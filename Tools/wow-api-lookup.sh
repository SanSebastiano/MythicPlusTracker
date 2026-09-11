#!/usr/bin/env bash
# wow-api-lookup.sh
# Fetches WoW API documentation from warcraft.wiki.gg.
#
# Usage:
#   ./Tools/wow-api-lookup.sh <API_name>
#
# Examples:
#   ./Tools/wow-api-lookup.sh C_MythicPlus.GetRunHistory
#   ./Tools/wow-api-lookup.sh C_ChallengeMode.GetMapTable
#   ./Tools/wow-api-lookup.sh CHALLENGE_MODE_MAPS_UPDATE
#   ./Tools/wow-api-lookup.sh CreateFrame

set -euo pipefail

WIKI_BASE="https://warcraft.wiki.gg/wiki"
USER_AGENT="MythicPlusTracker-api-lookup (addon development, single on-demand lookup)"

usage() {
    echo "Usage: $0 <API_function_or_event>"
    echo ""
    echo "Examples:"
    echo "  $0 C_MythicPlus.GetRunHistory"
    echo "  $0 C_ChallengeMode.GetMapTable"
    echo "  $0 CHALLENGE_MODE_MAPS_UPDATE"
    echo "  $0 CreateFrame"
    echo ""
    echo "Full API index: $WIKI_BASE/World_of_Warcraft_API"
}

QUERY=""

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        *)
            QUERY="$1"
            shift
            ;;
    esac
done

if [ -z "$QUERY" ]; then
    usage
    exit 1
fi

if ! command -v curl &>/dev/null; then
    echo "curl not found — install it, or open the documentation in a browser."
    exit 0
fi

# Strips HTML tags and entities, collapses blank lines. Rough but readable.
strip_html() {
    sed 's/<style[^>]*>.*<\/style>//gI' \
        | sed 's/<script[^>]*>.*<\/script>//gI' \
        | sed 's/<[^>]*>//g' \
        | sed 's/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g; s/&nbsp;/ /g; s/&#[0-9]*;//g' \
        | sed '/^[[:space:]]*$/d' \
        | sed 's/^[[:space:]]*//'
}

lookup_wiki() {
    # Page titles keep the dots but differ by symbol kind: API functions live
    # under an "API_" prefix (API_C_ChallengeMode.GetMapTable), events do not
    # (CHALLENGE_MODE_MAPS_UPDATE, where the prefixed title 404s). Try the
    # prefix first — the bare title can be a redirect stub with no content.
    local candidates=("API_${QUERY}" "${QUERY}")

    echo "=== WoW API Lookup: $QUERY (warcraft.wiki.gg) ==="
    echo ""

    local url="" code candidate
    for candidate in "${candidates[@]}"; do
        code=$(curl -sL -o /dev/null --max-time 10 -A "$USER_AGENT" \
                    -w '%{http_code}' "${WIKI_BASE}/${candidate}" 2>/dev/null) || code="000"
        if [ "$code" = "200" ]; then
            url="${WIKI_BASE}/${candidate}"
            break
        fi
    done

    if [ -z "$url" ]; then
        echo "Page not found on warcraft.wiki.gg (tried '${QUERY}' and 'API_${QUERY}')."
        echo ""
        echo "Try searching: https://warcraft.wiki.gg/index.php?search=${QUERY}"
        exit 0
    fi

    echo "URL: $url"
    echo ""

    local raw
    raw=$(curl -sL --max-time 10 -A "$USER_AGENT" "$url" 2>/dev/null) || {
        echo "Could not fetch page (network error)."
        echo "Open: $url"
        exit 0
    }

    # MediaWiki wraps the article in mw-parser-output and ends it at
    # printfooter. Everything outside that is chrome and inline scripts, which
    # survive tag stripping and would bury the signature.
    echo "$raw" \
        | sed -n '/mw-parser-output/,/printfooter/p' \
        | strip_html \
        | sed -e '/NewPP limit report/,$d' -e '/^<!--/d' \
        | head -80

    echo ""
    echo "Full page: $url"
}

lookup_wiki
