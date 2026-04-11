---
name: htb-academy-lab
description: Scaffold a new HTB Academy lab workspace with standardized structure. Creates module.md, exercises.md, assessment.md, cheatsheet.md, screenshots/, and files/ directories. Use when starting a new HTB Academy module or skills assessment.
---

# htb-academy-lab

Scaffolds a standardized HTB Academy lab workspace.

## Usage

From the workspace root:

```bash
openclaw skills run htb-academy-lab <module-name>
```

Or use the script directly:

```bash
./scripts/new-lab.sh <module-name>
```

## What It Creates

```
htb/academy/<module-name>/
├── module.md          # Module overview, concepts, sections, key takeaways
├── exercises.md       # Exercise answers per section with explanations
├── assessment.md      # Skills assessment walkthrough (recon/exploit/privesc/flags)
├── cheatsheet.md      # Reusable commands, tools, syntax from this module
├── screenshots/       # Visual proofs, diagrams, references
├── files/             # Downloaded scripts, wordlists, artifacts
└── raw_data/          # Command logs and raw output
```

## File Templates

### module.md
- Module overview (path, topic, assessment indicator)
- Sections table for tracking progress
- Key concepts learned
- Tools introduced
- Gaps / follow-up questions

### exercises.md
- Section-by-section exercise answers
- Question / Answer / Explanation format

### assessment.md
- Target metadata (IP, OS, difficulty)
- Recon section
- Exploitation section (initial access)
- Privilege escalation section
- Flags table
- Lessons learned

### cheatsheet.md
- Commands table
- Payloads / one-liners

## Workflow Integration

This skill standardizes the Academy workflow:
1. **Module Study** → Document in `module.md`
2. **Exercises** → Log answers in `exercises.md`
3. **Skills Assessment** → Track in `assessment.md`
4. **Cheatsheet** → Capture reusable knowledge in `cheatsheet.md`
5. **Artifacts** → Store screenshots and files in `screenshots/` and `files/`

## Why Structured Notes?

- Consistent review and reference
- Clear progression tracking across sections
- Easy to compare exercises with assessment techniques
- Builds good documentation habits
- Separates conceptual learning from hands-on assessment

---

*Part of the Neo HTB workspace toolkit.*
