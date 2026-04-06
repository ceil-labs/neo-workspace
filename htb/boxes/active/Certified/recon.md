# Certified — Recon

## Target
| Field | Value |
|-------|-------|
| IP | 10.129.231.186 |
| Hostname | DC01.certified.htb |
| OS | Windows (Domain Controller) |
| Domain | certified.htb |

## Nmap Scan
```
sudo nmap -sC -sV -Pn 10.129.231.186
```

**Results:**
| Port | State | Service | Version |
|------|-------|---------|---------|
| 53/tcp | open | domain | Simple DNS Plus |
| 88/tcp | open | kerberos-sec | Microsoft Windows Kerberos |
| 135/tcp | open | msrpc | Microsoft Windows RPC |
| 139/tcp | open | netbios-ssn | Microsoft Windows netbios-ssn |
| 389/tcp | open | ldap | Microsoft Active Directory LDAP |
| 445/tcp | open | microsoft-ds | SMB |
| 464/tcp | open | kpasswd5 | Kerberos password change |
| 593/tcp | open | ncacn_http | RPC over HTTP |
| 636/tcp | open | ssl/ldap | LDAPS |
| 3268/tcp | open | ldap | Global Catalog LDAP |
| 3269/tcp | open | ssl/ldap | Global Catalog LDAPS |
| 5985/tcp | open | http | WinRM (HTTPAPI 2.0) |

**Host scripts:**
- SMB signing enabled and required
- DC01.certified.htb identified as Domain Controller

## Initial Credentials
| Username | Password | Source |
|----------|----------|--------|
| judith.mader | judith09 | Provided |

## Domain Enumeration

### BloodHound (bloodhound-python)
- `bloodhound-python -u judith.mader -p judith09 -d certified.htb -c all -ns 10.129.231.186`
- Found 10 users, 53 groups, 1 computer (DC01), 2 GPOs, 1 OU

### Key Users
- `management_svc` — Service account, member of `Management` and `Remote Management Users`
- `judith.mader` — Regular user account

### Key Groups
- `Management` — Contains management_svc

### BloodHound Attack Path
1. **judith.mader** has **WriteOwner** on `Management` group
2. `Management` group has **GenericWrite** over `management_svc`

### management_svc Object Details
- **DN:** CN=management service,CN=Users,DC=certified,htb
- **sAMAccountName:** management_svc
- **servicePrincipalName:** certified.htb/management_svc.DC01
- **MemberOf:** CN=Management,CN=Users,DC=certified,DC=htb; CN=Remote Management Users,CN=Builtin,DC=certified,DC=htb
- **userAccountControl:** NORMAL_ACCOUNT; DONT_EXPIRE_PASSWORD
- **PasswordLastSet:** 2024-05-13 23:30:51

### Kerberoasting Attempt
- `impacket-GetUserSPNs -dc-ip 10.129.231.186 -request certified.htb/judith.mader:judith09`
- Retrieved TGS hash for management_svc (saved to `raw_data/management_svc.hash`)
- **Kerberoasting failed** — clock skew error; hash cracking with rockyou.txt also unsuccessful

## Observations
- This is a Windows AD Domain Controller — typical of an Active Directory privilege escalation challenge
- judith.mader is a low-privilege user with a specific BloodHound edge enabling the attack chain
- management_svc has WinRM access via membership in `Remote Management Users`
- No direct password-based privesc possible; the path relies on ACL abuse (WriteOwner → GenericWrite → Shadow Credentials)

## Next Steps
- [x] Enumerate domain with BloodHound
- [x] Identify judith.mader → Management → management_svc attack chain
- [x] Exploit WriteOwner + GenericWrite to gain code execution as management_svc
- [ ] Escalate to Domain Admin via ADCS ESC9
