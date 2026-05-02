# Skills Assessment — Part II: AD Enumeration & Attacks (Internal)

## Context
> Inlanefreight has contracted us to perform a full-scope **internal penetration test**. The new CISO is worried about nuanced AD security flaws that may have gone unnoticed in previous tests. The client is not concerned about stealth and has provided a **Parrot Linux VM** within the internal network to maximize coverage. Connect via SSH (or xfreerdp) and begin looking for a foothold into the domain. Once you have a foothold, enumerate the domain and look for flaws that can be utilized to move laterally, escalate privileges, and achieve domain compromise.

---

## Objectives

- [x] Connect to the internal attack host
- [x] Gain a foothold in the domain
- [x] Enumerate the AD environment
- [x] Find and exploit AD misconfigurations
- [x] Move laterally between hosts
- [x] Escalate privileges
- [ ] Achieve domain compromise
- [ ] Capture all flags

---

## Questions

| # | Question | Answer | Status |
|---|----------|--------|--------|
| 1 | Obtain a password hash for a domain user account that can be leveraged to gain a foothold in the domain. What is the account name? | `AB920` | ✅ |
| 2 | What is this user's cleartext password? | `weasal` | ✅ |
| 3 | Submit the contents of the flag.txt file on MS01. | `aud1t_gr0up_m3mbersh1ps!` | ✅ |
| 4 | Use a common method to obtain weak credentials for another user. Submit the username for the user whose credentials you obtain. | `BR086` | ✅ |
| 5 | What is this user's password? | `Welcome1` | ✅ |
| 6 | Locate a configuration file containing an MSSQL connection string. What is the password for the user listed in this file? | `D@ta_bAse_adm1n!` | ✅ |
| 7 | Submit the contents of the flag.txt file on the Administrator Desktop on SQL01. | `s3imp3rs0nate_cl@ssic` | ✅ |
| 8 | Submit the contents of the flag.txt file on the Administrator Desktop on MS01. | `exc3ss1ve_adm1n_r1ghts!` | ✅ |
| 9 | Obtain credentials for a user who has GenericAll rights over the Domain Admins group. What's this user's account name? | `CT059` | ✅ |
| 10 | Crack this user's password hash and submit the cleartext password as your answer. | *(Inveigh hash captured — pending crack)* | 🔄 |
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

## Attack Path (Actual)

### Phase 1: Initial Access — Responder Hash Capture
- Connected to Parrot VM via SSH
- Ran `responder -I ens224 -wrfv`
- Captured NTLMv2 hash for domain user `AB920`
- Cracked hash with hashcat (rockyou wordlist) → `weasal`

### Phase 2: Foothold — MS01 as AB920
- Validated creds with crackmapexec SMB on MS01
- RDP'd as `AB920` / `weasal` to MS01
- Read Q3 flag from `C:\flag.txt`

### Phase 3: Credential Access — DomainPasswordSpray
- Discovered no lockout policy via DomainPasswordSpray
- Sprayed `Welcome1` across 2899 domain users
- Hit: `BR086:Welcome1`

### Phase 4: Enumeration — DC01 Shares & Connection String
- **Critical learning:** smbmap reveals shares that crackmapexec suppresses on DC01
- smbmap showed `Department Shares` with subfolders: Accounting, Executives, Finance, HR, IT, Marketing, R&D
- Navigated to `Department Shares/IT/Private/Development/web.config`
- Found MSSQL connection string: `netdb:D@ta_bAse_adm1n!`

### Phase 5: Privilege Escalation — SQL01 → SYSTEM via PrintSpoofer
- Connected to SQL01 as `netdb` (dbo/sysadmin on master)
- Uploaded PrintSpoofer64.exe
- `SeImpersonatePrivilege` enabled on `NT SERVICE\MSSQL$SQLEXPRESS`
- Used PrintSpoofer to escalate to SYSTEM
- Created msfvenom reverse shell, got interactive SYSTEM shell
- Read Q7 flag from `C:\Users\Administrator\Desktop\flag.txt`
- Mimikatz dumped local Administrator hash: `bdaffbfe64f1fc646a3353be1c2c3c99`

### Phase 6: Lateral Movement — MS01 as Administrator (Pass-the-Hash)
- **Critical learning:** crackmapexec SMB hash auth FAILED (`STATUS_LOGON_FAILURE`)
- **Critical learning:** evil-winRM SUCCEEDED with same hash!
- Authenticated as Administrator on MS01 via evil-winRM pass-the-hash
- Read Q8 flag from `C:\Users\Administrator\Desktop\flag.txt`

### Phase 7: BloodHound — Finding GenericAll Path
- bloodhound-python with BR086 creds
- Found `CT059@INLANEFREIGHT.LOCAL` has GenericAll over Domain Admins
- CT059 is massively over-permissioned:
  - GenericAll over: Domain Admins, Enterprise Admins, Schema Admins, Account Operators, Backup Operators, Cert Publishers, DnsAdmins, DnsUpdateProxy, RAS and IAS Servers

### Phase 8: Capturing CT059 Hash — Inveigh
- Inveigh background job on MS01 (evil-winRM PTY issues workaround)
- Inveigh captured CT059 NTLMv2 hash from DC01 auth attempts
- Hash file: `Inveigh_NTLMV2_admin_dump.txt`
- Pending: crack with hashcat (mode 5600)

### Phase 9: Domain Compromise (Pending)
- Crack CT059 password → authenticate as CT059
- Add account to Domain Admins (GenericAll abuse)
- Read Q11 flag on DC01
- DCSync KRBTGT hash (Q12)

---

## Target Map

```
[Parrot VM — Internal Attack Host]
    |
    | Responder → AB920 hash → cracked: weasal
    v
[MS01] — AB920 foothold → flag Q3
    |
    | DomainPasswordSpray → BR086:Welcome1
    v
[DC01] — smbmap reveals "Department Shares"
    |
    | web.config → netdb:D@ta_bAse_adm1n!
    v
[SQL01] — netdb login → PrintSpoofer → SYSTEM
    |
    | Mimikatz → local Administrator hash
    v
[MS01] — evil-winRM PtH → Administrator
    |
    | BloodHound → CT059 has GenericAll over Domain Admins
    v
[DC01] — Inveigh captures CT059 hash (pending crack)
    |
    | Add to Domain Admins → Domain Compromise
    v
[Domain Admin] — DCSync KRBTGT → Q11 + Q12 flags
```

---

## Credentials Discovered

| Account | Password / Hash | Source | Valid On | Notes |
|---------|-----------------|--------|----------|-------|
| `AB920` | `weasal` | Responder hash → hashcat | MS01, SMB | Initial foothold |
| `BR086` | `Welcome1` | DomainPasswordSpray | MS01, SMB | IT-Managers group |
| `netdb` | `D@ta_bAse_adm1n!` | web.config on DC01 | SQL01 (MSSQL) | dbo/sysadmin on master |
| `SQL01\Administrator` | `bdaffbfe64f1fc646a3353be1c2c3c99` | Mimikatz (SYSTEM) | SQL01 (local) | Pass-the-hash to MS01 |
| `CT059` | *(NTLMv2 captured)* | Inveigh on MS01 | Domain | GenericAll over Domain Admins |

---

## Flags Summary

| Host | Location | Flag | Status |
|------|----------|------|--------|
| MS01 | `C:\flag.txt` | `aud1t_gr0up_m3mbersh1ps!` | ✅ Q3 |
| MS01 | `C:\Users\Administrator\Desktop\flag.txt` | `exc3ss1ve_adm1n_r1ghts!` | ✅ Q8 |
| SQL01 | `C:\Users\Administrator\Desktop\flag.txt` | `s3imp3rs0nate_cl@ssic` | ✅ Q7 |
| DC01 | `C:\Users\Administrator\Desktop\flag.txt` | | ⏳ Q11 |

---

## Key Learnings

### 1. smbmap vs crackmapexec
- **smbmap reveals shares that crackmapexec suppresses**
- crackmapexec against DC01 with hostname returned empty; smbmap showed `Department Shares`
- crackmapexec with IP worked, but still missed the share listing initially
- **Always cross-verify with smbmap when shares seem sparse**

### 2. Pass-the-Hash Protocol Differences
- **SMB hash auth ≠ WinRM hash auth**
- crackmapexec SMB: `STATUS_LOGON_FAILURE` with Administrator hash
- evil-winRM: **SUCCEEDED** with identical hash
- **RDP pass-the-hash** can fail with "Account restrictions are preventing this user from signing in" (NTLMv2-only policy)
- **Test multiple protocols when PtH fails**

### 3. SQL Server Privilege Escalation
- `SeImpersonatePrivilege` on SQL service accounts = SYSTEM via PrintSpoofer
- `netdb` was dbo/sysadmin but still running as `NT SERVICE\MSSQL$SQLEXPRESS`
- PrintSpoofer (`-i -c <command>`) reliably escalates from service account to SYSTEM

### 4. Inveigh in evil-winRM
- evil-winRM PTY cannot handle interactive input (Console.KeyAvailable)
- **Use `-RunTime` parameter** or **Start-Job** for background execution
- Inveigh successfully captured CT059 hash from DC01 authentication attempts

### 5. bloodhound-python Hash Syntax
- `--hashes` requires `LMHASH:NTHASH` format with colon
- Empty LM hash: `aad3b435b51404eeaad3b435b51404ee`
- Full syntax: `--hashes 'aad3b435b51404eeaad3b435b51404ee:NTLMHASH'`

### 6. Web.config Connection String Hunting
- Connection strings often in `web.config` files in IIS/development directories
- BR086's IT-Managers group unlocked `Department Shares/IT/Private/Development/`
- Not all users can read all files in AD — group membership matters for file access

---

## Key Tools for This Assessment

| Tool | Purpose | Used For |
|------|---------|----------|
| Responder | LLMNR/NBT-NS/mDNS poisoning, hash capture | Q1 — AB920 hash |
| hashcat / John | Hash cracking | Q2 — cracked AB920, pending CT059 |
| BloodHound / SharpHound | AD enumeration, attack path mapping | Q9 — CT059 GenericAll |
| bloodhound-python | Remote BloodHound data collection | Domain ACL enumeration |
| impacket | DCSync, SMB exec, secretsdump, mssqlclient | SQL01 connection, pending DC01 |
| crackmapexec | SMB/WinRM auth testing, spraying | Creds validation (but not definitive!) |
| mimikatz | Credential extraction, PtH, PtT | SQL01 local admin hash |
| PrintSpoofer | SeImpersonatePrivilege exploitation | SQL01 → SYSTEM |
| Inveigh | LLMNR/NBT-NS/DNS/WPAD poisoning | CT059 hash capture |
| DomainPasswordSpray | Password spraying across AD | Q4/Q5 — BR086:Welcome1 |
| smbmap | SMB share enumeration | DC01 shares discovery |
| evil-winRM | WinRM pass-the-hash shell | MS01 Administrator access |
| msfvenom | Payload generation | Reverse shell for SYSTEM |

---

## Raw Data Files

| File | Description |
|------|-------------|
| `raw_data/nmap_ping_sweep.txt` | Host discovery scan |
| `raw_data/nmap_top20.txt` | Port scan results |
| `raw_data/responder.log` | Responder capture log |
| `raw_data/ab920_hash.txt` | AB920 NTLMv2 hash |
| `raw_data/spray_welcome1_ms01.txt` | DomainPasswordSpray results |
| `raw_data/connection_string_search.txt` | Initial connection string hunt (AB920) |
| `raw_data/cred_file_hunt.txt` | Credential file search on MS01 |
| `raw_data/172.16.7.3-Department Shares_IT_Private_Development_web.config` | Q6 connection string |
| `raw_data/notes.md` | Detailed session notes |
| `raw_data/Inveigh_NTLMV2_admin_dump.txt` | CT059 + AB920 captured hashes |
| `raw_data/Inveight_administrator_dump.txt` | Inveigh full log |
| `raw_data/mimikatz_logon_password_dump_administrator.txt` | Mimikatz sekurlsa output |

---

*Started: 2026-04-27*
*Last Updated: 2026-05-02*
*Status: 🔄 IN PROGRESS — CT059 hash cracked (pending), Domain Compromise next*
