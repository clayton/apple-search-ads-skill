#!/bin/bash
# Update Apple Search Ads keyword bid
# Usage: ./update-keyword-bid.sh --campaign-id ID --adgroup-id ID --keyword-id ID --bid AMOUNT [--currency USD]
#
# Examples:
#   ./update-keyword-bid.sh --campaign-id 123 --adgroup-id 456 --keyword-id 789 --bid 1.50
#   ./update-keyword-bid.sh --campaign-id 123 --adgroup-id 456 --keyword-id 789 --bid 2.00 --currency EUR

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Defaults
CURRENCY="USD"
CAMPAIGN_ID=""
ADGROUP_ID=""
KEYWORD_ID=""
BID=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --campaign-id) CAMPAIGN_ID="$2"; shift 2 ;;
        --adgroup-id) ADGROUP_ID="$2"; shift 2 ;;
        --keyword-id) KEYWORD_ID="$2"; shift 2 ;;
        --bid) BID="$2"; shift 2 ;;
        --currency) CURRENCY="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 --campaign-id ID --adgroup-id ID --keyword-id ID --bid AMOUNT [--currency USD]"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Validate required arguments
if [ -z "$CAMPAIGN_ID" ] || [ -z "$ADGROUP_ID" ] || [ -z "$KEYWORD_ID" ] || [ -z "$BID" ]; then
    echo "Error: --campaign-id, --adgroup-id, --keyword-id, and --bid are required" >&2
    echo "Usage: $0 --campaign-id ID --adgroup-id ID --keyword-id ID --bid AMOUNT" >&2
    exit 1
fi

# Build request body (bulk endpoint requires array format with id)
body="[{\"id\": $KEYWORD_ID, \"bidAmount\": {\"amount\": \"$BID\", \"currency\": \"$CURRENCY\"}}]"

# Update keyword bid via bulk endpoint (single endpoint returns RESOURCE_NOT_FOUND)
echo "Updating keyword $KEYWORD_ID bid to $BID $CURRENCY..." >&2
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
        matchType: .matchType,
        bidAmount: .bidAmount,
        status: .status
    }'
    echo ""
    echo "Keyword bid updated successfully." >&2
else
    echo "$response"
fi
