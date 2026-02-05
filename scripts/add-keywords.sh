#!/bin/bash
# Add keywords to an Apple Search Ads ad group
# Usage: ./add-keywords.sh --campaign-id ID --adgroup-id ID --keywords "kw1,kw2" [--match-type EXACT|BROAD] [--bid AMOUNT]
#
# Examples:
#   ./add-keywords.sh --campaign-id 123 --adgroup-id 456 --keywords "fitness app,workout tracker" --bid 1.00
#   ./add-keywords.sh --campaign-id 123 --adgroup-id 456 --keywords "health" --match-type BROAD --bid 0.50

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Defaults
MATCH_TYPE="EXACT"
CURRENCY="USD"
BID=""
CAMPAIGN_ID=""
ADGROUP_ID=""
KEYWORDS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --campaign-id) CAMPAIGN_ID="$2"; shift 2 ;;
        --adgroup-id) ADGROUP_ID="$2"; shift 2 ;;
        --keywords) KEYWORDS="$2"; shift 2 ;;
        --match-type) MATCH_TYPE="$2"; shift 2 ;;
        --bid) BID="$2"; shift 2 ;;
        --currency) CURRENCY="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 --campaign-id ID --adgroup-id ID --keywords \"kw1,kw2\" [--match-type EXACT|BROAD] [--bid AMOUNT]"
            echo ""
            echo "Options:"
            echo "  --keywords     Comma-separated list of keywords to add"
            echo "  --match-type   EXACT (default) or BROAD"
            echo "  --bid          Bid amount (optional, uses ad group default if not set)"
            echo "  --currency     Currency code (default: USD)"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Validate required arguments
if [ -z "$CAMPAIGN_ID" ] || [ -z "$ADGROUP_ID" ] || [ -z "$KEYWORDS" ]; then
    echo "Error: --campaign-id, --adgroup-id, and --keywords are required" >&2
    echo "Usage: $0 --campaign-id ID --adgroup-id ID --keywords \"kw1,kw2\" [--bid AMOUNT]" >&2
    exit 1
fi

# Build JSON array from comma-separated keywords
IFS=',' read -ra KW_ARRAY <<< "$KEYWORDS"
JSON_ARRAY="["
for i in "${!KW_ARRAY[@]}"; do
    # Trim whitespace
    kw=$(echo "${KW_ARRAY[$i]}" | xargs)

    [ $i -gt 0 ] && JSON_ARRAY+=","

    if [ -n "$BID" ]; then
        JSON_ARRAY+="{\"text\":\"$kw\",\"matchType\":\"$MATCH_TYPE\",\"bidAmount\":{\"amount\":\"$BID\",\"currency\":\"$CURRENCY\"}}"
    else
        JSON_ARRAY+="{\"text\":\"$kw\",\"matchType\":\"$MATCH_TYPE\"}"
    fi
done
JSON_ARRAY+="]"

# Add keywords
echo "Adding ${#KW_ARRAY[@]} keyword(s) to ad group $ADGROUP_ID..." >&2
response=$(api_post "/campaigns/$CAMPAIGN_ID/adgroups/$ADGROUP_ID/targetingkeywords/bulk" "$JSON_ARRAY")

# Check for errors
if ! check_error "$response"; then
    exit 1
fi

# Output result
if command -v jq &> /dev/null; then
    echo "$response" | jq '.data[] | {
        id: .id,
        text: .text,
        matchType: .matchType,
        status: .status,
        bidAmount: .bidAmount
    }'
    echo ""
    echo "Keywords added successfully." >&2
else
    echo "$response"
fi
