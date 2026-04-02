# TOOLS.md - Environment Cheat Sheet

This file is your quick reference for tools, environment specifics, and setup details unique to this workspace.

## Session Startup Checklist

Every session, after reading SOUL.md and USER.md, check this file for:
- Tool availability and configurations
- Environment-specific notes
- Recent changes to tools or setup

---

## 🔄 Coordination with Ceil

To message Ceil, first find their running session, then use `sessions_send`:

**Step 1: Find Ceil's active session**
```
sessions_list(kinds=["agent"], limit=10)
```

Look for:
- Session with `key` containing `"agent:main:"`
- Status: `"running"` (not `"done"`)
- Active channel: usually `telegram:direct:8154042516`

**Step 2: Send message**
```
sessions_send(sessionKey="agent:main:telegram:direct:8154042516", message="...")
```

**⚠️ Known Issue:** `sessions_send` reports `status: "timeout"` even on successful delivery. Ignore the status field — if you need confirmation, ask Ceil to reply.

**Current active session (as of last check):**
- `agent:main:telegram:direct:8154042516` — Victor's direct Telegram chat with Ceil
- `agent:main:main` — webchat session (usually done/inactive)

---

## Environment Notes

### Workspace
- **Location**: `~/.openclaw/workspace-neo`
- **GitHub**: https://github.com/ceil-labs/neo-workspace


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
- **Model**: MiniMax (`opencode-go/minimax-m2.7`)
- **Mode**: Run (one-shot) unless persistent needed

---

## File Locations Quick Reference

| File | Purpose |
|------|---------|
| `SOUL.md` | Who I am (loaded every session) — includes former IDENTITY.md content |
| `USER.md` | Who Victor is |
| `AGENTS.md` | Operating rules and procedures |
| `TOOLS.md` | This file — environment, tools, and configuration |
| `MEMORY.md` | Long-term curated memory (main session only) |
| `memory/YYYY-MM-DD.md` | Daily logs |

---

## Memory Tools Reference

### Built-in SQLite Memory (Local)
| Tool | Purpose | Backend |
|------|---------|---------|
| `memory_search` | Semantic search over MEMORY.md and memory/*.md files | Local SQLite + Gemini embeddings |
| `memory_get` | Read specific file sections with line ranges | Local SQLite |

**Use for:** Session-level technical details, documented decisions, HTB techniques, local file-based memory.

**Session Start Protocol:**
1. Read SOUL.md → USER.md → TOOLS.md → memory/YYYY-MM-DD.md
2. **Memory search first**: Call `memory_search` before answering "what did we..." questions
3. **Research = delegate first**: Spawn subagent → review → decide

**During Session:**
| Situation | Tool | Why |
|-----------|------|-----|
| Need a quick fact from docs | `memory_search` | Fast local lookup |
| Cross-session pattern | `memory_search` + `memory_get` | Find related past HTB work |
| Complex synthesis | `memory_search` then delegate | Deep reasoning over documented decisions |
| Victor asks about past | `memory_search` | Specific conversation history in daily notes |

---

## Tool Profile Configuration

| Profile | Description | Plugin Tools Exposed? |
|---------|-------------|----------------------|
| `"base"` | Essential tools only | ❌ No |
| `"coding"` | Code-focused tools | ❌ No (built-in only) |
| `"full"` | All available tools | ✅ Yes |

**Recommendation:** Use `"full"` when working with plugins (Honcho, custom skills, etc.).

---

_Add environment-specific notes here as needed: HTB boxes, tools, exploits, techniques, etc._
c._
