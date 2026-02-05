#!/bin/bash
# List keywords for an Apple Search Ads ad group
# Usage: ./get-keywords.sh --campaign-id ID --adgroup-id ID [--format json|table] [--limit N]
#
# Examples:
#   ./get-keywords.sh --campaign-id 123 --adgroup-id 456
#   ./get-keywords.sh --campaign-id 123 --adgroup-id 456 --format json
#   ./get-keywords.sh --campaign-id 123 --adgroup-id 456 --status ACTIVE

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Defaults
FORMAT="table"
LIMIT=1000
OFFSET=0
STATUS=""
CAMPAIGN_ID=""
ADGROUP_ID=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --campaign-id) CAMPAIGN_ID="$2"; shift 2 ;;
        --adgroup-id) ADGROUP_ID="$2"; shift 2 ;;
        --format) FORMAT="$2"; shift 2 ;;
        --limit) LIMIT="$2"; shift 2 ;;
        --offset) OFFSET="$2"; shift 2 ;;
        --status) STATUS="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 --campaign-id ID --adgroup-id ID [--format json|table] [--status ACTIVE|PAUSED]"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Validate required arguments
if [ -z "$CAMPAIGN_ID" ] || [ -z "$ADGROUP_ID" ]; then
    echo "Error: --campaign-id and --adgroup-id are required" >&2
    echo "Usage: $0 --campaign-id ID --adgroup-id ID [--format json|table]" >&2
    exit 1
fi

# Fetch keywords
response=$(api_get "/campaigns/$CAMPAIGN_ID/adgroups/$ADGROUP_ID/targetingkeywords" "limit=$LIMIT&offset=$OFFSET")

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
        echo "Keywords for Ad Group $ADGROUP_ID"
        echo "================================="
        echo ""
        echo "$response" | jq -r '
            .data[] |
            [
                .id,
                .text,
                .matchType,
                .status,
                (.bidAmount.amount // "default")
            ] | @tsv' | \
        column -t -s $'\t' | \
        (echo "ID	KEYWORD	MATCH	STATUS	BID" | column -t -s $'\t' && cat)
        echo ""
        echo "Total: $(echo "$response" | jq '.data | length') keywords"
    else
        echo "$response"
    fi
fi
