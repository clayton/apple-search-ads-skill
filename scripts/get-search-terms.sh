#!/bin/bash
# Get search terms report from an Apple Search Ads campaign
# Shows actual search queries that triggered your ads (useful for Discovery campaigns)
# Usage: ./get-search-terms.sh --campaign-id ID [--adgroup-id ID] [--days N] [--format json|table]
#
# Examples:
#   ./get-search-terms.sh --campaign-id 123 --days 30
#   ./get-search-terms.sh --campaign-id 123 --adgroup-id 456 --days 7
#   ./get-search-terms.sh --campaign-id 123 --format json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Defaults
DAYS=30
FORMAT="table"
CAMPAIGN_ID=""
ADGROUP_ID=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --campaign-id) CAMPAIGN_ID="$2"; shift 2 ;;
        --adgroup-id) ADGROUP_ID="$2"; shift 2 ;;
        --days) DAYS="$2"; shift 2 ;;
        --format) FORMAT="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 --campaign-id ID [--adgroup-id ID] [--days N] [--format json|table]"
            echo ""
            echo "Options:"
            echo "  --campaign-id   Campaign ID (required)"
            echo "  --adgroup-id    Ad group ID (optional, for specific ad group)"
            echo "  --days          Number of days to report (default: 30)"
            echo "  --format        Output format: json or table (default: table)"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Validate required arguments
if [ -z "$CAMPAIGN_ID" ]; then
    echo "Error: --campaign-id is required" >&2
    echo "Usage: $0 --campaign-id ID [--adgroup-id ID] [--days N]" >&2
    exit 1
fi

# Calculate date range
END_DATE=$(date +%Y-%m-%d)
START_DATE=$(date -v-${DAYS}d +%Y-%m-%d 2>/dev/null || date -d "$DAYS days ago" +%Y-%m-%d)

# Build request body
body=$(cat <<EOF
{
    "startTime": "$START_DATE",
    "endTime": "$END_DATE",
    "selector": {
        "orderBy": [
            {"field": "localSpend", "sortOrder": "DESCENDING"}
        ],
        "pagination": {
            "offset": 0,
            "limit": 1000
        }
    },
    "returnRowTotals": true,
    "returnRecordsWithNoMetrics": false
}
EOF
)

# Determine endpoint based on whether adgroup-id is provided
if [ -n "$ADGROUP_ID" ]; then
    endpoint="/reports/campaigns/$CAMPAIGN_ID/adgroups/$ADGROUP_ID/searchterms"
    location="Ad Group $ADGROUP_ID"
else
    endpoint="/reports/campaigns/$CAMPAIGN_ID/searchterms"
    location="Campaign $CAMPAIGN_ID"
fi

# Fetch search terms report
response=$(api_post "$endpoint" "$body")

# Check for errors
if ! check_error "$response"; then
    exit 1
fi

# Output based on format
if [ "$FORMAT" = "json" ]; then
    echo "$response" | format_json
else
    if command -v jq &> /dev/null; then
        echo ""
        echo "Search Terms Report ($START_DATE to $END_DATE)"
        echo "$location"
        echo "=========================================================="
        echo ""

        # Extract and format rows
        echo "$response" | jq -r '
            .data.reportingDataResponse.row[]? |
            [
                (.metadata.searchTermText // "N/A"),
                (.metadata.matchType // "N/A"),
                (.metadata.keyword // "N/A"),
                (.total.localSpend.amount // "0"),
                (.total.impressions // 0),
                (.total.taps // 0),
                (.total.totalInstalls // 0)
            ] | @tsv' | \
        column -t -s $'\t' | \
        (echo "SEARCH_TERM	MATCH	KEYWORD	SPEND	IMPR	TAPS	INSTALLS" | column -t -s $'\t' && cat)

        echo ""
        echo "Total search terms: $(echo "$response" | jq '.data.reportingDataResponse.row | length')"
        echo ""
        echo "Tip: Add high-performing search terms to Proxy campaign for ROAS tracking."
    else
        echo "$response"
    fi
fi
