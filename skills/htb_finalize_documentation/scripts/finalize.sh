#!/bin/bash
# finalize.sh - Validation script for htb_finalize_documentation
# Usage: ./finalize.sh --box <box-name> [--skip-move]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
# Correct path: ~/.openclaw/workspace-neo/htb/
HTB_ROOT="$(realpath "${SKILL_DIR}/../../htb")"

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

# Check box exists (either in active or already in retired)
BOX_DIR_ACTIVE="$HTB_ROOT/boxes/active/$BOX_NAME"
BOX_DIR_RETIRED="$HTB_ROOT/boxes/retired/$BOX_NAME"

if [[ -d "$BOX_DIR_ACTIVE" ]]; then
    BOX_DIR="$BOX_DIR_ACTIVE"
    BOX_LOCATION="active"
elif [[ -d "$BOX_DIR_RETIRED" ]]; then
    BOX_DIR="$BOX_DIR_RETIRED"
    BOX_LOCATION="retired"
    echo "WARNING: Box already in retired/ - will create writeup only"
else
    echo "ERROR: Box not found: $BOX_NAME"
    echo "Checked: $BOX_DIR_ACTIVE"
    echo "Checked: $BOX_DIR_RETIRED"
    exit 1
fi

# Check for completion markers (look for "ROOTED" or flags in documentation)
# Note: We don't require physical user.txt/root.txt files
HAS_USER_FLAG="false"
HAS_ROOT_FLAG="false"

if [[ -f "$BOX_DIR/recon.md" ]] && grep -qi "root.*flag\|user.*flag\|ROOTED" "$BOX_DIR/recon.md" 2>/dev/null; then
    HAS_USER_FLAG="true"
    HAS_ROOT_FLAG="true"
fi

if [[ -f "$BOX_DIR/privesc.md" ]] && grep -qi "ROOTED\|root.*flag" "$BOX_DIR/privesc.md" 2>/dev/null; then
    HAS_ROOT_FLAG="true"
fi

# Output validation results
echo "DELEGATE_READY"
echo "BOX_NAME:$BOX_NAME"
echo "BOX_DIR:$BOX_DIR"
echo "BOX_LOCATION:$BOX_LOCATION"
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

# Check raw_data/
if [[ -d "$BOX_DIR/raw_data" ]]; then
    file_count=$(find "$BOX_DIR/raw_data" -type f 2>/dev/null | wc -l)
    echo "  raw_data:$file_count files"
fi

exit 0
