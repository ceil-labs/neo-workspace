#!/bin/bash
# finalize.sh - Validation script for htb_finalize_documentation
# Usage: ./finalize.sh --box <box-name> [--skip-move]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
HTB_ROOT="${SKILL_DIR}/../../htb"

# Parse arguments
BOX_NAME=""
SKIP_MOVE="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        --box)
            BOX_NAME="$2"
            shift 2
            ;;
        --skip-move)
            SKIP_MOVE="true"
            shift
            ;;
        *)
            echo "ERROR: Unknown option: $1"
            echo "Usage: $0 --box <box-name> [--skip-move]"
            exit 1
            ;;
    esac
done

# Validate arguments
if [[ -z "$BOX_NAME" ]]; then
    echo "ERROR: --box is required"
    echo "Usage: $0 --box <box-name> [--skip-move]"
    exit 1
fi

# Check box exists in active/
BOX_DIR="$HTB_ROOT/boxes/active/$BOX_NAME"
if [[ ! -d "$BOX_DIR" ]]; then
    echo "ERROR: Box not found in active/: $BOX_DIR"
    echo "Box must be in boxes/active/ directory"
    exit 1
fi

# Check for user flag (in loot/ or at box root)
HAS_USER_FLAG="false"
if [[ -f "$BOX_DIR/loot/user.txt" ]] || \
   [[ -f "$BOX_DIR/user.txt" ]] || \
   grep -q "user.*flag\|user.txt" "$BOX_DIR"/*.md 2>/dev/null | grep -qi "539\|flag"; then
    HAS_USER_FLAG="true"
fi

# Check for root flag (in loot/ or at box root)
HAS_ROOT_FLAG="false"
if [[ -f "$BOX_DIR/loot/root.txt" ]] || \
   [[ -f "$BOX_DIR/root.txt" ]] || \
   grep -q "root.*flag\|root.txt" "$BOX_DIR"/*.md 2>/dev/null | grep -qi "54e\|flag"; then
    HAS_ROOT_FLAG="true"
fi

# Output validation results
echo "DELEGATE_READY"
echo "BOX_NAME:$BOX_NAME"
echo "BOX_DIR:$BOX_DIR"
echo "SKIP_MOVE:$SKIP_MOVE"
echo "HAS_USER_FLAG:$HAS_USER_FLAG"
echo "HAS_ROOT_FLAG:$HAS_ROOT_FLAG"
echo "HTB_ROOT:$HTB_ROOT"

# List existing files for context
echo ""
echo "EXISTING_FILES:"
for doc in recon.md exploit.md privesc.md; do
    if [[ -f "$BOX_DIR/$doc" ]]; then
        lines=$(wc -l < "$BOX_DIR/$doc")
        echo "  $doc:$lines"
    else
        echo "  $doc:0"
    fi
done

# Check loot/
if [[ -d "$BOX_DIR/loot" ]]; then
    find "$BOX_DIR/loot" -type f 2>/dev/null | while read -r f; do
        echo "  loot:$(basename "$f")"
    done
fi

# Check raw_data/
if [[ -d "$BOX_DIR/raw_data" ]]; then
    file_count=$(find "$BOX_DIR/raw_data" -type f 2>/dev/null | wc -l)
    echo "  raw_data:$file_count files"
fi

# Check if already in retired
if [[ -d "$HTB_ROOT/boxes/retired/$BOX_NAME" ]]; then
    echo ""
    echo "WARNING: Box already exists in retired/"
fi

exit 0
