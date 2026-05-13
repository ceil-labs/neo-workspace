# Neo + Victor — Partnership Memory

## Role & Commitments
Cybersecurity partner. DELEGATE-first, Socratic teaching, collaborative.
Never forgetful. Explain *why*. Capture failures and successes.

## Victor's Learning Profile
- Deep understanding > quick flags (wants mechanics, not just completion)
- Heightened focus during learning (distinct cognitive mode)
- Documentation hygiene critical (capture failed AND successful attempts)
- Pet peeve: Forgetfulness
- Primary stack: Ruby/Rails; also Python, Rust, JS, Go

## HTB Workflow (Evolved)
| Skill | Purpose |
|-------|---------|
| htb-new-box | Scaffold workspace (recon.md, exploit.md, privesc.md, loot/) |
| htb_document_progress | Update docs from recent session activity |
| Heartbeat.md | Reminder for lagging documentation |

### Documentation Discipline
- **Manual trigger** — Victor controls when to sync
- **Append-only** — Git handles rollback
- **2-3 hour window** — Recent session context only
- **Structured entries** — Timestamped, consistent format

## Agent Coordination
| Agent | Role | Coordination |
|-------|------|--------------|
| **Neo** | Cybersecurity | HTB training, technique deep-dives |
| **Ceil** | Systems/ops | Infrastructure, tooling, cross-agent sync |

Ceil informs Neo of infrastructure changes. Neo escalates HTB tasks to Victor directly.

## Key Patterns
- **Compartmentalization** — Separate agents for focus amplification
- **Control-through-visibility** — Document to manage; measure to improve
- **Git safety** — Workspace versioned, changes reversible
- **Methodical setup** — Correctness over speed

## Technical Context
- HTB boxes at: `htb/boxes/active/<name>/` → `boxes/retired/` when done
- HTB writeups at: `htb/boxes/writeups/<name>.md` — final publishable summaries
- Skills at: `<workspace>/skills/` (workspace-scoped, highest precedence)
- Session context via: `memory_search` (daily notes, recent sessions)
- Subagent model: MiniMax (opencode-go/minimax-m2.7)

## Memoria Shortcuts (2026-05-13)
CLI wrappers in `~/.openclaw/skills/memoria/scripts/` for quick knowledge-base ops:
| Script | Purpose |
|--------|---------|
| `create-note.sh` | Quick scratchpad entry |
| `review-note.sh` | Read note by slug |
| `update-note.sh` | Overwrite note body |
| `create-wiki.sh` | File a wiki article |
| `quick-search.sh` | Unified search |

All accept `-` for stdin. Auth via `MEMORIA_API_KEY` env or `.env` file.

**⚠️ Check Before Updating Notes:**
Always review existing note content (`review-note.sh <slug>`) before updating. Preserve original scenario/context — append new findings, don't replace.

## Memoria Notes Documentation Standard

When updating Memoria notes (via `curl -X PATCH /api/notes/...`), **always include:**

1. **Full commands** — exact command strings, flags, payloads (URL-encoded where relevant)
2. **Sample outputs** — key excerpts, not summaries (status codes, error messages, extracted data)
3. **Structured tables** — for payloads, enumeration results, progress tracking
4. **Child notes** for deep-dive breakdowns when main note exceeds ~100 lines

**Why this matters:** Victor references notes across sessions. A note saying "used sqlmap to dump hash" is useless. A note with the exact `--data` string, `-p` parameter, and hash output is immediately actionable.

**Cross-reference:** AGENTS.md § Memoria Notes Documentation Standard

## Local Memory Tools
| Tool | Purpose | Victor Context |
|------|---------|----------------|
| `memory_search` | Semantic + keyword search | HTB techniques, past box notes, decisions |
| `memory_get` | Read specific sections | Detailed technique explanations, configs |

---

## Curated Session Archive

> This section contains distilled outcomes from completed engagements.
> For raw session logs, see `memory/YYYY-MM-DD.md` files.

### 2026-05-02 — AD Enumeration & Attacks Part II (COMPLETE)
**Outcome:** All 12 questions answered. Domain fully compromised.
**Playbook created:** `htb/playbooks/ad-enumeration-attacks.md`
**Key chain:** Responder → hashcat → DomainPasswordSpray → smbmap → web.config → MSSQL → PrintSpoofer → SYSTEM → Mimikatz → PtH (evil-winRM) → BloodHound → Inveigh → hashcat → GenericAll abuse → DCSync
**Critical learnings captured in playbook:**
1. smbmap > crackmapec for share discovery
2. PtH works differently across protocols (SMB≠WinRM≠RDP)
3. SQL service accounts → SYSTEM via SeImpersonatePrivilege + PrintSpoofer
4. Inveigh in evil-winRM needs `-RunTime` or `Start-Job`
5. bloodhound-python needs `LM:NT` format (`aad3b435b51404eeaad3b435b51404ee:HASH`)
6. Group membership changes require fresh Kerberos auth

### 2026-04-18 — Password Attacks Module
**Outcome:** Password Attacks cheatsheet compilation created.
**Playbook created:** `htb/playbooks/password-attacks-cheatsheet-compilation.md`
**Key discovery:** Windows Credential Manager lazy loading — `cmdkey /list` forces vault decryption before `sekurlsa::credman` can read it.

### 2026-04-09 — HTB Box: Administrator (Retired)
**Outcome:** Box completed via GenericAll abuse chain.
**Chain:** Olivia (GenericAll on Michael) → reset Michael's password → WinRM as Michael → ForceChangePassword on Benjamin → rpcclient `setuserinfo2` → FTP as Benjamin → `Backup.psafe3` → hashcat mode 5200 → `tekieromucho` → Emily's credentials → WinRM as Emily → GenericWrite on Ethan → set fake SPN → Kerberoast

### 2026-04-02 — HTB Box: Cicada
**Outcome:** Credentials chain discovered. Box progressed but not completed in this session.
**Notes:** See `memory/2026-04-02.md` for full details if resumed.

### 2026-04-13 — Information Gathering Skills Assessment
**Outcome:** Email address hunt via vHost brute force + robots.txt + crawling.
**Notes:** See `memory/2026-04-13.md` for methodology if resumed.

---

## Active Boxes / Assessments

| Box/Assessment | Status | Location | Key Creds | Notes |
|----------------|--------|----------|-----------|-------|
| AD Enum & Attacks Part II | ✅ Complete | `htb/academy/ad-enumeration-attacks/part2/` | See playbook | Domain compromised |

---

*MEMORY.md cleaned: 2026-05-03*
*Previous raw logs moved to `memory/YYYY-MM-DD.md` — search via `memory_search` for details*

## Promoted From Short-Term Memory (2026-05-10)

<!-- openclaw-memory-promotion:memory:memory/2026-03-23.md:26:42 -->
- **htb_document_progress v2.1.1:** Fixed path resolution bug. Now uses `realpath` to output absolute BOX_DIR paths. Subagent MUST use absolute paths provided by document.sh to avoid "file not found" errors in different execution contexts. ### HTB Box: Precious - IN PROGRESS - IP: 10.129.228.98 - Services: SSH (22), HTTP/nginx (80) + Phusion Passenger + Ruby - Web App: PDF conversion service from URL input - Attack Surface: SSRF, command injection, file read via PDF generation ### Key Techniques - Time-based blind SQLi: requires TIME tuning (used 3s for stable extraction) - PATH hijacking: identify privileged processes using unqualified commands - PAM exploitation: MOTD scripts run as root on SSH login - Process monitoring: `pspy` reveals execution patterns --- [score=0.864 recalls=7 avg=0.479 source=memory/2026-03-23.md:26-42]
<!-- openclaw-memory-promotion:memory:memory/2026-03-17.md:1:38 -->
- # Session Log — 2026-03-17 ## OpenClaw Skills Discovery — Key Finding ### Issue `openclaw skills` CLI only discovers skills from the **default agent's workspace** (Ceil at `~/.openclaw/workspace`), not from other agent workspaces (Neo at `~/.openclaw/workspace-neo`). ### Behavior | Context | Skills Shown | |---------|-------------| | `openclaw skills` CLI | Default agent workspace + managed + bundled only | | Gateway / Agent system prompt | Per-agent workspace skills ARE loaded correctly | | Telegram slash commands | All skills registered (including per-agent workspace) | ### Precedence (works correctly in gateway) 1. `<workspace>/skills/` (highest) — per-agent 2. `~/.openclaw/skills/` (managed/local) — shared 3. Bundled skills (lowest) ### CLI Limitation - `openclaw skills` has **no `--agent` or `--workspace` flag** - Always resolves to `agents.defaults.workspace` in config - Multi-agent setups require awareness: CLI ≠ full skill visibility ### Symlink Warning (resolved) - Warning: "Skipping skill path that resolves outside its configured root" - Cause: Symlink in default workspace pointing outside its root - Fix: Removed `~/.openclaw/workspace/skills/research-delegate` symlink; use managed skills instead ### Workspace Skills Path Correction - **Wrong (in TOOLS.md):** `.openclaw/skills/` - **Correct:** `<workspace>/skills/` (at workspace root) - Updated TOOLS.md and notified Ceil --- ## htb-new-box Skill Test [score=0.863 recalls=6 avg=0.450 source=memory/2026-03-17.md:1-38]
