#!/usr/bin/env bash
# registration-validator.sh
# Validates that every .lua file in the addon is actually registered in a
# .toc or .xml load-order manifest. The inverse of toc-validator.sh: an
# unregistered file produces no error and no warning in-game, it simply
# never runs — so nothing but this check catches it.
#
# Usage:
#   ./Tools/registration-validator.sh
#
# Exit codes:
#   0 — every .lua file is registered
#   1 — one or more .lua files are not referenced from any manifest

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOC="$REPO_ROOT/MythicPlusTracker.toc"

if [ ! -f "$TOC" ]; then
    echo "ERROR: .toc file not found: $TOC"
    exit 1
fi

echo "=== Registration Validator ==="
echo ""

registered="$(mktemp)"
present="$(mktemp)"
trap 'rm -f "$registered" "$present"' EXIT

# ---------------------------------------------------------------------------
# Collect every path referenced from the .toc (relative to the repo root)
# ---------------------------------------------------------------------------
while IFS= read -r line; do
    line="${line%$'\r'}"
    [[ -z "$line" || "$line" =~ ^## ]] && continue

    filepath="${line//\//}"
    realpath -m --relative-to="$REPO_ROOT" "$REPO_ROOT/$filepath" >> "$registered"
done < "$TOC"

# ---------------------------------------------------------------------------
# Collect every path referenced from an .xml manifest. References resolve
# relative to the referencing .xml file's own directory, not the repo root.
# ---------------------------------------------------------------------------
while IFS= read -r xml_file; do
    xml_dir="$(dirname "$xml_file")"

    while IFS= read -r ref; do
        ref="${ref//\//}"
        realpath -m --relative-to="$REPO_ROOT" "$xml_dir/$ref" >> "$registered"
    done < <(grep -oP "(?<=file=['\"])[^'\"]+(?=['\"])" "$xml_file" 2>/dev/null)
done < <(find "$REPO_ROOT" -name "*.xml" -not -path "*/.git/*" -not -path "*/.idea/*" | sort)

# ---------------------------------------------------------------------------
# Collect every .lua file that actually exists
# ---------------------------------------------------------------------------
while IFS= read -r lua_file; do
    realpath -m --relative-to="$REPO_ROOT" "$lua_file" >> "$present"
done < <(find "$REPO_ROOT" -name "*.lua" \
    -not -path "*/.git/*" -not -path "*/.idea/*" -not -path "*/.luarocks/*" | sort)

orphans="$(comm -13 <(sort -u "$registered") <(sort -u "$present"))"

if [ -z "$orphans" ]; then
    echo "All $(sort -u "$present" | wc -l | tr -d ' ') .lua files are registered."
    exit 0
fi

echo "Not referenced from any .toc/.xml manifest:"
echo ""
printf '  UNREGISTERED  %s\n' $orphans
echo ""
echo "$(printf '%s\n' $orphans | wc -l | tr -d ' ') unregistered file(s) found."
exit 1
