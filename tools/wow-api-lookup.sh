#!/usr/bin/env bash
# wow-api-lookup.sh
# Fetches WoW API documentation from warcraft.wiki.gg.
#
# Usage:
#   ./tools/wow-api-lookup.sh <API_name>
#
# Examples:
#   ./tools/wow-api-lookup.sh C_MythicPlus.GetRunHistory
#   ./tools/wow-api-lookup.sh C_ChallengeMode.GetMapTable
#   ./tools/wow-api-lookup.sh CHALLENGE_MODE_MAPS_UPDATE
#   ./tools/wow-api-lookup.sh CreateFrame

set -euo pipefail

if [ -z "${1-}" ]; then
    echo "Usage: $0 <API_function_or_event>"
    echo ""
    echo "Examples:"
    echo "  $0 C_MythicPlus.GetRunHistory"
    echo "  $0 C_ChallengeMode.GetMapTable"
    echo "  $0 CHALLENGE_MODE_MAPS_UPDATE"
    echo "  $0 CreateFrame"
    echo ""
    echo "Full API index: https://warcraft.wiki.gg/wiki/World_of_Warcraft_API"
    exit 1
fi

QUERY="$1"
# warcraft.wiki.gg uses the function name as the page title (dots preserved)
URL="https://warcraft.wiki.gg/wiki/${QUERY}"

echo "=== WoW API Lookup: $QUERY ==="
echo "URL: $URL"
echo ""

# Fetch the page and extract readable text by stripping HTML tags.
# Requires: curl (standard on Linux/macOS; available via Git Bash on Windows)
if ! command -v curl &>/dev/null; then
    echo "curl not found. Open the URL above in your browser."
    exit 0
fi

RAW=$(curl -sL --max-time 10 "$URL" 2>/dev/null) || {
    echo "Could not fetch page (network error or page not found)."
    echo "Open: $URL"
    exit 0
}

# Check for "page does not exist" response
if echo "$RAW" | grep -q "does not exist"; then
    echo "Page not found on warcraft.wiki.gg."
    echo ""
    echo "Try searching: https://warcraft.wiki.gg/index.php?search=${QUERY}"
    exit 0
fi

# Strip HTML tags, collapse whitespace, remove blank lines, show first 80 lines.
# This gives a rough but useful text dump of the page content.
echo "$RAW" \
    | sed 's/<style[^>]*>.*<\/style>//gI' \
    | sed 's/<script[^>]*>.*<\/script>//gI' \
    | sed 's/<[^>]*>//g' \
    | sed 's/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g; s/&nbsp;/ /g; s/&#[0-9]*;//g' \
    | sed '/^[[:space:]]*$/d' \
    | sed 's/^[[:space:]]*//' \
    | head -80

echo ""
echo "Full page: $URL"
