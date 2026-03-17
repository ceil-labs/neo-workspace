---
name: htb-new-box
description: Scaffold a new Hack The Box (HTB) box workspace with standardized structure. Creates recon.md, exploit.md, privesc.md, and loot/ directory.
---

# htb-new-box

Scaffolds a standardized HTB box workspace.

## Usage

From your htb/ directory:

```bash
# Run via openclaw skill:
openclaw skills run htb-new-box <box-name>

# Or use the script directly:
./scripts/new-box.sh <box-name>
```

## What It Creates

```
boxes/active/<box-name>/
├── recon.md      # Target info, nmap scans, services, observations
├── exploit.md    # Attack vectors, exploits used, initial access
├── privesc.md    # Privilege escalation enumeration and exploitation
└── loot/         # Downloaded files, credentials, screenshots
```

## File Templates

### recon.md
- Target metadata (IP, OS, difficulty)
- Nmap scan section
- Services table
- Initial observations
- Interesting findings
- Next steps checklist

### exploit.md
- Attack vector documentation
- Exploit commands/code
- Explanation of vulnerability mechanics
- Initial access details
- Lessons learned

### privesc.md
- Enumeration commands
- Privesc vector found
- Exploitation steps
- Root/admin proof
- Lessons learned

## Workflow Integration

This skill standardizes the box workflow:
1. **Recon** → Document in `recon.md`
2. **Exploit** → Log in `exploit.md`
3. **Privesc** → Track in `privesc.md`
4. **Loot** → Store files in `loot/`

## Why Structured Notes?

- Consistent review and reference
- Clear progression tracking
- Easy to share or publish walkthroughs
- Builds good documentation habits

---

*Part of the Neo HTB workspace toolkit.*
