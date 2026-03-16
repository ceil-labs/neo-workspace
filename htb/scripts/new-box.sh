#!/bin/bash
# new-box.sh - Scaffold a new HTB box workspace

BOX_NAME=$1

if [ -z "$BOX_NAME" ]; then
    echo "Usage: ./new-box.sh <box-name>"
    echo "Example: ./new-box.sh starting-point-legacy"
    exit 1
fi

BOX_DIR="boxes/active/$BOX_NAME"

if [ -d "$BOX_DIR" ]; then
    echo "Box directory already exists: $BOX_DIR"
    exit 1
fi

mkdir -p "$BOX_DIR/loot"

# Create recon.md
cat > "$BOX_DIR/recon.md" << 'EOF'
# Box Name

## Target
- IP: 
- OS: 
- Difficulty: 

## Nmap Scan
```
# Insert nmap output here
```

## Services
| Port | Service | Version | Notes |
|------|---------|---------|-------|
|      |         |         |       |

## Initial Observations

## Interesting Files/Directories

## Next Steps
EOF

# Create exploit.md
cat > "$BOX_DIR/exploit.md" << 'EOF'
# Exploitation

## Attack Vector
[What vulnerability or misconfiguration?]

## Exploit Used
```
# Commands or code used
```

## How It Works
[Explain the vulnerability and why the exploit works]

## Initial Access
- User: 
- Proof: 

## Lessons
[What did you learn from this exploit?]
EOF

# Create privesc.md
cat > "$BOX_DIR/privesc.md" << 'EOF'
# Privilege Escalation

## Enumeration
```
# Commands run to find privesc vectors
```

## Vector Found
[What misconfiguration or vulnerability?]

## Exploitation
```
# Commands or code used
```

## Root/Admin Access
- User: root / administrator
- Proof: 

## Lessons
[What did you learn from this privesc?]
EOF

echo "Created box workspace: $BOX_DIR"
echo ""
echo "Files created:"
echo "  - $BOX_DIR/recon.md"
echo "  - $BOX_DIR/exploit.md"
echo "  - $BOX_DIR/privesc.md"
echo "  - $BOX_DIR/loot/"
