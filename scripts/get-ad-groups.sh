#!/bin/bash
# List ad groups for an Apple Search Ads campaign
# Usage: ./get-ad-groups.sh --campaign-id ID [--format json|table] [--limit N]
#
# Examples:
#   ./get-ad-groups.sh --campaign-id 123456789
#   ./get-ad-groups.sh --campaign-id 123456789 --format json
#   ./get-ad-groups.sh --campaign-id 123456789 --status ENABLED

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Defaults
FORMAT="table"
LIMIT=1000
OFFSET=0
STATUS=""
CAMPAIGN_ID=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --campaign-id) CAMPAIGN_ID="$2"; shift 2 ;;
        --format) FORMAT="$2"; shift 2 ;;
        --limit) LIMIT="$2"; shift 2 ;;
        --offset) OFFSET="$2"; shift 2 ;;
        --status) STATUS="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 --campaign-id ID [--format json|table] [--limit N] [--status ENABLED|PAUSED]"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Validate required arguments
if [ -z "$CAMPAIGN_ID" ]; then
    echo "Error: --campaign-id is required" >&2
    echo "Usage: $0 --campaign-id ID [--format json|table]" >&2
    exit 1
fi

# Fetch ad groups
response=$(api_get "/campaigns/$CAMPAIGN_ID/adgroups" "limit=$LIMIT&offset=$OFFSET")

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
        echo "Ad Groups for Campaign $CAMPAIGN_ID"
        echo "===================================="
        echo ""
        echo "$response" | jq -r '
            .data[] |
            [
                .id,
                .name,
                .status,
                (.defaultBidAmount.amount // "N/A"),
                (.automatedKeywordsOptIn // false)
            ] | @tsv' | \
        column -t -s $'\t' | \
        (echo "ID	NAME	STATUS	DEFAULT_BID	AUTO_KW" | column -t -s $'\t' && cat)
        echo ""
        echo "Total: $(echo "$response" | jq '.data | length') ad groups"
    else
        echo "$response"
    fi
fi
