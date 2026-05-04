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
