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

## Promoted From Short-Term Memory (2026-04-14)

<!-- openclaw-memory-promotion:memory:memory/2026-04-02.md:1:42 -->
- # 2026-04-02 - Daily Log ## HTB: Cicada Box - Current State **Session Ended:** Continuing later ### Target - **IP:** 10.129.231.149 - **Hostname:** cicada.htb - **OS:** Windows Server 2022 (Domain Controller) - **Status:** Enumeration phase, credentials chain discovered ### Credentials Discovered | User | Password | Source | Status | |------|----------|--------|--------| | michael.wrightson | `Cicada$M6Corpb*@Lp#nZp!8` | HR share (default creds) | Valid SMB | | david.orelious | `aRt$Lp#7t*VQ!3` | AD description field | Valid SMB | | emily.oscars | `Q!3@Lp#M6b*7t*Vt` | Backup_script.ps1 | **UNTESTED** | ### Attack Path So Far 1. ✅ Anonymous SMB access to HR share → found default password [score=0.807 recalls=4 avg=0.466 source=memory/2026-04-02.md:1-21]

## Promoted From Short-Term Memory (2026-04-16)

<!-- openclaw-memory-promotion:memory:memory/2026-04-13.md:474:496 -->
- - vHost brute force (110k wordlist) → only found `web1337` - Directory enum (common.txt, raft-small-words.txt, raft-large-directories.txt) on web1337 root → only `index.html`, `robots.txt` - Directory enum on `/admin_h1dd3n/` → only `index.html` - Full page source analysis → both pages are 104-120 byte stubs, no links, no email - HTTP headers → no email - HTML comments → none found - CEWL → no email extracted - theHarvester → no results - DNS (A, MX, TXT, AXFR) → DNS server unreachable from attacking machine - wget recursive mirror → only `index.html` downloaded - Nmap full port scan → only port 32404 open - **Critical observation:** `index-2.html` and `index-3.html` listed in robots.txt return 404 on current instance - ReconSpider results checked — empty (no links found on pages) - Standard email-guessing paths (`/contact`, `/about`, `contact.txt`, etc.) → all 404 ### Key Question for Next Session The HTB Academy Information Gathering Skills Assessment requires an email address found via crawling. The methodology taught includes: whois, robots.txt, subdomain bruteforcing, and crawling. We've completed three of four steps. The email remains elusive. Victor may need to check HTB Academy module hints or try a completely different technique. ### Workspace - Correct workspace: `htb/academy/information-gathering-skills-assessment/` - Assessment file: `assessment.md` - Raw data: `raw_data/` [score=0.838 recalls=8 avg=0.488 source=memory/2026-04-13.md:474-496]
<!-- openclaw-memory-promotion:memory:memory/2026-04-13.md:436:454 -->
- - ## Light Sleep <!-- openclaw:dreaming:light:start --> - Candidate: Session Summary: Scaffolded and progressed through HTB box **Administrator** (10.129.245.95). - confidence: 0.00 - evidence: memory/2026-04-09.md:4-4 - recalls: 0 - status: staged - Candidate: Recon: Target: Windows Server 2022 Domain Controller (hostname: DC, domain: `administrator.htb`); Open ports: 21 (FTP), 53 (DNS), 88 (Kerberos), 135 (RPC), 139 (NetBIOS), 389/3268 (LDAP), 445 (SMB), 593 (RPC over HTTP), 5985 (WinRM); Initial credentials provided: `Olivia` / `ichl - confidence: 0.00 - evidence: memory/2026-04-09.md:9-11 - recalls: 0 - status: staged - Candidate: Enumeration: Ran `bloodhound-python` and lo [confidence=0.62 evidence=memory/2026-04-10.md:1-27] <!-- openclaw:dreaming:rem:end --> ## Information Gathering Assessment — Target Update - **New IP:** `154.57.164.68:32653` (lab restarted) - `/etc/hosts` updated to point `inlanefreight.htb` to new IP - assessment.md and module.md updated with new target - Re-enumeration needed: whois, dnsrecon, directory brute force, crawling ## Information Gathering Assessment — Target Update (2nd Restart) - **New IP:** `154.57.164.79:31936` - `/etc/hosts` updated for both `inlanefreight.htb` and `web1337.inlanefreight.htb` - Known methodology from previous instance: 1. vHost brute force → `web1337.inlanefreight.htb` 2. robots.txt → `Disallow: /admin_h1dd3n` 3. `/admin_h1dd3n/` → API key `e963d863ee0e82ba7080fbf558ca0d3f` 4. Next: directory enumeration under `/admin_h1dd3n/` to find email address [score=0.802 recalls=5 avg=0.564 source=memory/2026-04-13.md:436-454]

## Promoted From Short-Term Memory (2026-04-17)

<!-- openclaw-memory-promotion:memory:memory/2026-04-13.md:68:90 -->
- - Candidate: Email Search — Exhausted Techniques: **Critical observation:** `index-2.html` and `index-3.html` listed in robots.txt return 404 on current instance; ReconSpider results checked — empty (no links found on pages); Standard email-guessing paths (`/contact`, `/about`, `contact.txt`, - confidence: 0.00 - evidence: memory/2026-04-13.md:540-542 - recalls: 0 - status: staged - Candidate: Key Question for Next Session: The HTB Academy Information Gathering Skills Assessment requires an email address found via crawling. The methodology taught includes: whois, robots.txt, subdomain bruteforcing, and crawling. We've completed three of four steps. The email remains el - confidence: 0.00 - evidence: memory/2026-04-13.md:545-545 - recalls: 0 - status: staged - Candidate: Workspace: Correct workspace: `htb/academy/information-gathering-skills-assessment/`; Assessment file: `assessment.md`; Raw data: `raw_data/` - confidence: 0.00 - evidence: memory/2026-04-13.md:548-550 - recalls: 0 - status: staged - Candidate: Session Summary: Scaffolded and progressed through HTB box **Administrator** (10.129.245.95). - confidence: 0.00 - evidence: memory/2026-04-09.md:4-4 - recalls: 0 - status: staged - Candidate: Recon: Target: Windows Server 2022 Domain Controller (hostname: DC, domain: `administrator.htb`); Open ports: 21 (FTP), 53 (DNS), 88 (Kerberos), 135 (RPC), 139 (NetBIOS), 389/3268 (LDAP), 445 (SMB), 593 (RPC over HTTP), 5985 (WinRM); Initial credentials provided: `Olivia` / `ichl - confidence: 0.00 - evidence: memory/2026-04-09.md:9-11 [score=0.816 recalls=9 avg=0.468 source=memory/2026-04-13.md:68-90]
<!-- openclaw-memory-promotion:memory:memory/2026-04-13.md:18:37 -->
- - Candidate: Information Gathering Assessment — Target Update (2nd Restart): **New IP:** `154.57.164.79:31936`; `/etc/hosts` updated for both `inlanefreight.htb` and `web1337.inlanefreight.htb`; Known methodology from previous instance:; vHost brute force → `web1337.inlanefreight.htb` - confidence: 0.00 - evidence: memory/2026-04-13.md:501-504 - recalls: 0 - status: staged - Candidate: Information Gathering Assessment — Target Update (2nd Restart): robots.txt → `Disallow: /admin_h1dd3n`; `/admin_h1dd3n/` → API key `e963d863ee0e82ba7080fbf558ca0d3f`; Next: directory enumeration under `/admin_h1dd3n/` to find email address - confidence: 0.00 - evidence: memory/2026-04-13.md:505-507 [score=0.806 recalls=6 avg=0.550 source=memory/2026-04-13.md:18-25]
