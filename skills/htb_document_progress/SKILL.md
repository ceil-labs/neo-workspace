---
name: htb_document_progress
description: Update HTB box documentation (recon.md, exploit.md, privesc.md) based on recent session activity. Fully delegates analysis to subagent for third-party perspective.
triggers:
  - "document progress for {box}"
  - "htb_document_progress --box {box}"
---

# HTB Document Progress (v2 - Full Delegation)

**Purpose:** Synchronize HTB box documentation with recent session activity using a delegated subagent for independent analysis.

---

## Overview

This skill maintains documentation hygiene by updating `recon.md`, `exploit.md`, and `privesc.md` based on:
1. **Recent session exchanges** (via `memory_search`) — captures session context via semantic search
2. **Command execution logs** (`raw_data/cmd_*.log`) — captures exact commands and full output
3. **Files in `loot/` and `raw_data/`** — supporting artifacts

**Architecture (v3):**
- **Neo (parent):** Validates box exists, spawns subagent, applies updates
- **Subagent:** Does ALL analysis from dual sources (session + logs)
- **Benefit:** Complete picture — conversation explains *why*, logs show *what* and *results*

---

## Execution Flow

```
User: document progress for Writeup

1. Validate (document.sh)
   - Check boxes/active/<box>/ exists
   - Detect cmd_*.log files in raw_data/
   - Output machine-parseable READY signal

2. Delegate (Neo spawns subagent)
   - Subagent receives BOX_NAME, BOX_DIR, DRY_RUN flag

3. Subagent Analysis (Dual Source)
   ├─ Source 1: memory_search → session context via semantic search
   ├─ Source 2: raw_data/cmd_*.log → exact commands, full output, timestamps
   ├─ Read existing docs (recon.md, exploit.md, privesc.md)
   ├─ List loot/ directory
   └─ Synthesize: Merge conversation + logs for complete picture

4. Return JSON
   {
     "recon.md": "full updated content or null",
     "exploit.md": "full updated content or null", 
     "privesc.md": "full updated content or null",
     "summary": "Brief description of changes"
   }

5. Apply (Neo)
   - Write updates to docs (unless --dry-run)
   - Report summary to user
```

---

## Usage

### Document Current Progress
```
document progress for Writeup
htb_document_progress --box Writeup
```

### Preview Without Applying
```
htb_document_progress --box Writeup --dry-run
```

---

## File Structure

```
boxes/active/<box-name>/
├── recon.md          # Updated by subagent analysis
├── exploit.md        # Updated by subagent analysis
├── privesc.md        # Updated by subagent analysis
├── loot/             # Scanned by subagent
└── raw_data/         # Scanned by subagent
```

---

## Subagent Task Specification

When spawning the subagent, provide:

```yaml
box_name: Writeup
box_dir: /home/openclaw/.openclaw/workspace-neo/htb/boxes/active/Writeup
dry_run: false
```

**Subagent Instructions:**
1. **IMPORTANT: Use the absolute BOX_DIR path provided** — do not construct paths manually
2. **Dual Source Analysis:**
   - Call `memory_search` with a query about recent session activity for the box
   - List `raw_data/cmd_*.log` files: `ls -la BOX_DIR/raw_data/cmd_*.log`
   - Read each cmd_*.log file for exact commands, output, and timestamps
3. Use `read` tool to fetch existing docs from BOX_DIR: recon.md, exploit.md, privesc.md
4. Use `exec` with absolute paths to list files: `ls -la BOX_DIR/loot/`
5. **Merge Sources:** Combine conversation context (why) + command logs (what/output) for richer docs
6. Format updates with ISO timestamps
7. Return JSON: `{ "recon.md": "...", "exploit.md": "...", "privesc.md": "...", "summary": "..." }`

**Deduplication:** Subagent compares against existing docs to avoid redundant entries.

---

## Integration with `run` Command

This skill works best with the `run` function (see `~/.openclaw/shell-utils/run-function.sh`):

```bash
# Use run to execute commands with automatic logging
run nmap -sC -sV 10.129.231.37
# Creates: raw_data/cmd_20260326_105612.log

# Later, document captures both conversation and logs
document progress for BoardLight
```

**Without `run`:** Skill uses `memory_search` only (session context)  
**With `run`:** Skill merges `memory_search` + `cmd_*.log` files (complete picture)

### Dual Source Benefits

| Source | Captures | Example |
|--------|----------|---------|
| `memory_search` | Session context via semantic search | "Victor asked about port 80 being open, suggesting web enumeration" |
| `cmd_*.log` | Exact commands, full output, timestamps | `nmap -sC -sV 10.129.231.37` → ports 22, 80 found at 10:05:32 |
| **Merged** | Complete narrative | "At 10:05, Victor ran nmap to start recon and asked about port 80, finding SSH and HTTP services..." |

---

## Entry Format

Subagent should format entries with ISO timestamps:

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

## Scripts

| Script | Purpose |
|--------|---------|
| `document.sh` | Validates box exists, outputs READY signal with metadata |
| `apply.sh` | Applies JSON updates from subagent to documentation files |

*Note: v2 removed gather.sh, update.sh — all analysis now delegated to subagent.*

---

## Error Handling

| Scenario | Response |
|----------|----------|
| Box not found | Script error exit with message |
| Missing docs | Warning only — subagent handles creation logic |
| Empty session | Subagent reports "No activity to document" |
| Subagent fails | Report error, suggest retry |

---

## Integration

This skill is invoked:
- When user says "document progress for <box>"
- When user runs `htb_document_progress --box <name>`

The parent agent (Neo) handles the subagent spawning — not the bash script.

---

## Dependencies

- Subagent must have access to `memory_search` tool (local SQLite memory)
- Subagent must have access to `read`, `write`, `exec` tools
- Git for version safety (changes are tracked)

---

## Migration Notes (v1 → v2)

**v1:** Bash scripts gathered data, packed into temp files, subagent analyzed packed data  
**v2:** Single validation script, subagent explores filesystem directly

**Benefits of v2:**
- Subagent has third-party perspective (didn't participate in original session)
- No temp file management
- Subagent reads only what it needs
- Cleaner architecture

---

_Changelog: v3.0 - Dual source architecture: memory_search + cmd_*.log files  
v2.0 - Full delegation architecture, removed intermediate bash scripts_
