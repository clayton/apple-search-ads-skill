#!/bin/bash
# Update an Apple Search Ads campaign
# Usage: ./update-campaign.sh --campaign-id ID [--name NAME] [--budget AMOUNT] [--daily-budget AMOUNT] [--status ENABLED|PAUSED]
#
# Examples:
#   ./update-campaign.sh --campaign-id 123 --daily-budget 200
#   ./update-campaign.sh --campaign-id 123 --status PAUSED
#   ./update-campaign.sh --campaign-id 123 --name "USA_generic_v2" --budget 10000

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Defaults
CURRENCY="USD"
CAMPAIGN_ID=""
CAMPAIGN_NAME=""
BUDGET=""
DAILY_BUDGET=""
STATUS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --campaign-id) CAMPAIGN_ID="$2"; shift 2 ;;
        --name) CAMPAIGN_NAME="$2"; shift 2 ;;
        --budget) BUDGET="$2"; shift 2 ;;
        --daily-budget) DAILY_BUDGET="$2"; shift 2 ;;
        --status) STATUS="$2"; shift 2 ;;
        --currency) CURRENCY="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 --campaign-id ID [--name NAME] [--budget AMOUNT] [--daily-budget AMOUNT] [--status ENABLED|PAUSED]"
            echo ""
            echo "Options:"
            echo "  --campaign-id   Campaign ID to update (required)"
            echo "  --name          New campaign name"
            echo "  --budget        New total budget"
            echo "  --daily-budget  New daily budget cap"
            echo "  --status        ENABLED or PAUSED"
            echo "  --currency      Currency code (default: USD)"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Validate required arguments
if [ -z "$CAMPAIGN_ID" ]; then
    echo "Error: --campaign-id is required" >&2
    echo "Usage: $0 --campaign-id ID [--name NAME] [--budget AMOUNT] [--daily-budget AMOUNT] [--status ENABLED|PAUSED]" >&2
    exit 1
fi

# Check that at least one update field is provided
if [ -z "$CAMPAIGN_NAME" ] && [ -z "$BUDGET" ] && [ -z "$DAILY_BUDGET" ] && [ -z "$STATUS" ]; then
    echo "Error: At least one update field is required (--name, --budget, --daily-budget, or --status)" >&2
    exit 1
fi

# Build campaign update object
campaign_data="{"
first=true

if [ -n "$CAMPAIGN_NAME" ]; then
    [ "$first" = false ] && campaign_data+=","
    campaign_data+="\"name\":\"$CAMPAIGN_NAME\""
    first=false
fi

if [ -n "$BUDGET" ]; then
    [ "$first" = false ] && campaign_data+=","
    campaign_data+="\"budgetAmount\":{\"amount\":\"$BUDGET\",\"currency\":\"$CURRENCY\"}"
    first=false
fi

if [ -n "$DAILY_BUDGET" ]; then
    [ "$first" = false ] && campaign_data+=","
    campaign_data+="\"dailyBudgetAmount\":{\"amount\":\"$DAILY_BUDGET\",\"currency\":\"$CURRENCY\"}"
    first=false
fi

if [ -n "$STATUS" ]; then
    [ "$first" = false ] && campaign_data+=","
    campaign_data+="\"status\":\"$STATUS\""
    first=false
fi

campaign_data+="}"

# Wrap in campaign object for PUT
body="{\"campaign\":$campaign_data}"

# Update campaign
echo "Updating campaign $CAMPAIGN_ID..." >&2
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
        status: .status,
        dailyBudget: .dailyBudgetAmount,
        totalBudget: .budgetAmount
    }'
    echo ""
    echo "Campaign updated successfully." >&2
else
    echo "$response"
fi
