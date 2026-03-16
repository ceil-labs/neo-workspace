# HTB Workspace

Neo + Victor's cybersecurity training ground.

## Quick Start

```bash
# Start a new box
./scripts/new-box.sh <box-name>

# Example:
./scripts/new-box.sh starting-point-legacy
```

## Structure

```
htb/
├── 00-meta/                    # Tracking and reference
│   ├── active-boxes.md         # Currently working on
│   ├── completed-boxes.md      # Finished with notes
│   └── learning-journal.md     # Patterns and lessons across boxes
│
├── academy/                    # HTB Academy modules
│   └── module-name/
│       ├── notes.md            # Module notes and key concepts
│       ├── exercises/          # Lab exercises
│       └── skills-assessment/  # Mini-box for this module
│           ├── recon.md
│           ├── exploit.md
│           ├── privesc.md
│           └── loot/
│
├── boxes/                      # HTB Machines
│   ├── active/                 # Currently active boxes
│   │   └── box-name/
│   │       ├── recon.md        # Enumeration and scanning
│   │       ├── exploit.md      # Initial access
│   │       ├── privesc.md      # Privilege escalation
│   │       └── loot/           # Screenshots, creds, flags
│   │
│   └── retired/                # Completed boxes (reference)
│       ├── easy/
│       ├── medium/
│       ├── hard/
│       └── insane/
│
├── blue-team/                  # Defensive labs
│   ├── forensics/              # Disk/memory analysis
│   ├── soc-analyst/            # Log analysis, threat hunting
│   └── incident-response/      # IR scenarios
│
├── playbooks/                  # Your compiled techniques
│   ├── privesc-linux.md
│   ├── privesc-windows.md
│   ├── web-exploits.md
│   └── forensics-checklist.md
│
└── scripts/                    # Automation helpers
    ├── new-box.sh              # Scaffold new box workspace
    └── utils/
```

## How We Work

### Red Team (Boxes)

| Phase | Victor Does | Neo Does |
|-------|-------------|----------|
| Recon | Run scans, enumerate | Ask "what are you looking for?" |
| Exploit | Try vectors, research | Spawn subagent for deep research if stuck |
| Privesc | Local enumeration | Validate findings, suggest vectors |
| Review | Capture flags | "What was the critical mistake?" |

### Blue Team (Defensive)

| Phase | Victor Does | Neo Does |
|-------|-------------|----------|
| Ingest | Load logs/images | Ask "what patterns do you see?" |
| Hunt | Query logs, find IOCs | Spawn subagent for analysis at scale |
| Timeline | Build incident timeline | Validate reconstruction |
| Report | Document findings | Review for completeness |

## File Templates

Each box/academy module gets consistent templates:

- `recon.md` — Nmap, services, initial observations
- `exploit.md` — Attack vector, exploit used, how it worked
- `privesc.md` — Privilege escalation path
- `loot/` — Screenshots, credentials, flags, artifacts

## Notes Format

Each note file follows this structure:

```markdown
# Box/Module Name

## Target
- IP: x.x.x.x
- OS: Linux/Windows
- Difficulty: Easy/Medium/Hard/Insane

## Recon
[Your enumeration notes]

## Exploitation
[How you got initial access]

## Privilege Escalation
[How you became root/admin]

## Lessons Learned
[What you learned, what to remember]

## References
[Links, tools used, techniques]
```

## Learning Journal

Update `00-meta/learning-journal.md` with patterns you notice:
- Common misconfigurations
- Privesc techniques that show up repeatedly
- Tools that save time
- Mistakes to avoid

This becomes your personal cheat sheet over time.
