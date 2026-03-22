---
interval: 60m
model: opencode-go/minimax-m2.5
---

# Neo Documentation Hygiene Check

## Task
Check if active HTB box needs documentation sync.

## Steps
1. Find active box: `htb/boxes/active/*`
2. Get recent session via `honcho_session` (last 2h)
3. Check docs vs. session/loot/raw_data timestamps
4. If session exists AND docs stale → remind
5. Else → silent (OK)

## Subagent Input
- Box name (if active box found)
- Session transcript (recent exchanges)
- Doc timestamps (recon.md, exploit.md, privesc.md mtime)
- Loot/raw_data file list with mtimes

## Subagent Decision
```
IF session_has_content AND (docs_older_than_session OR new_unprocessed_files):
    OUTPUT: "📋 <box>: documentation may need sync\n"
            "Recent: <brief summary>\n"
            "Run: htb_document_progress --box <box>"
ELSE:
    OUTPUT: ""  (silent / no notification)
```

## Message Rules
- Be specific about what triggered the reminder
- Include actionable command
- No message if documentation appears current
