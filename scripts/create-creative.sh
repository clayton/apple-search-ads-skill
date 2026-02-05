#!/bin/bash
# Create a creative for a Custom Product Page in Apple Search Ads
# Usage: ./create-creative.sh --adam-id APP_ID --name NAME --product-page-id UUID
#
# Examples:
#   ./create-creative.sh --adam-id 123456789 --name "Summer Sale CPP" --product-page-id abc-123-def

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Defaults
ADAM_ID=""
CREATIVE_NAME=""
PRODUCT_PAGE_ID=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --adam-id) ADAM_ID="$2"; shift 2 ;;
        --name) CREATIVE_NAME="$2"; shift 2 ;;
        --product-page-id) PRODUCT_PAGE_ID="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 --adam-id APP_ID --name NAME --product-page-id UUID"
            echo ""
            echo "Options:"
            echo "  --adam-id         App Store app ID (required)"
            echo "  --name            Creative name (required)"
            echo "  --product-page-id Custom Product Page UUID from App Store Connect (required)"
            echo ""
            echo "Custom Product Pages (CPPs) are created in App Store Connect."
            echo "Use this script to create an Apple Search Ads creative from a CPP."
            exit 0
            ;;
        *) shift ;;
    esac
done

# Validate required arguments
if [ -z "$ADAM_ID" ] || [ -z "$CREATIVE_NAME" ] || [ -z "$PRODUCT_PAGE_ID" ]; then
    echo "Error: --adam-id, --name, and --product-page-id are required" >&2
    echo "Usage: $0 --adam-id APP_ID --name NAME --product-page-id UUID" >&2
    exit 1
fi

# Build request body
body=$(cat <<EOF
{
    "adamId": $ADAM_ID,
    "name": "$CREATIVE_NAME",
    "type": "CUSTOM_PRODUCT_PAGE",
    "productPageId": "$PRODUCT_PAGE_ID"
}
EOF
)

# Create creative
echo "Creating creative '$CREATIVE_NAME'..." >&2
response=$(api_post "/creatives" "$body")

# Check for errors
if ! check_error "$response"; then
    exit 1
fi

# Output result
if command -v jq &> /dev/null; then
    echo "$response" | jq '.data | {
        id: .id,
        name: .name,
        type: .type,
        adamId: .adamId,
        productPageId: .productPageId,
        state: .state
    }'
    echo ""
    echo "Creative created successfully." >&2
    echo "Use the creative ID to create ads with ./create-ad.sh" >&2
else
    echo "$response"
fi
