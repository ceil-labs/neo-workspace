# Cicada

## Target
- IP: 10.129.231.149
- Hostname: cicada.htb
- OS: Windows (Domain Controller)
- Difficulty: Hard

## Nmap Scan
```
# Full nmap not yet run — SMB enum returned rich results
```

## Services
| Port | Service | Version | Notes |
|------|---------|---------|-------|
| 445  | SMB     | Windows Server SMB | Domain Controller |
| 389  | LDAP    | | Domain enum via lookupsid |
| 53   | DNS     | | cicada.htb |
| 88   | Kerberos| | DC |

## SMB Shares
| Share  | Permissions (anonymous) | Permissions (david.orelious) | Notes |
|--------|------------------------|-------------------------------|-------|
| HR     | READ ONLY              | READ ONLY                     | Contains "Notice from HR.txt" |
| DEV    | READ ONLY              | READ ONLY                     | Contains "Backup_script.ps1" |
| ADMIN$ | NO ACCESS              | NO ACCESS                     | Remote Admin |
| C$     | NO ACCESS              | NO ACCESS                     | Default share |
| NETLOGON| READ ONLY             | READ ONLY                     | Logon server share |
| SYSVOL | READ ONLY              | READ ONLY                     | Logon server share |
| IPC$   | READ ONLY              | READ ONLY                     | Remote IPC |

## Users Enumerated (via lookupsid)
Discovered via `lookupsid.py` on 2026-03-31:
- Administrator
- Guest
- krbtgt
- john.smoulder
- sarah.dantelia
- michael.wrightson
- david.orelious
- emily.oscars

## Initial Observations
- Windows Domain Controller for `cicada.htb`
- HR share exposes default password for all new hires in "Notice from HR.txt"
- DEV share contains a backup script with credentials for emily.oscars embedded in plaintext
- david.orelious has READ access to DEV share (found via smbmap)
- michael.wrightson: default password `Cicada$M6Corpb*@Lp#nZp!8` works for SMB
- david.orelious: password `aRt$Lp#7t*VQ!3` found in AD description field

## Interesting Files
| File | Share | Contents |
|------|-------|----------|
| Notice from HR.txt | HR | Default creds: `Cicada$M6Corpb*@Lp#nZp!8` for all new hires |
| Backup_script.ps1 | DEV | Credential: `emily.oscars` / `Q!3@Lp#M6b*7t*Vt` |

## Next Steps
- [ ] Try emily.oscars credentials on SMB/WinRM
- [ ] Check if emily.oscars has WinRM access
- [ ] Enumerate AD with elevated credentials
- [ ] Look for further privesc paths from emily.oscars
