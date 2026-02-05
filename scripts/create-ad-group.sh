#!/bin/bash
# Create a new ad group in an Apple Search Ads campaign
# Usage: ./create-ad-group.sh --campaign-id ID --name NAME --default-bid AMOUNT [--status ENABLED|PAUSED]
#
# Examples:
#   ./create-ad-group.sh --campaign-id 123 --name "generic_keywords" --default-bid 1.50
#   ./create-ad-group.sh --campaign-id 123 --name "competitor_terms" --default-bid 2.00 --status PAUSED

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Defaults
STATUS="ENABLED"
CURRENCY="USD"
AUTO_KEYWORDS="false"
CAMPAIGN_ID=""
AD_GROUP_NAME=""
DEFAULT_BID=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --campaign-id) CAMPAIGN_ID="$2"; shift 2 ;;
        --name) AD_GROUP_NAME="$2"; shift 2 ;;
        --default-bid) DEFAULT_BID="$2"; shift 2 ;;
        --status) STATUS="$2"; shift 2 ;;
        --auto-keywords) AUTO_KEYWORDS="true"; shift ;;
        --currency) CURRENCY="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 --campaign-id ID --name NAME --default-bid AMOUNT [--status ENABLED|PAUSED]"
            echo ""
            echo "Options:"
            echo "  --campaign-id    Campaign ID to add ad group to (required)"
            echo "  --name           Ad group name (required)"
            echo "  --default-bid    Default bid amount for keywords (required)"
            echo "  --status         ENABLED (default) or PAUSED"
            echo "  --auto-keywords  Enable automated keywords (Search Match)"
            echo "  --currency       Currency code (default: USD)"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Validate required arguments
if [ -z "$CAMPAIGN_ID" ] || [ -z "$AD_GROUP_NAME" ] || [ -z "$DEFAULT_BID" ]; then
    echo "Error: --campaign-id, --name, and --default-bid are required" >&2
    echo "Usage: $0 --campaign-id ID --name NAME --default-bid AMOUNT" >&2
    exit 1
fi

# Get current timestamp for start time
START_TIME=$(date -u +%Y-%m-%dT07:00:00.000)

# Build request body
body=$(cat <<EOF
{
    "name": "$AD_GROUP_NAME",
    "automatedKeywordsOptIn": $AUTO_KEYWORDS,
    "defaultBidAmount": {"amount": "$DEFAULT_BID", "currency": "$CURRENCY"},
    "pricingModel": "CPC",
    "startTime": "$START_TIME",
    "targetingDimensions": {
        "deviceClass": {
            "included": ["IPHONE", "IPAD"]
        }
    },
    "status": "$STATUS"
}
EOF
)

# Create ad group
echo "Creating ad group '$AD_GROUP_NAME' in campaign $CAMPAIGN_ID..." >&2
response=$(api_post "/campaigns/$CAMPAIGN_ID/adgroups" "$body")

# Check for errors
if ! check_error "$response"; then
    exit 1
fi

# Output result
if command -v jq &> /dev/null; then
    echo "$response" | jq '.data | {
        id: .id,
        name: .name,
        status: .status,
        defaultBid: .defaultBidAmount,
        automatedKeywords: .automatedKeywordsOptIn
    }'
    echo ""
    echo "Ad group created successfully." >&2
else
    echo "$response"
fi
