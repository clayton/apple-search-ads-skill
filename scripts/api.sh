#!/bin/bash
# Apple Search Ads API Common Functions
# Usage: source api.sh; api_get "/campaigns"; api_post "/path" "$body"
#
# Provides:
#   get_token - Exchange credentials for an access token
#   api_get PATH [QUERY_STRING] - GET request
#   api_post PATH BODY - POST request
#   api_put PATH BODY - PUT request (for bulk updates)
#   api_patch PATH BODY - PATCH request
#   api_delete PATH - DELETE request

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_URL="https://api.searchads.apple.com/api/v5"

# Load environment from common locations if needed
for envfile in "$HOME/.claude/.env" "$HOME/.env" ".env"; do
    if [ -f "$envfile" ]; then
        set -a
        source "$envfile"
        set +a
        break
    fi
done

# ---------------------------------------------------------------------------
# Authentication — ES256 JWT → OAuth2 access token
# ---------------------------------------------------------------------------
#
# JWT structure for Apple Search Ads:
#   Header:  { alg: "ES256", kid: APPLE_ADS_KEY_ID }
#   Payload: { iss: APPLE_ADS_TEAM_ID, sub: APPLE_ADS_CLIENT_ID,
#              aud: "https://appleid.apple.com", iat: now, exp: now+3600 }
#   Signed with: APPLE_ADS_PRIVATE_KEY (EC P-256)
#
# The JWT is exchanged at https://appleid.apple.com/auth/oauth2/token
# with grant_type=client_credentials, scope=searchadsorg.
# ---------------------------------------------------------------------------

# Validate that all required env vars are set
_validate_env() {
    local missing=()
    for var in APPLE_ADS_CLIENT_ID APPLE_ADS_TEAM_ID APPLE_ADS_KEY_ID APPLE_ADS_PRIVATE_KEY APPLE_ADS_ORG_ID; do
        if [ -z "${!var}" ]; then
            missing+=("$var")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Error: Missing required environment variables:" >&2
        printf "  - %s\n" "${missing[@]}" >&2
        echo "" >&2
        echo "Set these in your environment or in ~/.claude/.env" >&2
        return 1
    fi
}

# Base64url encode (URL-safe base64 without padding)
_base64url_encode() {
    openssl base64 -e -A | tr '+/' '-_' | tr -d '='
}

# Parse DER-encoded ECDSA signature → raw r||s (64 bytes for P-256)
_parse_der_signature() {
    local der_hex="$1"
    local pos=4  # Skip sequence tag (30) + length byte

    # r integer
    pos=$((pos + 2))  # skip integer tag (02)
    local r_len=$((16#${der_hex:$pos:2}))
    pos=$((pos + 2))
    local r_hex="${der_hex:$pos:$((r_len * 2))}"
    pos=$((pos + r_len * 2))

    # s integer
    pos=$((pos + 2))  # skip integer tag (02)
    local s_len=$((16#${der_hex:$pos:2}))
    pos=$((pos + 2))
    local s_hex="${der_hex:$pos:$((s_len * 2))}"

    # Normalize to exactly 32 bytes (64 hex chars) each
    while [ ${#r_hex} -gt 64 ] && [ "${r_hex:0:2}" = "00" ]; do r_hex="${r_hex:2}"; done
    while [ ${#r_hex} -lt 64 ]; do r_hex="00${r_hex}"; done
    while [ ${#s_hex} -gt 64 ] && [ "${s_hex:0:2}" = "00" ]; do s_hex="${s_hex:2}"; done
    while [ ${#s_hex} -lt 64 ]; do s_hex="00${s_hex}"; done

    echo "${r_hex}${s_hex}"
}

# Generate an ES256 JWT client_secret for Apple OAuth
_generate_client_secret() {
    local now=$(date +%s)
    local exp=$((now + 3600))

    local header='{"alg":"ES256","kid":"'"$APPLE_ADS_KEY_ID"'"}'
    local payload='{"iss":"'"$APPLE_ADS_TEAM_ID"'","iat":'"$now"',"exp":'"$exp"',"aud":"https://appleid.apple.com","sub":"'"$APPLE_ADS_CLIENT_ID"'"}'

    local header_b64=$(printf '%s' "$header" | _base64url_encode)
    local payload_b64=$(printf '%s' "$payload" | _base64url_encode)
    local signing_input="${header_b64}.${payload_b64}"

    # Write private key to temp file (handle escaped newlines from env vars)
    local key_file=$(mktemp)
    trap "rm -f '$key_file'" RETURN
    printf '%s' "$APPLE_ADS_PRIVATE_KEY" | sed 's/\\n/\n/g' > "$key_file"

    # Sign and convert DER → raw r||s
    local sig_der=$(printf '%s' "$signing_input" | openssl dgst -sha256 -sign "$key_file" | xxd -p | tr -d '\n')
    local sig_raw=$(_parse_der_signature "$sig_der")
    local sig_b64=$(printf '%s' "$sig_raw" | xxd -r -p | _base64url_encode)

    rm -f "$key_file"
    echo "${signing_input}.${sig_b64}"
}

# Get a fresh access token (generates JWT, exchanges for OAuth token)
get_token() {
    _validate_env || return 1

    local client_secret=$(_generate_client_secret)

    local response=$(curl -s -X POST 'https://appleid.apple.com/auth/oauth2/token' \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        -d "grant_type=client_credentials" \
        -d "client_id=$APPLE_ADS_CLIENT_ID" \
        -d "client_secret=$client_secret" \
        -d "scope=searchadsorg")

    if echo "$response" | grep -q '"error"'; then
        local error=$(echo "$response" | grep -o '"error":"[^"]*"' | cut -d'"' -f4)
        local error_desc=$(echo "$response" | grep -o '"error_description":"[^"]*"' | cut -d'"' -f4)
        echo "Error: $error - $error_desc" >&2
        return 1
    fi

    if command -v jq &> /dev/null; then
        echo "$response" | jq -r '.access_token'
    else
        echo "$response" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4
    fi
}

# ---------------------------------------------------------------------------
# API request helpers
# ---------------------------------------------------------------------------

# GET request
# Usage: api_get "/campaigns" "limit=100&offset=0"
api_get() {
    local path="$1"
    local query="$2"
    local token=$(get_token)
    local url="$BASE_URL$path"

    if [ -n "$query" ]; then
        url="$url?$query"
    fi

    curl -s -X GET \
        -H "Authorization: Bearer $token" \
        -H "X-AP-Context: orgId=$APPLE_ADS_ORG_ID" \
        -H "Content-Type: application/json" \
        "$url"
}

# POST request
# Usage: api_post "/reports/campaigns" '{"startTime":"2024-01-01"}'
api_post() {
    local path="$1"
    local body="$2"
    local token=$(get_token)

    curl -s -X POST \
        -H "Authorization: Bearer $token" \
        -H "X-AP-Context: orgId=$APPLE_ADS_ORG_ID" \
        -H "Content-Type: application/json" \
        -d "$body" \
        "$BASE_URL$path"
}

# PATCH request (NOTE: PATCH returns 403 for campaign updates - use api_put with nested body instead)
# Usage: api_patch "/campaigns/123" '{"status":"PAUSED"}'
api_patch() {
    local path="$1"
    local body="$2"
    local token=$(get_token)

    curl -s -X PATCH \
        -H "Authorization: Bearer $token" \
        -H "X-AP-Context: orgId=$APPLE_ADS_ORG_ID" \
        -H "Content-Type: application/json" \
        -d "$body" \
        "$BASE_URL$path"
}

# PUT request (for campaign/adgroup updates and bulk keyword updates)
# Campaign updates require nested body: '{"campaign":{"status":"PAUSED"}}'
# Keyword bulk updates: '[{"id":789,"bidAmount":{"amount":"2.50","currency":"USD"}}]'
api_put() {
    local path="$1"
    local body="$2"
    local token=$(get_token)

    curl -s -X PUT \
        -H "Authorization: Bearer $token" \
        -H "X-AP-Context: orgId=$APPLE_ADS_ORG_ID" \
        -H "Content-Type: application/json" \
        -d "$body" \
        "$BASE_URL$path"
}

# DELETE request
# Usage: api_delete "/campaigns/123/adgroups/456/targetingkeywords/789"
api_delete() {
    local path="$1"
    local token=$(get_token)

    curl -s -X DELETE \
        -H "Authorization: Bearer $token" \
        -H "X-AP-Context: orgId=$APPLE_ADS_ORG_ID" \
        -H "Content-Type: application/json" \
        "$BASE_URL$path"
}

# Format JSON output (if jq available)
format_json() {
    if command -v jq &> /dev/null; then
        jq '.'
    else
        cat
    fi
}

# Extract error message from response
check_error() {
    local response="$1"
    if command -v jq &> /dev/null; then
        local error=$(echo "$response" | jq -r '.error.message // empty')
        if [ -n "$error" ]; then
            echo "API Error: $error" >&2
            return 1
        fi
    fi
    return 0
}
