#!/bin/bash
# List all Apple Search Ads campaigns
# Usage: ./list-campaigns.sh [--format json|table] [--limit N] [--status ENABLED|PAUSED]
#
# Examples:
#   ./list-campaigns.sh                      # List all campaigns as table
#   ./list-campaigns.sh --format json        # Output raw JSON
#   ./list-campaigns.sh --status ENABLED     # Only enabled campaigns
#   ./list-campaigns.sh --limit 10           # First 10 campaigns

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Defaults
FORMAT="table"
LIMIT=1000
OFFSET=0
STATUS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --format) FORMAT="$2"; shift 2 ;;
        --limit) LIMIT="$2"; shift 2 ;;
        --offset) OFFSET="$2"; shift 2 ;;
        --status) STATUS="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 [--format json|table] [--limit N] [--status ENABLED|PAUSED]"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Fetch campaigns
response=$(api_get "/campaigns" "limit=$LIMIT&offset=$OFFSET")

# Check for errors
if ! check_error "$response"; then
    exit 1
fi

# Filter by status if specified
if [ -n "$STATUS" ]; then
    response=$(echo "$response" | jq --arg status "$STATUS" '.data |= map(select(.status == $status))')
fi

# Output based on format
if [ "$FORMAT" = "json" ]; then
    echo "$response" | format_json
else
    if command -v jq &> /dev/null; then
        echo ""
        echo "Apple Search Ads Campaigns"
        echo "=========================="
        echo ""
        echo "$response" | jq -r '
            .data[] |
            [
                .id,
                .name,
                .status,
                (.countriesOrRegions // ["N/A"])[0],
                (.dailyBudgetAmount.amount // "N/A"),
                (.displayStatus // "N/A")
            ] | @tsv' | \
        column -t -s $'\t' | \
        (echo "ID	NAME	STATUS	COUNTRY	DAILY_BUDGET	DISPLAY_STATUS" | column -t -s $'\t' && cat)
        echo ""
        echo "Total: $(echo "$response" | jq '.data | length') campaigns"
    else
        echo "$response"
    fi
fi
