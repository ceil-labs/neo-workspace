# TOOLS.md - Environment Cheat Sheet

This file is your quick reference for tools, environment specifics, and setup details unique to this workspace.

## Session Startup Checklist

Every session, after reading SOUL.md and USER.md, check this file for:
- Tool availability and configurations
- Environment-specific notes
- Recent changes to tools or setup

---

## 🔄 Coordination with Ceil

- Honcho workspace is shared (`openclaw`)
- Peer isolation keeps agent memories separate
- Use `sessions_send` to message Ceil directly for coordination:
  ```
  sessions_send(sessionKey="agent:main:main", message="...")
  ```

---

## Environment Notes

### Workspace
- **Location**: `~/.openclaw/workspace-neo`
- **GitHub**: https://github.com/ceil-labs/neo-workspace
- **Peer in Honcho**: `agent-neo`

### Shared Resources
- **User Skills**: `~/.openclaw/skills/` (shared with Ceil)
- **Workspace Skills**: `.openclaw/skills/` (workspace-scoped, committed to repo)
- **Secrets**: `~/.openclaw/secrets.json`

### Workspace Skills

Located at `<workspace>/skills/` — workspace-scoped, highest precedence, committed to repo.

**Note:** This is the skills directory at the workspace root (e.g., `~/.openclaw/workspace-neo/skills/`), NOT `.openclaw/skills/`.

| Skill | Purpose |
|-------|---------|
| `htb-new-box` | 🎯 Scaffold new HTB box workspace (recon.md, exploit.md, privesc.md, loot/) |

### Subagent Defaults
- **Model**: MiniMax (`opencode-go/minimax-m2.5`)
- **Mode**: Run (one-shot) unless persistent needed

---

## File Locations Quick Reference

| File | Purpose |
|------|---------|
| `SOUL.md` | Who I am (loaded every session) — includes former IDENTITY.md content |
| `USER.md` | Who Victor is |
| `AGENTS.md` | Operating rules and procedures (includes memory tools guidance) |
| `TOOLS.md` | This file — environment and tool notes |
| `MEMORY.md` | Long-term curated memory (main session only) |
| `memory/YYYY-MM-DD.md` | Daily logs |

---

## Memory Tools Reference

See `AGENTS.md` for detailed guidance on:
- Built-in SQLite memory (`memory_search`, `memory_get`)
- Honcho cloud memory (`honcho_profile`, `honcho_search`, `honcho_recall`, `honcho_analyze`)

---

_Add environment-specific notes here as needed: HTB boxes, tools, exploits, techniques, etc._
