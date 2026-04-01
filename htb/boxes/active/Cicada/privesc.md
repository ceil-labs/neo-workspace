# Privilege Escalation

## Enumeration
```
# Pending — emily.oscars credential testing needed
```

## Vector Found
[Pending — emily.oscars access not yet tested]

## Exploitation
[Pending]

## Current Position
- User: david.orelious (domain user, low-privilege)
- Pending: emily.oscars credential testing (from Backup_script.ps1)

## Target
- emily.oscars may have higher privileges (service account associated with backup)
- Need to check: local admin rights, group memberships, WinRM access, SMB access

## Next Steps
1. Test emily.oscars credentials against SMB
2. Test WinRM access: `evil-winrm -i 10.129.231.149 -u emily.oscars -p 'Q!3@Lp#M6b*7t*Vt'`
3. Enumerate group memberships: `net user emily.oscars /domain`
4. Look for privesc from emily.oscars → Domain Admin
5. Kerberoast any service accounts
6. Check for AS-REP roasting

## Lessons
[Pending]
