#!/bin/bash
# Apple Search Ads API Common Functions
# Usage: source api.sh; api_get "/campaigns"; api_post "/path" "$body"
#
# Provides:
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

# Get a fresh access token
get_token() {
    bash "$SCRIPT_DIR/get-token.sh"
}

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

# PATCH request
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

# PUT request (for bulk updates)
# Usage: api_put "/campaigns/123/adgroups/456/targetingkeywords/bulk" '[{"id":789,"bidAmount":{"amount":"2.50","currency":"USD"}}]'
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
