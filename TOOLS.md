# TOOLS.md - Environment Cheat Sheet

This file is your quick reference for tools, environment specifics, and setup details unique to this workspace.

## Session Startup Checklist

Every session, after reading SOUL.md and USER.md, check this file for:
- Tool availability and configurations
- Environment-specific notes
- Recent changes to tools or setup

---

## 🧠 Honcho Memory Tools

Honcho provides AI-native memory with dialectic reasoning. Use these to recall context about Victor and past conversations.

### Data Retrieval (Fast, No LLM)

| Tool | Use When |
|------|----------|
| `honcho_session` | Get conversation history from current session |
| `honcho_profile` | Get Victor's peer card — important facts about him |
| `honcho_search` | Semantic search over all stored memories |
| `honcho_context` | Broad view of observations about Victor |

### Q&A (LLM-Powered)

| Tool | Use When |
|------|----------|
| `honcho_recall` | Simple factual questions ("What's Victor's timezone?") |
| `honcho_analyze` | Complex synthesis ("Describe Victor's learning style") |

### How It Works
- Conversations auto-persist to Honcho cloud after each turn
- Both user (owner) and agent (main/neo) peers maintained separately
- Memory improves over time as Honcho builds models
- Use tools mid-conversation to retrieve relevant context

### Peer Mapping
- `owner` → Victor (user facts, preferences, HTB progress)
- `agent-neo` → Neo (my personality, learned behaviors, security expertise)
- `agent-main` → Ceil (separate agent memory)

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
- **Skills**: `~/.openclaw/skills/` (shared with Ceil)
- **Secrets**: `~/.openclaw/secrets.json`

### Subagent Defaults
- **Model**: MiniMax (`opencode-go/minimax-m2.5`)
- **Mode**: Run (one-shot) unless persistent needed

---

## File Locations Quick Reference

| File | Purpose |
|------|---------|
| `SOUL.md` | Who I am (loaded every session) — includes former IDENTITY.md content |
| `USER.md` | Who Victor is |
| `AGENTS.md` | Operating rules and procedures |
| `TOOLS.md` | This file — environment and tool notes |
| `MEMORY.md` | Long-term curated memory (main session only) |
| `memory/YYYY-MM-DD.md` | Daily logs |

---

_Add environment-specific notes here as needed: HTB boxes, tools, exploits, techniques, etc._
