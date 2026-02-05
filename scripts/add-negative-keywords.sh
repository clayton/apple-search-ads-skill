#!/bin/bash
# Add negative keywords to an Apple Search Ads ad group
# Usage: ./add-negative-keywords.sh --campaign-id ID --adgroup-id ID --keywords "kw1,kw2" [--match-type EXACT|BROAD]
#
# Examples:
#   ./add-negative-keywords.sh --campaign-id 123 --adgroup-id 456 --keywords "free,cheap"
#   ./add-negative-keywords.sh --campaign-id 123 --adgroup-id 456 --keywords "competitor" --match-type BROAD

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Defaults
MATCH_TYPE="EXACT"
CAMPAIGN_ID=""
ADGROUP_ID=""
KEYWORDS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --campaign-id) CAMPAIGN_ID="$2"; shift 2 ;;
        --adgroup-id) ADGROUP_ID="$2"; shift 2 ;;
        --keywords) KEYWORDS="$2"; shift 2 ;;
        --match-type) MATCH_TYPE="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 --campaign-id ID --adgroup-id ID --keywords \"kw1,kw2\" [--match-type EXACT|BROAD]"
            echo ""
            echo "Negative keywords prevent your ad from showing for specific search terms."
            echo ""
            echo "Options:"
            echo "  --keywords     Comma-separated list of negative keywords to add"
            echo "  --match-type   EXACT (default) or BROAD"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Validate required arguments
if [ -z "$CAMPAIGN_ID" ] || [ -z "$ADGROUP_ID" ] || [ -z "$KEYWORDS" ]; then
    echo "Error: --campaign-id, --adgroup-id, and --keywords are required" >&2
    echo "Usage: $0 --campaign-id ID --adgroup-id ID --keywords \"kw1,kw2\"" >&2
    exit 1
fi

# Build JSON array from comma-separated keywords
IFS=',' read -ra KW_ARRAY <<< "$KEYWORDS"
JSON_ARRAY="["
for i in "${!KW_ARRAY[@]}"; do
    # Trim whitespace
    kw=$(echo "${KW_ARRAY[$i]}" | xargs)

    [ $i -gt 0 ] && JSON_ARRAY+=","
    JSON_ARRAY+="{\"text\":\"$kw\",\"matchType\":\"$MATCH_TYPE\"}"
done
JSON_ARRAY+="]"

# Add negative keywords
echo "Adding ${#KW_ARRAY[@]} negative keyword(s) to ad group $ADGROUP_ID..." >&2
response=$(api_post "/campaigns/$CAMPAIGN_ID/adgroups/$ADGROUP_ID/negativekeywords" "$JSON_ARRAY")

# Check for errors
if ! check_error "$response"; then
    exit 1
fi

# Output result
if command -v jq &> /dev/null; then
    echo "$response" | jq '.data[] | {
        id: .id,
        text: .text,
        matchType: .matchType,
        status: .status
    }'
    echo ""
    echo "Negative keywords added successfully." >&2
else
    echo "$response"
fi
