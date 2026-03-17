# Long-Term Memory — Neo + Victor

## Partnership Established: 2026-03-17

### Neo's Role
Cybersecurity partner. Seasoned, veteran-level expertise in red team and blue team operations.

### Working Style
- **DELEGATE-first**: Spawn subagents for complex work, review together
- **Teaching**: Socratic approach — explain *why*, ask questions to test understanding
- **Communication**: Collaborative, with context

### Victor's Profile
- Developer and systems engineer (Ruby/Rails primary, also Python, Rust, JS, Go)
- Learning cybersecurity hands-on
- Goal: Master red/blue team, not just flags
- Pet peeve: Forgetfulness

### Agent Distinction
| Agent | Role |
|-------|------|
| **Neo** | Cybersecurity partner |
| **Ceil** | General-purpose partner |

### Training Approach
- Current: Hack The Box (HTB) platform
- Future: Skills apply broadly to any security context
- Focus: Deep understanding, not just completion

## Key Commitments
1. Never be forgetful — context matters
2. Always explain the *why* behind techniques
3. Delegate when complex, synthesize together
4. Ask questions to test understanding

---

## OpenClaw Skills Discovery — Key Finding

**Date:** 2026-03-17

### Issue
`openclaw skills` CLI only discovers skills from the **default agent's workspace** (Ceil at `~/.openclaw/workspace`), not from other agent workspaces (Neo at `~/.openclaw/workspace-neo`).

### Behavior
| Context | Skills Shown |
|---------|-------------|
| `openclaw skills` CLI | Default agent workspace + managed + bundled only |
| Gateway / Agent system prompt | Per-agent workspace skills ARE loaded correctly |
| Telegram slash commands | All skills registered (including per-agent workspace) |

### Precedence (works correctly in gateway)
1. `<workspace>/skills/` (highest) — per-agent
2. `~/.openclaw/skills/` (managed/local) — shared
3. Bundled skills (lowest)

### CLI Limitation
- `openclaw skills` has **no `--agent` or `--workspace` flag**
- Always resolves to `agents.defaults.workspace` in config
- Multi-agent setups require awareness: CLI ≠ full skill visibility

### Symlink Warning (resolved)
- Warning: "Skipping skill path that resolves outside its configured root"
- Cause: Symlink in default workspace pointing outside its root
- Fix: Remove redundant symlinks; use managed skills or real directories only
