# Skills Assessment — Part II: AD Enumeration & Attacks (Internal)

## Context
> Inlanefreight has contracted us to perform a full-scope **internal penetration test**. The new CISO is worried about nuanced AD security flaws that may have gone unnoticed in previous tests. The client is not concerned about stealth and has provided a **Parrot Linux VM** within the internal network to maximize coverage. Connect via SSH (or xfreerdp) and begin looking for a foothold into the domain. Once you have a foothold, enumerate the domain and look for flaws that can be utilized to move laterally, escalate privileges, and achieve domain compromise.

---

## Objectives

- [ ] Connect to the internal attack host
- [ ] Gain a foothold in the domain
- [ ] Enumerate the AD environment
- [ ] Find and exploit AD misconfigurations
- [ ] Move laterally between hosts
- [ ] Escalate privileges
- [ ] Achieve domain compromise
- [ ] Capture all flags

---

## Questions

| # | Question | Answer | Status |
|---|----------|--------|--------|
| 1 | Obtain a password hash for a domain user account that can be leveraged to gain a foothold in the domain. What is the account name? | `AB920` | ⏳ |
| 2 | What is this user's cleartext password? | `weasal` | ⏳ |
| 3 | Submit the contents of the flag.txt file on MS01. | | ⏳ |
| 4 | Use a common method to obtain weak credentials for another user. Submit the username for the user whose credentials you obtain. | | ⏳ |
| 5 | What is this user's password? | | ⏳ |
| 6 | Locate a configuration file containing an MSSQL connection string. What is the password for the user listed in this file? | | ⏳ |
| 7 | Submit the contents of the flag.txt file on the Administrator Desktop on SQL01. | | ⏳ |
| 8 | Submit the contents of the flag.txt file on the Administrator Desktop on MS01. | | ⏳ |
| 9 | Obtain credentials for a user who has GenericAll rights over the Domain Admins group. What's this user's account name? | | ⏳ |
| 10 | Crack this user's password hash and submit the cleartext password as your answer. | | ⏳ |
| 11 | Submit the contents of the flag.txt file on the Administrator desktop on DC01. | | ⏳ |
| 12 | Submit the NTLM hash for the KRBTGT account for the target domain after achieving domain compromise. | | ⏳ |

---

## Environment

| Component | Details |
|-----------|---------|
| Attack Host | Parrot Linux VM (internal network) |
| Access | SSH or xfreerdp |
| Target Domain | INLANEFREIGHT.LOCAL |
| Known Hosts | MS01, SQL01, DC01 |
| Objective | Domain compromise |

---

## Attack Plan

### Phase 1: Initial Access — Internal Attack Host
- Connect to Parrot VM via SSH
- Enumerate internal network (nmap, ping sweep)
- Identify domain-joinable hosts and open services
- Look for LLMNR/NBT-NSResponder opportunities

### Phase 2: Foothold — Capture Domain User Hash
- Responder / Inveigh for hash capture
- Potential methods: LLMNR/NBT-NS poisoning, mDNS, WPAD
- Crack captured hash or relay

### Phase 3: Enumeration
- BloodHound / SharpHound
- ldapdomaindump / PowerView
- Identify attack paths and misconfigurations

### Phase 4: Credential Access
- Kerberoasting
- AS-REP roasting
- Password spraying / weak credentials
- Configuration file hunting (MSSQL connection strings)

### Phase 5: Privilege Escalation & Lateral Movement
- Abuse ACL misconfigurations (GenericAll, DCSync, etc.)
- Pass-the-Hash / Pass-the-Ticket
- Move to SQL01, MS01

### Phase 6: Domain Compromise
- Target user with GenericAll over Domain Admins
- Full domain admin access
- DCSync / dump NTDS
- Capture KRBTGT hash

---

## Target Map

```
[Parrot VM — Internal Attack Host]
    |
    | LLMNR/NBT-NS / Responder / Enumeration
    v
[AD Environment — INLANEFREIGHT.LOCAL]
    |
    +--→ [MS01] — Flag + lateral pivot
    |
    +--→ [SQL01] — MSSQL + Flag
    |
    +--→ [DC01] — Domain Controller / Final target
```

---

## Credentials Discovered

| Account | Password / Hash | Source | Valid On | Notes |
|---------|-----------------|--------|----------|-------|
| | | | | |

---

## Flags Summary

| Host | Location | Flag | Status |
|------|----------|------|--------|
| MS01 | `flag.txt` (root?) | | ⏳ |
| MS01 | `C:\Users\Administrator\Desktop\flag.txt` | | ⏳ |
| SQL01 | `C:\Users\Administrator\Desktop\flag.txt` | | ⏳ |
| DC01 | `C:\Users\Administrator\Desktop\flag.txt` | | ⏳ |

---

## Key Tools for This Assessment

| Tool | Purpose |
|------|---------|
| Responder | LLMNR/NBT-NS/mDNS poisoning, hash capture |
| hashcat / John | Hash cracking |
| BloodHound / SharpHound | AD enumeration, attack path mapping |
| impacket | DCSync, SMB exec, secretsdump |
| crackmapexec | SMB/WinRM auth testing, spraying |
| ldapdomaindump | LDAP enumeration |
| mimikatz | Credential extraction, PtH, PtT |
| PowerView | AD ACL/permission enumeration |

---

## Raw Data

- Logs and command output: `raw_data/`
- Screenshots: `screenshots/`
- Artifacts: `files/`

---

*Started: 2026-04-27*
*Status: 🔄 IN PROGRESS — Connecting to internal attack host*
