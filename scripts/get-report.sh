#!/bin/bash
# Get Apple Search Ads keyword performance report
# Usage: ./get-report.sh --campaign-id ID --adgroup-id ID [--days N] [--format json|table]
#
# Examples:
#   ./get-report.sh --campaign-id 123 --adgroup-id 456
#   ./get-report.sh --campaign-id 123 --adgroup-id 456 --days 7
#   ./get-report.sh --campaign-id 123 --adgroup-id 456 --format json

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
            echo "Usage: $0 --campaign-id ID --adgroup-id ID [--days N] [--format json|table]"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Validate required arguments
if [ -z "$CAMPAIGN_ID" ] || [ -z "$ADGROUP_ID" ]; then
    echo "Error: --campaign-id and --adgroup-id are required" >&2
    echo "Usage: $0 --campaign-id ID --adgroup-id ID [--days N]" >&2
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

# Fetch report
response=$(api_post "/reports/campaigns/$CAMPAIGN_ID/adgroups/$ADGROUP_ID/keywords" "$body")

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
        echo "Keyword Performance Report ($START_DATE to $END_DATE)"
        echo "Campaign: $CAMPAIGN_ID | Ad Group: $ADGROUP_ID"
        echo "=========================================================="
        echo ""

        # Extract and format rows
        echo "$response" | jq -r '
            .data.reportingDataResponse.row[]? |
            [
                (.metadata.keyword // "N/A"),
                (.metadata.keywordId // "N/A"),
                (.metadata.matchType // "N/A"),
                (.total.localSpend.amount // "0"),
                (.total.impressions // 0),
                (.total.taps // 0),
                (.total.totalInstalls // 0),
                (if (.total.taps // 0) > 0 then ((.total.totalInstalls // 0) / (.total.taps // 1) * 100 | floor | tostring) + "%" else "0%" end)
            ] | @tsv' | \
        column -t -s $'\t' | \
        (echo "KEYWORD	KW_ID	MATCH	SPEND	IMPR	TAPS	INSTALLS	CR" | column -t -s $'\t' && cat)

        echo ""
        echo "Total keywords: $(echo "$response" | jq '.data.reportingDataResponse.row | length')"
    else
        echo "$response"
    fi
fi
