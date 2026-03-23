---
name: htb_finalize_documentation
description: Finalize and archive a completed HTB box. Streamlines documentation, moves box from active to retired, creates publishable writeup. Trigger with "finalize documentation for <box>" or "htb_finalize_documentation --box <name>".
---

# HTB Finalize Documentation

Archives completed HTB boxes with streamlined docs and final writeup.

## When to Use

- Box is **completed** (flags captured in documentation)
- Ready to move from `active/` to `retired/` (or already in retired/)
- Need publishable writeup in `writeups/`

**Note:** The skill checks documentation (recon.md, privesc.md) for "ROOTED" or flag markers instead of requiring physical user.txt/root.txt files.

## Workflow

```
User: finalize documentation for Writeup
    ↓
1. Validate (finalize.sh)
   - Check box exists (active/ or retired/)
   - Verify completion markers in documentation
   - Output READY signal with absolute paths
    ↓
2. Delegate (subagent)
   - Streamline recon.md, exploit.md, privesc.md
   - Remove redundancy, ensure consistency
   - Move: active/Box → retired/Box (if not already moved)
   - Create: writeups/Box.md
    ↓
3. Report completion
```

## Expected Output

- `retired/{box}/` — Streamlined docs
- `writeups/{box}.md` — Final publishable writeup

## File Templates

### writeups/{box}.md Structure

```markdown
# HTB: {Box Name}

**Difficulty:** Easy/Medium/Hard/Insane  
**OS:** Linux/Windows  
**IP:** 10.129.x.x

## Executive Summary

[1-2 paragraph overview of the attack chain]

## Attack Chain

```
Initial Access → Privilege Escalation → Root
```

## Initial Access

[Detailed exploitation steps with commands]

## Privilege Escalation

[Detailed exploitation steps with commands]

## Flags

| Level | Flag |
|-------|------|
| User | `...` |
| Root | `...` |

## Lessons Learned

- [Key insight 1]
- [Key insight 2]

## Full Documentation

See `retired/{box}/` for complete notes:
- `recon.md` — Enumeration details
- `exploit.md` — Attack walkthrough  
- `privesc.md` — Privilege escalation details
```

## Streamlining Guidelines

When optimizing documentation:
1. **Remove redundancy** — Eliminate duplicate information across files
2. **Ensure consistency** — Standardize formatting and terminology
3. **Preserve failed attempts** — Document what didn't work (valuable for learning)
4. **Clear attack flow** — Make the exploitation chain easy to follow
5. **Complete flags** — Both user and root flags must be present

## Move to Retired

The skill moves the entire box directory:
- **FROM**: `htb/boxes/active/{box}/`
- **TO**: `htb/boxes/retired/{box}/`

## Usage Examples

```
finalize documentation for Writeup
htb_finalize_documentation --box Writeup
```

## Dependencies

- Subagent must have file read/write access
- Git tracking recommended (changes are reversible)
