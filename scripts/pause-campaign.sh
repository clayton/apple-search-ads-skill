#!/bin/bash
# Pause or enable an Apple Search Ads campaign
# Usage: ./pause-campaign.sh --campaign-id ID [--enable]
#
# Examples:
#   ./pause-campaign.sh --campaign-id 123456789          # Pause
#   ./pause-campaign.sh --campaign-id 123456789 --enable # Enable

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Defaults
STATUS="PAUSED"
CAMPAIGN_ID=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --campaign-id) CAMPAIGN_ID="$2"; shift 2 ;;
        --enable) STATUS="ENABLED"; shift ;;
        --pause) STATUS="PAUSED"; shift ;;
        --help)
            echo "Usage: $0 --campaign-id ID [--enable|--pause]"
            echo "  Default action is pause. Use --enable to activate a campaign."
            exit 0
            ;;
        *) shift ;;
    esac
done

# Validate required arguments
if [ -z "$CAMPAIGN_ID" ]; then
    echo "Error: --campaign-id is required" >&2
    echo "Usage: $0 --campaign-id ID [--enable]" >&2
    exit 1
fi

# Build request body
body="{\"campaign\":{\"status\":\"$STATUS\"}}"

# Update campaign status
action=$([ "$STATUS" = "PAUSED" ] && echo "Pausing" || echo "Enabling")
echo "$action campaign $CAMPAIGN_ID..." >&2
response=$(api_put "/campaigns/$CAMPAIGN_ID" "$body")

# Check for errors
if ! check_error "$response"; then
    exit 1
fi

# Output result
if command -v jq &> /dev/null; then
    echo "$response" | jq '.data | {
        id: .id,
        name: .name,
        status: .status
    }'
    echo ""
    echo "Campaign $STATUS successfully." >&2
else
    echo "$response"
fi
