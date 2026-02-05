#!/bin/bash
# Pause or enable an Apple Search Ads keyword
# Usage: ./pause-keyword.sh --campaign-id ID --adgroup-id ID --keyword-id ID [--enable]
#
# Examples:
#   ./pause-keyword.sh --campaign-id 123 --adgroup-id 456 --keyword-id 789          # Pause
#   ./pause-keyword.sh --campaign-id 123 --adgroup-id 456 --keyword-id 789 --enable # Enable

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Defaults
STATUS="PAUSED"
CAMPAIGN_ID=""
ADGROUP_ID=""
KEYWORD_ID=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --campaign-id) CAMPAIGN_ID="$2"; shift 2 ;;
        --adgroup-id) ADGROUP_ID="$2"; shift 2 ;;
        --keyword-id) KEYWORD_ID="$2"; shift 2 ;;
        --enable) STATUS="ACTIVE"; shift ;;
        --pause) STATUS="PAUSED"; shift ;;
        --help)
            echo "Usage: $0 --campaign-id ID --adgroup-id ID --keyword-id ID [--enable|--pause]"
            echo "  Default action is pause. Use --enable to activate a keyword."
            exit 0
            ;;
        *) shift ;;
    esac
done

# Validate required arguments
if [ -z "$CAMPAIGN_ID" ] || [ -z "$ADGROUP_ID" ] || [ -z "$KEYWORD_ID" ]; then
    echo "Error: --campaign-id, --adgroup-id, and --keyword-id are required" >&2
    echo "Usage: $0 --campaign-id ID --adgroup-id ID --keyword-id ID [--enable]" >&2
    exit 1
fi

# Build request body (bulk endpoint requires array format with id)
body="[{\"id\": $KEYWORD_ID, \"status\": \"$STATUS\"}]"

# Update keyword status via bulk endpoint (single endpoint returns RESOURCE_NOT_FOUND)
action=$([ "$STATUS" = "PAUSED" ] && echo "Pausing" || echo "Enabling")
echo "$action keyword $KEYWORD_ID..." >&2
response=$(api_put "/campaigns/$CAMPAIGN_ID/adgroups/$ADGROUP_ID/targetingkeywords/bulk" "$body")

# Check for errors
if ! check_error "$response"; then
    exit 1
fi

# Output result (bulk endpoint returns array)
if command -v jq &> /dev/null; then
    echo "$response" | jq '.data[0] | {
        id: .id,
        text: .text,
        status: .status,
        bidAmount: .bidAmount
    }'
    echo ""
    echo "Keyword $STATUS successfully." >&2
else
    echo "$response"
fi
