---
name: htb_document_progress
description: Update HTB box documentation (recon.md, exploit.md, privesc.md) based on recent session activity. Captures both successful and failed attempts for documentation hygiene. Use when progressing through an active HTB box and need to sync documentation with recent findings. Trigger with "document progress for <box>" or "htb_document_progress --box <name>".
---

# HTB Document Progress

**Purpose:** Synchronize HTB box documentation with recent session activity.

---

## Overview

This skill maintains documentation hygiene by updating `recon.md`, `exploit.md`, and `privesc.md` based on:
1. Recent session exchanges (last 2-3 hours)
2. Files in `loot/` directory
3. Files in `raw_data/` directory

**Design philosophy:**
- Capture both failures and successes (critical for pentesting rigor)
- Append-only updates (git handles rollback)
- Smart deduplication (update status vs. append new)
- Manual trigger with structured workflow

---

## Execution Flow

```
User: htb_document_progress --box Paper [--dry-run]

1. Validate
   - Check boxes/active/<box>/ exists
   - Verify recon.md, exploit.md, privesc.md exist

2. Gather Inputs
   - Call honcho_session for recent transcript
   - Scan loot/ and raw_data/ directories
   - Read existing doc excerpts for baseline

3. Delegate Analysis
   - Spawn subagent with full context
   - Subagent identifies new vs. existing content
   - Returns structured updates

4. Apply Updates
   - Append entries to appropriate docs
   - Report summary of changes
```

---

## Usage

### Document Current Progress

```
Document progress for Paper
htb_document_progress --box Paper
```

### Preview Without Applying

```
htb_document_progress --box Paper --dry-run
```

---

## File Structure

```
boxes/active/<box-name>/
├── recon.md          # Updated with new findings, services, hosts
├── exploit.md        # Updated with attempts, shells, credentials
├── privesc.md        # Updated with privesc attempts, root progress
├── loot/             # Scanned for credentials, scripts, notes
└── raw_data/         # Scanned for enumeration output, research
```

---

## Entry Format

Each update is appended with ISO timestamp:

```markdown
### [2026-03-22 07:15 UTC] CVE-2021-3560 Exploitation

**Status:** Successful → Root shell obtained

**Details:**
Manual D-Bus timing created "ghost user" — user existed in accounts-daemon
but not /etc/passwd. Switched to 50011.sh which handles timing robustly.

**Commands:**
```bash
chmod +x 50011.sh
./50011.sh
su - hacker
sudo -i
```

**Result:** root.txt captured — `e50eb2bb38c864627c54b8c0d9f0802f`
```

---

## Subagent Task

When delegating, provide subagent with:

1. **Box name** — for context
2. **Session transcript** — recent exchanges (last ~2 hours)
3. **Loot contents** — credentials, scripts, screenshots
4. **Raw data** — enumeration outputs, CVE research
5. **Existing docs** — current state for deduplication

**Subagent instructions:**
- Identify findings not yet documented
- Format with timestamps
- Distinguish attempted vs. successful
- Return JSON: `{ "recon.md": [...], "exploit.md": [...], "privesc.md": [...] }`

---

## Scripts

| Script | Purpose |
|--------|---------|
| `document.sh` | Entry point, argument validation |
| `gather.sh` | Collect session, loot, raw_data, existing docs |
| `update.sh` | Spawn subagent, apply updates |

---

## Error Handling

| Scenario | Response |
|----------|----------|
| Box not found | Error: "Box not in boxes/active/" |
| Missing docs | Warn and create from templates |
| Empty session | Warn: "No recent activity found" |
| Subagent fails | Report error, suggest retry |

---

## Integration

This skill is invoked manually when:
- User says "document progress for <box>"
- User runs `htb_document_progress --box <name>`
- Heartbeat reminder triggers (separate from this skill)

---

## Dependencies

- `honcho_session` tool for session retrieval
- MiniMax subagent for analysis
- File read/write for doc updates
- Git for version safety

---

## Maintenance

To update this skill:
1. Modify `SKILL.md` for documentation changes
2. Update `skill.yaml` for spec changes
3. Iterate based on usage patterns
