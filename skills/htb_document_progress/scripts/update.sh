#!/bin/bash
# update.sh - Spawn subagent and apply documentation updates
# Called by gather.sh with environment variables set

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🤖 Delegating analysis to subagent..."
echo ""

# Build context for subagent
# This script prepares the context file that will be passed to the subagent

CONTEXT_FILE="$TEMP_DIR/subagent_context.txt"

cat > "$CONTEXT_FILE" << EOF
# HTB Document Progress Update Task

BOX: $BOX_NAME
DATE: $(date -u +"%Y-%m-%d %H:%M UTC")
MODE: $(if $DRY_RUN; then echo "DRY-RUN (preview only)"; else echo "APPLY"; fi)

## BOX DIRECTORY
$BOX_DIR

## INSTRUCTIONS FOR SUBAGENT

You are a documentation assistant for HTB box progress tracking.

Your task: Analyze the provided context and propose structured updates
to recon.md, exploit.md, and privesc.md.

### What to Look For
- Commands executed (nmap, curl, exploit attempts)
- Credentials discovered
- Flags captured (user.txt, root.txt)
- CVEs mentioned or exploited
- Shell access obtained
- Failed attempts (with error messages)
- Tools used
- Lessons learned (explicit statements)

### Entry Format
For each finding, format as:

### [TIMESTAMP] TITLE

**Status:** attempted|successful|failed|in-progress

**Details:**
[What happened, including error context]

**Commands:**
\`\`\`bash
[relevant commands]
\`\`\`

**Result:** [outcome]

### Deduplication
- Check existing doc excerpts provided below
- If similar entry exists → skip or update status
- If new → include in updates

### Output Format
Return ONLY a JSON object:

{
  "recon.md": ["entry1", "entry2"],
  "exploit.md": ["entry1"],
  "privesc.md": ["entry1", "entry2"],
  "summary": "Brief summary of changes"
}

If no updates needed, return:
{"summary": "No new findings to document"}

## EXISTING DOC EXCERPTS

EOF

# Append excerpts from existing docs
for doc in recon.md exploit.md privesc.md; do
    doc_path="$BOX_DIR/$doc"
    echo "" >> "$CONTEXT_FILE"
    echo "### $doc" >> "$CONTEXT_FILE"
    echo "" >> "$CONTEXT_FILE"
    if [[ -f "$doc_path" ]]; then
        # Show last 50 lines for context
        tail -n 50 "$doc_path" >> "$CONTEXT_FILE"
    else
        echo "(File does not exist yet)" >> "$CONTEXT_FILE"
    fi
done

# Append loot file contents
echo "" >> "$CONTEXT_FILE"
echo "## LOOT FILES" >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"

if [[ -d "$BOX_DIR/loot" ]]; then
    find "$BOX_DIR/loot" -type f \( -name "*.md" -o -name "*.txt" \) 2>/dev/null | while read -r file; do
        echo "### $(basename "$file")" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
        cat "$file" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
    done
else
    echo "(loot/ directory not found)" >> "$CONTEXT_FILE"
fi

# Append raw_data file contents
echo "" >> "$CONTEXT_FILE"
echo "## RAW_DATA FILES" >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"

if [[ -d "$BOX_DIR/raw_data" ]]; then
    find "$BOX_DIR/raw_data" -type f \( -name "*.md" -o -name "*.txt" \) 2>/dev/null | while read -r file; do
        echo "### $(basename "$file")" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
        cat "$file" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
    done
else
    echo "(raw_data/ directory not found)" >> "$CONTEXT_FILE"
fi

echo "Context file prepared: $CONTEXT_FILE"
echo ""
echo "NOTE: Session transcript should be retrieved via honcho_session tool"
echo "and combined with this context when spawning the subagent."
echo ""

if $DRY_RUN; then
    echo "🔍 DRY RUN MODE - Preview of context:"
    echo "---"
    head -n 50 "$CONTEXT_FILE"
    echo "---"
    echo ""
    echo "(Full context saved to $CONTEXT_FILE)"
fi

# Output instructions for Neo
cat << EOF

📋 NEXT STEPS FOR NEO:

1. Call honcho_session to get recent transcript
2. Combine with context file: $CONTEXT_FILE
3. Spawn subagent with combined context
4. Parse subagent's JSON response
5. Apply updates to docs (unless --dry-run)

EOF

exit 0
