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
