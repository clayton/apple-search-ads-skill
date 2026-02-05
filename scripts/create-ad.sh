#!/bin/bash
# Create an ad in an Apple Search Ads ad group
# Usage: ./create-ad.sh --campaign-id ID --adgroup-id ID --creative-id ID --name NAME [--status ENABLED|PAUSED]
#
# Examples:
#   ./create-ad.sh --campaign-id 123 --adgroup-id 456 --creative-id 789 --name "Summer Sale Ad"
#   ./create-ad.sh --campaign-id 123 --adgroup-id 456 --creative-id 789 --name "Test Ad" --status PAUSED

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Defaults
STATUS="ENABLED"
CAMPAIGN_ID=""
ADGROUP_ID=""
CREATIVE_ID=""
AD_NAME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --campaign-id) CAMPAIGN_ID="$2"; shift 2 ;;
        --adgroup-id) ADGROUP_ID="$2"; shift 2 ;;
        --creative-id) CREATIVE_ID="$2"; shift 2 ;;
        --name) AD_NAME="$2"; shift 2 ;;
        --status) STATUS="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 --campaign-id ID --adgroup-id ID --creative-id ID --name NAME [--status ENABLED|PAUSED]"
            echo ""
            echo "Options:"
            echo "  --campaign-id   Campaign ID (required)"
            echo "  --adgroup-id    Ad group ID (required)"
            echo "  --creative-id   Creative ID from ./create-creative.sh (required)"
            echo "  --name          Ad name (required)"
            echo "  --status        ENABLED (default) or PAUSED"
            echo ""
            echo "First create a creative with ./create-creative.sh, then use its ID here."
            exit 0
            ;;
        *) shift ;;
    esac
done

# Validate required arguments
if [ -z "$CAMPAIGN_ID" ] || [ -z "$ADGROUP_ID" ] || [ -z "$CREATIVE_ID" ] || [ -z "$AD_NAME" ]; then
    echo "Error: --campaign-id, --adgroup-id, --creative-id, and --name are required" >&2
    echo "Usage: $0 --campaign-id ID --adgroup-id ID --creative-id ID --name NAME" >&2
    exit 1
fi

# Build request body
body=$(cat <<EOF
{
    "creativeId": $CREATIVE_ID,
    "name": "$AD_NAME",
    "status": "$STATUS"
}
EOF
)

# Create ad
echo "Creating ad '$AD_NAME' in ad group $ADGROUP_ID..." >&2
response=$(api_post "/campaigns/$CAMPAIGN_ID/adgroups/$ADGROUP_ID/ads" "$body")

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
        creativeId: .creativeId
    }'
    echo ""
    echo "Ad created successfully." >&2
else
    echo "$response"
fi
