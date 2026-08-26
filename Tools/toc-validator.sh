#!/usr/bin/env bash
# toc-validator.sh
# Validates that every file referenced in .toc and .xml files actually exists.
#
# Usage:
#   ./Tools/toc-validator.sh
#
# Exit codes:
#   0 — all referenced files exist
#   1 — one or more referenced files are missing

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOC="$REPO_ROOT/MythicPlusTracker.toc"
ERRORS=0

if [ ! -f "$TOC" ]; then
    echo "ERROR: .toc file not found: $TOC"
    exit 1
fi

echo "=== TOC Validator ==="
echo ""

# ---------------------------------------------------------------------------
# Step 1: Check files listed directly in the .toc file
# ---------------------------------------------------------------------------
echo "--- MythicPlusTracker.toc ---"

while IFS= read -r line; do
    # Strip the CR of CRLF line endings (core.autocrlf checkouts on Windows)
    line="${line%$'\r'}"

    # Skip blank lines and ## metadata lines
    [[ -z "$line" || "$line" =~ ^## ]] && continue

    # Normalize path separators (WoW uses backslashes on Windows)
    filepath="${line//\\//}"
    full_path="$REPO_ROOT/$filepath"

    if [ ! -f "$full_path" ]; then
        echo "MISSING  $filepath"
        ERRORS=$((ERRORS + 1))
    else
        echo "OK       $filepath"
    fi
done < "$TOC"

echo ""

# ---------------------------------------------------------------------------
# Step 2: Check files referenced inside every .xml file
# ---------------------------------------------------------------------------
echo "--- XML file references ---"

while IFS= read -r xml_file; do
    xml_dir="$(dirname "$xml_file")"
    rel_xml="${xml_file#"$REPO_ROOT/"}"
    has_issue=false

    # Extract values of file='...' attributes from <Include> and <Script> tags
    # Handles both single and double quotes
    while IFS= read -r ref; do
        # Normalize path separator
        ref="${ref//\\//}"

        # Resolve relative to the XML file's directory
        resolved="$xml_dir/$ref"

        # Canonicalise without requiring the path to exist (realpath -m)
        canonical="$(realpath -m "$resolved")"

        if [ ! -f "$canonical" ]; then
            if ! $has_issue; then
                echo ""
                echo "In $rel_xml:"
                has_issue=true
            fi
            echo "  MISSING  $ref"
            ERRORS=$((ERRORS + 1))
        fi
    done < <(grep -oP "(?<=file=['\"])[^'\"]+(?=['\"])" "$xml_file" 2>/dev/null)

    if ! $has_issue; then
        echo "OK       $rel_xml"
    fi
done < <(find "$REPO_ROOT" -name "*.xml" -not -path "*/.git/*" | sort)

echo ""
if [ "$ERRORS" -eq 0 ]; then
    echo "All referenced files exist."
else
    echo "$ERRORS missing file reference(s) found."
    exit 1
fi
