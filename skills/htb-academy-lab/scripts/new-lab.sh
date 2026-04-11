#!/bin/bash
# new-lab.sh - Scaffold a new HTB Academy lab workspace
# Usage: ./new-lab.sh <module-name>

LAB_NAME=$1

if [ -z "$LAB_NAME" ]; then
    echo "Usage: ./new-lab.sh <module-name>"
    echo "Example: ./new-lab.sh active-directory-fundamentals"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Academy workspace root is two levels up from skills/htb-academy-lab/scripts/
ACADEMY_ROOT="$(dirname "$SCRIPT_DIR")/../../htb/academy"

if [ ! -d "$ACADEMY_ROOT" ]; then
    echo "Creating academy workspace at $ACADEMY_ROOT"
    mkdir -p "$ACADEMY_ROOT"
fi

LAB_DIR="$ACADEMY_ROOT/$LAB_NAME"

if [ -d "$LAB_DIR" ]; then
    echo "Lab directory already exists: $LAB_DIR"
    exit 1
fi

mkdir -p "$LAB_DIR/screenshots"
mkdir -p "$LAB_DIR/files"
mkdir -p "$LAB_DIR/raw_data"

# Create module.md
cat > "$LAB_DIR/module.md" << 'EOF'
# Module: <Name>

## Overview
- **Path:** HTB Academy /
- **Topic:** 
- **Skills Assessment:** Yes / No

## Sections
| Section | Status | Notes |
|---------|--------|-------|
|         |        |       |

## Key Concepts

## Tools Introduced

## Gaps / Follow-up
EOF

# Create exercises.md
cat > "$LAB_DIR/exercises.md" << 'EOF'
# Exercises

## Section: <Name>

### Exercise 1
**Question:**  
**Answer:**  
**Explanation:**  

### Exercise 2
**Question:**  
**Answer:**  
**Explanation:**  
EOF

# Create assessment.md
cat > "$LAB_DIR/assessment.md" << 'EOF'
# Skills Assessment

## Target
- IP / URL: 
- OS: 
- Difficulty: 

## Recon
```
# nmap, enumeration, etc.
```

## Exploitation
### Initial Access
```
# commands, payloads
```

### Privilege Escalation
```
# privesc commands
```

## Flags
| Level | Flag |
|-------|------|
| User  |      |
| Root  |      |

## Lessons
EOF

# Create cheatsheet.md
cat > "$LAB_DIR/cheatsheet.md" << 'EOF'
# Cheatsheet: <Module Name>

## Commands
| Command | Purpose |
|---------|---------|
|         |         |

## Payloads / One-liners
EOF

echo "Created academy lab workspace: $LAB_DIR"
echo ""
echo "Files created:"
echo "  - $LAB_DIR/module.md"
echo "  - $LAB_DIR/exercises.md"
echo "  - $LAB_DIR/assessment.md"
echo "  - $LAB_DIR/cheatsheet.md"
echo "  - $LAB_DIR/screenshots/"
echo "  - $LAB_DIR/files/"
echo "  - $LAB_DIR/raw_data/"
