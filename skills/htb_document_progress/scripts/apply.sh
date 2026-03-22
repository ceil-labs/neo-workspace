#!/bin/bash
# apply.sh - Apply JSON updates from subagent to documentation files
# Usage: ./apply.sh <box-dir> <json-file>
# Or: echo '{"recon.md":"...",...}' | ./apply.sh <box-dir> -

set -e

BOX_DIR="$1"
JSON_INPUT="$2"

if [[ -z "$BOX_DIR" || -z "$JSON_INPUT" ]]; then
    echo "Usage: $0 <box-dir> <json-file>"
    echo "   or: echo '{...}' | $0 <box-dir> -"
    exit 1
fi

if [[ "$JSON_INPUT" == "-" ]]; then
    JSON=$(cat)
else
    if [[ ! -f "$JSON_INPUT" ]]; then
        echo "Error: JSON file not found: $JSON_INPUT"
        exit 1
    fi
    JSON=$(cat "$JSON_INPUT")
fi

# Validate JSON is not empty
if [[ -z "$JSON" ]]; then
    echo "Error: Empty JSON input"
    exit 1
fi

# Check for required fields
if ! echo "$JSON" | grep -q '"summary"'; then
    echo "Error: JSON missing 'summary' field"
    exit 1
fi

echo "📋 Applying updates to $BOX_DIR"
echo ""

# Parse and apply each document
UPDATES=0

for doc in recon.md exploit.md privesc.md; do
    # Extract content using simple grep/sed (jq not required)
    CONTENT=$(echo "$JSON" | grep -oP "\"$doc\":\"\K[^\"]*" | sed 's/\\n/\n/g' | sed 's/\\\\/\\/g' || true)
    
    if [[ -n "$CONTENT" ]]; then
        echo "📝 Updating $doc..."
        echo "$CONTENT" > "$BOX_DIR/$doc"
        UPDATES=$((UPDATES + 1))
    else
        echo "  $doc: no changes"
    fi
done

echo ""
echo "✅ Applied $UPDATES document updates"

# Output summary
SUMMARY=$(echo "$JSON" | grep -oP '"summary":"\K[^"]*' || echo "Documentation updated")
echo ""
echo "Summary: $SUMMARY"
