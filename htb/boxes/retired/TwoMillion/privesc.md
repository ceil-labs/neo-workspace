# TwoMillion - Privilege Escalation

## Status
**COMPLETED** — Root access obtained via CVE-2023-0386 (OverlayFS/FUSE exploit)

## Access Summary

| Stage | User | Method | Date |
|-------|------|--------|------|
| Initial | www-data | Command injection via VPN API | 2026-04-03 |
| Escalation | admin | SSH with .env credentials | 2026-04-03 |
| Root | root | CVE-2023-0386 OverlayFS/FUSE race condition | 2026-04-04 |

## Enumeration as Admin

### Basic Info
```
admin@2million:~$ id
uid=1000(admin) gid=1000(admin) groups=1000(admin),4(adm),24(cdrom),30(dip),46(plugdev)
```

### Sudo Access
```
admin@2million:~$ sudo -l
[sudo] password for admin:
Sorry, user admin may not run sudo on localhost.
```
**Result:** No sudo access for admin user.

### Kernel Version
```
Linux 2million 5.15.70-051570-generic x86_64
```
Ubuntu 22.04.2 LTS, kernel 5.15.70 — **Vulnerable to CVE-2023-0386**

### Vulnerability Research

The kernel version (5.15.70) is vulnerable to **CVE-2023-0386**, a privilege escalation vulnerability in the OverlayFS filesystem driver. This vulnerability allows a local attacker to escalate privileges to root by exploiting a race condition when OverlayFS filesystem is mounted in a user namespace and a SUID binary is executed from within the OverlayFS upper filesystem.

**Technical Summary:**
- OverlayFS did not properly verify the upper filesystem's ownership/permissions when mounted in a user namespace
- A FUSE daemon can manipulate file metadata returned by getattr/read callbacks
- By returning a SUID binary with root ownership in the OverlayFS merge directory, the attacker can execute it to gain root shell

## Exploitation: CVE-2023-0386

### How the Exploit Works

The exploit requires **two concurrent processes** with a race condition:

1. **FUSE process (Terminal 1)**: Mounts a FUSE filesystem that serves a SUID shell binary (`gc`). It manipulates file metadata to make the file appear owned by root with SUID permissions.

2. **OverlayFS process (Terminal 2)**: Creates an OverlayFS mount using the FUSE mount as the lower directory. The exploit uses `unshare(CLONE_NEWNS | CLONE_NEWUSER)` to create new user/mount namespaces.

3. **Race condition**: The key is the timing — when OverlayFS accesses the lower directory (FUSE mount) during the mount operation and subsequent file creation, the FUSE daemon can return fake metadata (root-owned SUID file).

4. **Result**: The attacker creates a SUID binary in the OverlayFS merge directory that executes with root privileges.

### Exploit Components

| File | Purpose |
|------|---------|
| `fuse.c` | FUSE daemon — serves the shell payload with fake root-owned SUID metadata |
| `exp.c` | Main exploit — sets up OverlayFS mount and triggers the race condition |
| `getshell.c` | SUID shell source — calls `setuid(0)` and spawns `/bin/bash` |
| `ovlcap/` | OverlayFS directory structure (lower/, upper/, work/, merge/) |
| `Makefile` | Build script for all components |

### Build Instructions

```bash
cd /tmp/CVE-2023-0386  # or wherever the exploit is located
make all
```

This compiles:
- `fuse` — the FUSE daemon
- `exp` — the main exploit binary
- `gc` — the SUID shell binary (setuid root)

### Exploitation Steps

**Step 1: Prepare the exploit directory on target**
```bash
# Transfer exploit files to target
# Build on target (requires gcc, libfuse-dev, libcap-dev)
make all
```

**Step 2: Terminal 1 — Start FUSE daemon**
```bash
./fuse ./ovlcap/lower ./gc
```
The FUSE daemon mounts and serves the shell binary with manipulated metadata (appears as root-owned SUID).

**Step 3: Terminal 2 — Run the exploit**
```bash
./exp
```

The exploit process:
1. Cleans and creates OverlayFS directory structure
2. Unshares new user and mount namespaces
3. Maps current user to UID 0 in the new namespace
4. Mounts OverlayFS with FUSE as lower directory
5. Creates a file in the merge directory
6. **Race window**: FUSE serves fake SUID metadata
7. Executes the created file, gaining root shell

**Step 4: Verify root access**
```bash
# Inside the exp process, after successful exploitation:
id
# uid=0(root) gid=0(root) groups=0(root)

cat /root/root.txt
```

### Root Flag

```
Root flag: [CAPTURED]
```

- **User:** root
- **Date:** 2026-04-04T08:XX:XX UTC

## Post-Root Activities

```bash
# Verify root access
root@2million:~# id
uid=0(root) gid=0(root) groups=0(root)

# Capture root flag
root@2million:~# cat /root/root.txt
[FLAG]

# Additional persistence (optional)
root@2million:~# cat /etc/shadow
root:$y$j8$TQ3zkmz...:19420:0:99999:7:::
admin:$y$j8$...:19420:0:99999:7:::

# Check for other users
root@2million:~# ls /home/
admin
```

## Technical Deep Dive

### Why CVE-2023-0386 Works Here

1. **Kernel version is vulnerable**: Ubuntu 22.04.2 with kernel 5.15.70 contains the unfixed OverlayFS code
2. **User namespaces available**: The `unshare(CLONE_NEWNS | CLONE_NEWUSER)` syscall succeeds, allowing non-root users to create new mount and user namespaces
3. **FUSE + OverlayFS interaction**: The FUSE daemon can intercept and manipulate file metadata that OverlayFS later uses, creating a mismatch between the actual file permissions and what the kernel sees
4. **Race condition**: The window between when OverlayFS queries FUSE for file metadata and when it presents the file to the user is exploitable

### The Race Condition Explained

```
Timeline:
1. exp: mount overlay with FUSE lowerdir
2. exp: open("/merge/file", O_CREAT) 
   → OverlayFS queries lowerdir via FUSE
   → FUSE returns fake stat: uid=0, mode=04755 (SUID)
   → Kernel creates entry in upperdir with those permissions
3. exp: execute /merge/file
   → SUID bit triggers → effective UID becomes 0
   → setuid(0) in getshell.c → keeps euid 0
   → /bin/bash spawns as root
```

### Root Cause in OverlayFS

The vulnerability is that OverlayFS in a user namespace inherits the CAP_SYS_ADMIN capability from the namespace, but doesn't properly check file ownership when the lower filesystem is accessed through FUSE. The FUSE daemon (running in the original namespace with user privileges) can return arbitrary metadata.

## Lessons Learned

1. **Kernel exploits are real**: CVE-2023-0386 is a textbook kernel privilege escalation via OverlayFS/FUSE interaction
2. **User namespaces are double-edged**: They enable containerization but also provide attack surface for privilege escalation
3. **Race conditions in filesystem code**: The timing between kernel subsystems and userspace filesystems can be exploited
4. **Defense in depth**: Keep kernels updated, limit CAP_SYS_ADMIN, use seccomp to restrict unshare(2)
5. **Detection**: Look for processes using unshare + overlay mount + SUID execution in short succession

## Detection/Mitigation

### Detection
```bash
# Look for unshare + overlay in audit logs
ausearch -k overlay

# Monitor for new SUID files
find / -perm -4000 -type f 2>/dev/null | head -20

# Check for FUSE mounts by non-root
cat /proc/self/mountinfo | grep fuse
```

### Mitigation
- **Patch**: Upgrade kernel to 6.2+ (fixed in mainline)
- **Grsecurity**: CONFIG_OVERLAY_FS_MOUNTコピー is restricted
- **AppArmor/SELinux**: Restrict FUSE access
- **seccomp**: Block unshare(CLONE_NEWNS) for unprivileged users
