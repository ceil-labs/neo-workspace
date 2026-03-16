# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.

---

## 🧠 Honcho Memory Tools

Honcho provides AI-native memory with dialectic reasoning. Use these tools to recall context about Victor and past conversations.

### Data Retrieval Tools

| Tool | Use When |
|------|----------|
| `honcho_session` | Get conversation history from current session |
| `honcho_profile` | Get Victor's peer card — important facts about him |
| `honcho_search` | Semantic search over all stored memories |
| `honcho_context` | Broad view of observations about Victor |

### Q&A Tools

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
- `agent-neo` → Neo (your personality, learned behaviors, security expertise)
- `agent-main` → Ceil (separate agent memory)

### Coordination with Ceil
- Honcho workspace is shared (`openclaw`)
- Peer isolation keeps agent memories separate
- Use `sessions_send` to message Ceil directly for coordination
