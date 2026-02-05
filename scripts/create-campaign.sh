#!/bin/bash
# Create a new Apple Search Ads campaign
# Usage: ./create-campaign.sh --name NAME --adam-id ID --countries US,CA --budget 1000 --daily-budget 100 [--status ENABLED|PAUSED]
#
# Examples:
#   ./create-campaign.sh --name "USA_generic" --adam-id 123456789 --countries US --budget 5000 --daily-budget 100
#   ./create-campaign.sh --name "EUR_discovery" --adam-id 123456789 --countries DE,FR,IT --budget 3000 --daily-budget 50 --status PAUSED

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Defaults
STATUS="ENABLED"
CURRENCY="USD"
CAMPAIGN_NAME=""
ADAM_ID=""
COUNTRIES=""
BUDGET=""
DAILY_BUDGET=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name) CAMPAIGN_NAME="$2"; shift 2 ;;
        --adam-id) ADAM_ID="$2"; shift 2 ;;
        --countries) COUNTRIES="$2"; shift 2 ;;
        --budget) BUDGET="$2"; shift 2 ;;
        --daily-budget) DAILY_BUDGET="$2"; shift 2 ;;
        --status) STATUS="$2"; shift 2 ;;
        --currency) CURRENCY="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 --name NAME --adam-id APP_ID --countries US,CA --budget AMOUNT --daily-budget AMOUNT [--status ENABLED|PAUSED]"
            echo ""
            echo "Options:"
            echo "  --name          Campaign name (e.g., USA_generic)"
            echo "  --adam-id       App Store app ID"
            echo "  --countries     Comma-separated country codes (e.g., US,CA,GB)"
            echo "  --budget        Total campaign budget"
            echo "  --daily-budget  Daily budget cap"
            echo "  --status        ENABLED (default) or PAUSED"
            echo "  --currency      Currency code (default: USD)"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Validate required arguments
if [ -z "$CAMPAIGN_NAME" ] || [ -z "$ADAM_ID" ] || [ -z "$COUNTRIES" ] || [ -z "$BUDGET" ] || [ -z "$DAILY_BUDGET" ]; then
    echo "Error: --name, --adam-id, --countries, --budget, and --daily-budget are required" >&2
    echo "Usage: $0 --name NAME --adam-id APP_ID --countries US,CA --budget AMOUNT --daily-budget AMOUNT" >&2
    exit 1
fi

# Build countries JSON array
IFS=',' read -ra COUNTRY_ARRAY <<< "$COUNTRIES"
COUNTRIES_JSON="["
for i in "${!COUNTRY_ARRAY[@]}"; do
    [ $i -gt 0 ] && COUNTRIES_JSON+=","
    COUNTRIES_JSON+="\"${COUNTRY_ARRAY[$i]}\""
done
COUNTRIES_JSON+="]"

# Build request body
body=$(cat <<EOF
{
    "orgId": $APPLE_ADS_ORG_ID,
    "name": "$CAMPAIGN_NAME",
    "budgetAmount": {"amount": "$BUDGET", "currency": "$CURRENCY"},
    "dailyBudgetAmount": {"amount": "$DAILY_BUDGET", "currency": "$CURRENCY"},
    "adamId": $ADAM_ID,
    "countriesOrRegions": $COUNTRIES_JSON,
    "supplySources": ["APPSTORE_SEARCH_RESULTS"],
    "adChannelType": "SEARCH",
    "billingEvent": "TAPS",
    "status": "$STATUS"
}
EOF
)

# Create campaign
echo "Creating campaign '$CAMPAIGN_NAME'..." >&2
response=$(api_post "/campaigns" "$body")

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
        countries: .countriesOrRegions,
        dailyBudget: .dailyBudgetAmount,
        totalBudget: .budgetAmount
    }'
    echo ""
    echo "Campaign created successfully." >&2
else
    echo "$response"
fi
