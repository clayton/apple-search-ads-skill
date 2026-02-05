#!/bin/bash
# Apple Search Ads OAuth Token Generator (Pure Bash/OpenSSL)
# Usage: ./get-token.sh
# Outputs: access_token to stdout
#
# Requires environment variables:
#   APPLE_ADS_CLIENT_ID
#   APPLE_ADS_TEAM_ID
#   APPLE_ADS_KEY_ID
#   APPLE_ADS_PRIVATE_KEY
#   APPLE_ADS_ORG_ID
#
# This script uses only bash, curl, and openssl - no Ruby or other dependencies.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment from common locations if needed
for envfile in "$HOME/.claude/.env" "$HOME/.env" ".env"; do
    if [ -f "$envfile" ]; then
        set -a
        source "$envfile"
        set +a
        break
    fi
done

# Validate required environment variables
missing_vars=()
for var in APPLE_ADS_CLIENT_ID APPLE_ADS_TEAM_ID APPLE_ADS_KEY_ID APPLE_ADS_PRIVATE_KEY APPLE_ADS_ORG_ID; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    echo "Error: Missing required environment variables:" >&2
    printf "  - %s\n" "${missing_vars[@]}" >&2
    echo "" >&2
    echo "Set these in your environment or in ~/.claude/.env" >&2
    exit 1
fi

# Base64url encode (URL-safe base64 without padding)
base64url_encode() {
    openssl base64 -e -A | tr '+/' '-_' | tr -d '='
}

# Base64url encode string
base64url_encode_string() {
    printf '%s' "$1" | base64url_encode
}

# Generate ES256 JWT client secret
generate_client_secret() {
    local now
    now=$(date +%s)
    local exp=$((now + 3600))

    # JWT Header
    local header='{"alg":"ES256","kid":"'"$APPLE_ADS_KEY_ID"'"}'

    # JWT Payload
    local payload='{"iss":"'"$APPLE_ADS_TEAM_ID"'","iat":'"$now"',"exp":'"$exp"',"aud":"https://appleid.apple.com","sub":"'"$APPLE_ADS_CLIENT_ID"'"}'

    # Base64url encode header and payload
    local header_b64
    header_b64=$(base64url_encode_string "$header")
    local payload_b64
    payload_b64=$(base64url_encode_string "$payload")

    # Create signing input
    local signing_input="${header_b64}.${payload_b64}"

    # Prepare private key (handle escaped newlines from env var)
    local key_file
    key_file=$(mktemp)
    trap "rm -f '$key_file'" EXIT

    # Convert \n to actual newlines and write to temp file
    printf '%s' "$APPLE_ADS_PRIVATE_KEY" | sed 's/\\n/\n/g' > "$key_file"

    # Sign with ES256 (ECDSA P-256 with SHA-256)
    # OpenSSL outputs DER-encoded signature, we need raw r||s format
    local sig_der
    sig_der=$(printf '%s' "$signing_input" | openssl dgst -sha256 -sign "$key_file" | xxd -p | tr -d '\n')

    # Parse DER signature and extract r and s values
    # DER format: 30 <len> 02 <r_len> <r> 02 <s_len> <s>
    local sig_raw
    sig_raw=$(parse_der_signature "$sig_der")

    # Base64url encode the raw signature
    local sig_b64
    sig_b64=$(printf '%s' "$sig_raw" | xxd -r -p | base64url_encode)

    # Clean up temp file
    rm -f "$key_file"
    trap - EXIT

    # Return complete JWT
    echo "${signing_input}.${sig_b64}"
}

# Parse DER signature and convert to raw r||s format (64 bytes for P-256)
parse_der_signature() {
    local der_hex="$1"

    # Skip sequence tag (30) and length
    local pos=4  # Skip "30 XX"

    # Get r value
    # Skip integer tag (02)
    pos=$((pos + 2))

    # Get r length (in hex chars, so multiply by 2 for actual position)
    local r_len_hex="${der_hex:$pos:2}"
    local r_len=$((16#$r_len_hex))
    pos=$((pos + 2))

    # Extract r value
    local r_hex="${der_hex:$pos:$((r_len * 2))}"
    pos=$((pos + r_len * 2))

    # Get s value
    # Skip integer tag (02)
    pos=$((pos + 2))

    # Get s length
    local s_len_hex="${der_hex:$pos:2}"
    local s_len=$((16#$s_len_hex))
    pos=$((pos + 2))

    # Extract s value
    local s_hex="${der_hex:$pos:$((s_len * 2))}"

    # Pad or trim r and s to exactly 32 bytes (64 hex chars) each
    # If r starts with 00 (padding for positive number), remove it
    while [ ${#r_hex} -gt 64 ] && [ "${r_hex:0:2}" = "00" ]; do
        r_hex="${r_hex:2}"
    done
    # Pad with leading zeros if needed
    while [ ${#r_hex} -lt 64 ]; do
        r_hex="00${r_hex}"
    done

    # Same for s
    while [ ${#s_hex} -gt 64 ] && [ "${s_hex:0:2}" = "00" ]; do
        s_hex="${s_hex:2}"
    done
    while [ ${#s_hex} -lt 64 ]; do
        s_hex="00${s_hex}"
    done

    # Concatenate r||s
    echo "${r_hex}${s_hex}"
}

# Exchange client secret for access token
get_access_token() {
    local client_secret
    client_secret=$(generate_client_secret)

    local response
    response=$(curl -s -X POST 'https://appleid.apple.com/auth/oauth2/token' \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        -d "grant_type=client_credentials" \
        -d "client_id=$APPLE_ADS_CLIENT_ID" \
        -d "client_secret=$client_secret" \
        -d "scope=searchadsorg")

    # Check for error
    if echo "$response" | grep -q '"error"'; then
        local error
        error=$(echo "$response" | grep -o '"error":"[^"]*"' | cut -d'"' -f4)
        local error_desc
        error_desc=$(echo "$response" | grep -o '"error_description":"[^"]*"' | cut -d'"' -f4)
        echo "Error: $error - $error_desc" >&2
        exit 1
    fi

    # Extract access token
    if command -v jq &> /dev/null; then
        echo "$response" | jq -r '.access_token'
    else
        # Fallback without jq
        echo "$response" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4
    fi
}

# Main
get_access_token
