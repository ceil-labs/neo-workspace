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
1. Recent session exchanges (via `honcho_session`)
2. Files in `loot/` directory
3. Files in `raw_data/` directory

**Architecture (v2):**
- **Neo (parent):** Validates box exists, spawns subagent, applies updates
- **Subagent:** Does ALL analysis (session retrieval, file exploration, synthesis)
- **Benefit:** Third-party perspective, cleaner separation of concerns

---

## Execution Flow

```
User: document progress for Writeup

1. Validate (document.sh)
   - Check boxes/active/<box>/ exists
   - Output machine-parseable READY signal

2. Delegate (Neo spawns subagent)
   - Subagent receives BOX_NAME, BOX_DIR, DRY_RUN flag

3. Subagent Analysis
   ├─ Call honcho_session → session transcript
   ├─ Read existing docs (recon.md, exploit.md, privesc.md)
   ├─ List loot/ and raw_data/ directories
   ├─ Read relevant files
   └─ Synthesize findings vs. existing content

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
2. Call `honcho_session` with `messageLimit: 4000` to get recent session transcript
3. Use `read` tool to fetch existing docs from BOX_DIR: recon.md, exploit.md, privesc.md
4. Use `exec` with absolute paths to list files: `ls -la BOX_DIR/loot/` and `ls -la BOX_DIR/raw_data/`
5. Use `read` to fetch relevant raw data files using absolute BOX_DIR paths
6. Analyze: identify new findings vs. existing documented content
7. Format updates with ISO timestamps
8. Return JSON: `{ "recon.md": "...", "exploit.md": "...", "privesc.md": "...", "summary": "..." }`

**Deduplication:** Subagent compares against existing docs to avoid redundant entries.

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

- Subagent must have access to `honcho_session` tool (confirmed working)
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

_Changelog: v2.0 - Full delegation architecture, removed intermediate bash scripts_
