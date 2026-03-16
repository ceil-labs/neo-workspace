# Windows Privilege Escalation Playbook

Quick reference for common Windows privesc techniques.

## Enumeration

### System Info
```powershell
systeminfo
Get-ComputerInfo
```

### User Context
```powershell
whoami
whoami /priv
whoami /groups
```

### Installed Programs
```powershell
Get-ItemProperty "HKLM:\\Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\*" | select DisplayName
```

### Running Services
```powershell
Get-Service | Where-Object {$_.Status -eq "Running"}
```

### Scheduled Tasks
```powershell
Get-ScheduledTask | Where-Object {$_.State -eq "Ready"}
```

### Unquoted Service Paths
```powershell
wmic service get name,pathname,startmode | findstr /i /v "C:\\Windows\\" | findstr /i /v """
```

## Common Vectors

### Kernel Exploits
- Check OS version and patch level
- Tools: Windows Exploit Suggester, wesng

### Weak Service Permissions
- Services with weak DACLs
- Modifiable service binaries

### Unquoted Service Paths
- Service path: `C:\\Program Files\\App\\service.exe`
- Create: `C:\\Program.exe`

### AlwaysInstallElevated
```powershell
reg query HKCU\\SOFTWARE\\Policies\\Microsoft\\Windows\\Installer /v AlwaysInstallElevated
reg query HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\Installer /v AlwaysInstallElevated
```

### Stored Credentials
```powershell
cmdkey /list
```

### SAM/Security Hives
- If readable: extract hashes
- Tools: secretsdump.py, mimikatz

### Token Impersonation
- SeImpersonatePrivilege → Potato exploits
- SeAssignPrimaryTokenPrivilege → Token manipulation

### Scheduled Tasks
- Writable tasks → execute as SYSTEM

## Tools
- winPEAS
- PowerUp
- Sherlock
- Watson

## References
- [LOLBAS](https://lolbas-project.github.io/)
