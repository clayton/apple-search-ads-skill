#!/bin/bash
# Get an Apple Search Ads OAuth access token
# Usage: ./get-token.sh
#
# Outputs the access token to stdout (1 hour TTL).
# Uses ES256 JWT signed with APPLE_ADS_PRIVATE_KEY.
#
# Requires environment variables:
#   APPLE_ADS_CLIENT_ID    - Starts with SEARCHADS. (also used as JWT "sub")
#   APPLE_ADS_TEAM_ID      - Starts with SEARCHADS. (also used as JWT "iss")
#   APPLE_ADS_KEY_ID       - UUID key ID (JWT "kid" header)
#   APPLE_ADS_PRIVATE_KEY  - EC P-256 PEM private key
#   APPLE_ADS_ORG_ID       - Numeric org ID
#
# Examples:
#   ./get-token.sh
#   TOKEN=$(./get-token.sh) && echo "Got token: ${TOKEN:0:20}..."

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

get_token
