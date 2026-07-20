#!/usr/bin/env bash
# locale-validator.sh
# Validates that all locale files contain the same keys as the reference (en-US.lua).
#
# Usage:
#   ./Tools/locale-validator.sh
#
# Exit codes:
#   0 — all locale files are complete
#   1 — one or more files have missing or extra keys

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REFERENCE="$REPO_ROOT/Locales/en-US.lua"
ERRORS=0

if [ ! -f "$REFERENCE" ]; then
    echo "ERROR: Reference locale not found: $REFERENCE"
    exit 1
fi

# Extract locale keys from a file.
# Keys follow the pattern: ["KEY_NAME"] = "..."
extract_keys() {
    grep -oP '(?<=\[")[A-Z_0-9]+(?="\])' "$1" 2>/dev/null | sort -u
}

ref_keys=$(extract_keys "$REFERENCE")
ref_count=$(echo "$ref_keys" | wc -l)

echo "=== Locale Validator ==="
echo "Reference: Locales/en-US.lua ($ref_count keys)"
echo ""

for locale_file in "$REPO_ROOT/Locales/"*.lua; do
    [ "$locale_file" = "$REFERENCE" ] && continue

    rel_path="Locales/$(basename "$locale_file")"
    locale_keys=$(extract_keys "$locale_file")
    file_ok=true

    # Keys in reference but missing from this locale
    missing=$(comm -23 <(echo "$ref_keys") <(echo "$locale_keys"))
    if [ -n "$missing" ]; then
        echo "FAIL $rel_path -- MISSING keys:"
        echo "$missing" | sed 's/^/    /'
        ERRORS=$((ERRORS + 1))
        file_ok=false
    fi

    # Keys in this locale but not in reference (stale / orphaned)
    extra=$(comm -13 <(echo "$ref_keys") <(echo "$locale_keys"))
    if [ -n "$extra" ]; then
        echo "WARN $rel_path -- EXTRA keys (not in en-US, possibly stale):"
        echo "$extra" | sed 's/^/    /'
        ERRORS=$((ERRORS + 1))
        file_ok=false
    fi

    if $file_ok; then
        locale_count=$(echo "$locale_keys" | wc -l)
        echo "OK   $rel_path ($locale_count keys)"
    fi
done

echo ""
if [ "$ERRORS" -eq 0 ]; then
    echo "All locale files are complete."
else
    echo "Found issues in $ERRORS locale file(s)."
    exit 1
fi
