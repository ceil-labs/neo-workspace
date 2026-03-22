#!/bin/bash
# gather.sh - Collect all inputs for documentation update
# Called by document.sh with environment variables set

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create temp directory for gathered data
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "🔍 Gathering context..."
echo ""

# 1. Session transcript (placeholder - actual call happens in update.sh via subagent)
echo "Session context will be retrieved via honcho_session tool"

# 2. Scan loot directory
echo "📦 Scanning loot/..."
LOOT_DIR="$BOX_DIR/loot"
if [[ -d "$LOOT_DIR" ]]; then
    find "$LOOT_DIR" -type f -name "*.md" -o -name "*.txt" 2>/dev/null | while read -r file; do
        echo "  Found: $(basename "$file")"
    done
else
    echo "  (loot/ directory not found or empty)"
fi

# 3. Scan raw_data directory
echo "📄 Scanning raw_data/..."
RAW_DIR="$BOX_DIR/raw_data"
if [[ -d "$RAW_DIR" ]]; then
    find "$RAW_DIR" -type f -name "*.md" -name "*.txt" 2>/dev/null | while read -r file; do
        echo "  Found: $(basename "$file")"
    done
else
    echo "  (raw_data/ directory not found or empty)"
fi

# 4. Check existing docs
echo "📝 Checking existing documentation..."
for doc in recon.md exploit.md privesc.md; do
    if [[ -f "$BOX_DIR/$doc" ]]; then
        lines=$(wc -l < "$BOX_DIR/$doc")
        echo "  $doc: $lines lines"
    else
        echo "  $doc: (not found)"
    fi
done

echo ""
echo "✅ Context gathered"
echo ""

# Export temp dir for update.sh
export TEMP_DIR
export BOX_NAME
export BOX_DIR
export DRY_RUN

# Run update
"$SCRIPT_DIR/update.sh"
