#!/bin/bash
# document.sh - Entry point for htb_document_progress
# Usage: ./document.sh --box <box-name> [--dry-run]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
HTB_ROOT="${SKILL_DIR}/../../htb"

# Parse arguments
BOX_NAME=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --box)
            BOX_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 --box <box-name> [--dry-run]"
            exit 1
            ;;
    esac
done

# Validate arguments
if [[ -z "$BOX_NAME" ]]; then
    echo "Error: --box is required"
    echo "Usage: $0 --box <box-name> [--dry-run]"
    exit 1
fi

# Validate box exists
BOX_DIR="$HTB_ROOT/boxes/active/$BOX_NAME"
if [[ ! -d "$BOX_DIR" ]]; then
    echo "Error: Box not found: $BOX_DIR"
    echo "Box must be in boxes/active/ directory"
    exit 1
fi

echo "📁 Box: $BOX_NAME"
echo "📂 Directory: $BOX_DIR"
echo ""

# Check for required docs
for doc in recon.md exploit.md privesc.md; do
    if [[ ! -f "$BOX_DIR/$doc" ]]; then
        echo "⚠️  Warning: $doc not found"
    fi
done

# Export for gather.sh
export BOX_NAME
export BOX_DIR
export DRY_RUN
export HTB_ROOT

# Run gather and update
"$SCRIPT_DIR/gather.sh"
