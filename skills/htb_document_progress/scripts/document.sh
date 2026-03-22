#!/bin/bash
# document.sh - Entry point for htb_document_progress (v2 - Delegation Model)
# Usage: ./document.sh --box <box-name> [--dry-run]
#
# This script validates the box exists and signals readiness.
# The actual delegation to subagent is handled by the parent agent (Neo).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
HTB_ROOT="${SKILL_DIR}/../../htb"

# Parse arguments
BOX_NAME=""
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        --box)
            BOX_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        *)
            echo "ERROR: Unknown option: $1"
            echo "Usage: $0 --box <box-name> [--dry-run]"
            exit 1
            ;;
    esac
done

# Validate arguments
if [[ -z "$BOX_NAME" ]]; then
    echo "ERROR: --box is required"
    echo "Usage: $0 --box <box-name> [--dry-run]"
    exit 1
fi

# Validate box exists
BOX_DIR="$HTB_ROOT/boxes/active/$BOX_NAME"
if [[ ! -d "$BOX_DIR" ]]; then
    echo "ERROR: Box not found: $BOX_DIR"
    echo "Box must be in boxes/active/ directory"
    exit 1
fi

# Output validation result in machine-parseable format
echo "DELEGATE_READY"
echo "BOX_NAME:$BOX_NAME"
echo "BOX_DIR:$BOX_DIR"
echo "DRY_RUN:$DRY_RUN"
echo "HTB_ROOT:$HTB_ROOT"

# List existing files for reference
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

# List loot files
if [[ -d "$BOX_DIR/loot" ]]; then
    find "$BOX_DIR/loot" -type f 2>/dev/null | while read -r f; do
        echo "  loot:$(basename "$f")"
    done
fi

# List raw_data files  
if [[ -d "$BOX_DIR/raw_data" ]]; then
    find "$BOX_DIR/raw_data" -type f 2>/dev/null | while read -r f; do
        echo "  raw_data:$(basename "$f")"
    done
fi

exit 0
