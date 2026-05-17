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

## Promoted From Short-Term Memory (2026-05-17)

<!-- openclaw-memory-promotion:memory:memory/2026-05-09.md:1:40 -->
- # Neo — Daily Memory — 2026-05-09 ## HTB Academy: SQL Injection Fundamentals — Skills Assessment **Status:** Planning phase. Victor stepping out; initial recon + attack plan prepared for execution. **Target:** `https://154.57.164.64:31180/login.php` **Approach:** Black-box SQL injection assessment **Proxy:** Caido (Burp alternative) --- ### Assessment Objectives | Q | Question | Approach | |---|----------|----------| | 1 | Password hash for user `admin` | SQLi data extraction — enumerate tables, dump user creds | | 2 | Root path of web application | SQLi `LOAD_FILE` / error messages / `phpinfo` / RCE discovery | | 3 | RCE + contents of `/flag_XXXXXX.txt` | SQLi → file write shell OR stacked queries / DB-specific RCE | --- ### Plan of Attack **Phase 1 — Recon (5-10 min)** - Capture login request in Caido - Check response headers for stack clues (X-Powered-By, Server) - Fuzz for other endpoints: `/robots.txt`, `/index.php`, `/phpinfo.php`, `/admin.php` - Baseline normal vs error responses **Phase 2 — SQLi Detection (10-15 min)** - Test login form with payloads: - Boolean: `' OR '1'='1` / `' OR 1=1--` - Error: `'` (single quote to trigger syntax error) - Time-based: `' OR SLEEP(5)--` (MySQL), `'; WAITFOR DELAY '0:0:5'--` (MSSQL), `'; SELECT pg_sleep(5)--` (PostgreSQL) - Identify DB type from error messages or timing behavior - Determine injection type: UNION-based, error-based, blind, or stacked queries **Phase 3 — Data Extraction — admin hash (Q1)** - Manual UNION: `' UNION SELECT 1,2,3--` → enumerate columns [score=0.836 recalls=42 avg=0.538 source=memory/2026-05-09.md:1-40]
<!-- openclaw-memory-promotion:memory:memory/2026-04-28.md:1:43 -->
- # 2026-04-28 — Daily Log ## HTB Academy: AD Enumeration Attacks — Part II (Skills Assessment) **Session Start:** ~22:00 (Asia/Manila) **Status:** IN PROGRESS — Q1/Q2 complete, advancing toward Q3-Q12 **Next Session:** Continue from smbclient/MS01 enumeration ### Target Environment - **Attack Host:** Parrot Linux VM at `10.129.83.248` / `172.16.7.240` - **Domain:** INLANEFREIGHT.LOCAL - **Subnet:** 172.16.6.0/23 (internal network via `ens224`) ### Network Map Discovered | Host | IP | Open Ports | Notes | |------|-----|------------|-------| | DC01 | 172.16.7.3 | 53, 135, 139, 445 | SMB signing **required** | | MS01 | 172.16.7.50 | 135, 139, 445, **3389** | SMB signing **not required** | | SQL01 | 172.16.7.60 | 135, 139, 445, **1433** | MSSQL 2019 SQLEXPRESS; SMB signing **not required** | | Parrot VM | 172.16.7.240 | 22, 3389 | Attack host | ### Progress Log #### Recon (Complete) - Nmap ping sweep found 4 live hosts: DC01, MS01, SQL01, Parrot VM - Top-20 port scan identified services - `/etc/hosts` updated with all internal hosts #### Q1: Domain User Hash (Complete) - Ran Responder on `ens224` - Captured NTLMv2-SSP hash for `INLANEFREIGHT\AB920` from DC01 (172.16.7.3) - **Answer: `AB920`** #### Q2: Cleartext Password (Complete) - Cracked hash with hashcat mode 5600 + rockyou.txt - **Answer: `weasal`** #### MS01 Access (In Progress) - Validated creds with `crackmapexec smb MS01 -u AB920 -p weasal` → **valid, but NOT local admin** (no `Pwn3d!`) - WinRM (5985) not open on MS01 - Next step: `smbclient` to enumerate shares, then RDP or wmiexec for shell access [score=0.821 recalls=6 avg=0.499 source=memory/2026-04-28.md:1-43]
<!-- openclaw-memory-promotion:memory:memory/2026-04-03.md:1:49 -->
- # 2026-04-03 - Daily Log ## HTB: TwoMillion Box - In Progress **Session Active:** Continuing later ### Target - **IP:** 10.129.229.66 - **Hostname:** 2million.htb - **OS:** Linux (Ubuntu) - **Status:** Admin shell obtained, root privilege escalation pending ### Attack Progress #### Phase 1: Initial Enumeration - Deobfuscated `inviteapi.min.js` → discovered API endpoints - Generated invite code via `/api/v1/invite/how/to/generate` - Registered user: `testuser1@email.com` / `password` #### Phase 2: Authentication & IDOR - Authenticated and enumerated API routes via `/api/v1` - Discovered admin endpoints: - `/api/v1/admin/auth` - `/api/v1/admin/vpn/generate` - `/api/v1/admin/settings/update` - **Exploited IDOR vulnerability:** ```bash curl -X PUT 'http://2million.htb/api/v1/admin/settings/update' \ -d '{"email": "testuser1@email.com", "is_admin": 1}' ``` - Successfully elevated `testuser1` to admin #### Phase 3: Command Injection → Shell - **Discovered command injection** in VPN generation endpoint - Payload: `'{"username": "$(whoami)"}'` → returned `www-data` in certificate Subject - Obtained reverse shell as `www-data` #### Phase 4: Post-Exploitation - Found `/var/www/html/.env` containing credentials: `admin:SuperDuperPass123` - **Credential reuse → SSH access as admin user** - Captured **user flag:** `e0d52f0fa1c2e8756998955b5bd7158e` ✅ ### Current Position - **User:** admin (local user, not root) - **Shell:** SSH session - **Sudo:** Cannot run sudo - **SUID:** All standard Ubuntu binaries - **Next Phase:** Root privilege escalation [score=0.804 recalls=5 avg=0.473 source=memory/2026-04-03.md:1-49]
