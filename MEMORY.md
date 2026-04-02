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
- Skills at: `<workspace>/skills/` (workspace-scoped, highest precedence)
- Session context via: `memory_search` (daily notes, recent sessions)
- Subagent model: MiniMax (opencode-go/minimax-m2.5)

## Local Memory Tools
| Tool | Purpose | Victor Context |
|------|---------|----------------|
| `memory_search` | Semantic + keyword search | HTB techniques, past box notes, decisions |
| `memory_get` | Read specific sections | Detailed technique explanations, configs |
