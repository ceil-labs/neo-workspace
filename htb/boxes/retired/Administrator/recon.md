# Administrator — Recon

## Target
- **IP:** `10.129.213.179` (reset 2026-04-11; was `10.129.245.95`)
- **OS:** Windows Server 2022 — Domain Controller
- **Hostname:** `DC`
- **Domain:** `administrator.htb`

## Nmap Summary
```
21/tcp   open  ftp           Microsoft ftpd
53/tcp   open  domain        Simple DNS Plus
88/tcp   open  kerberos-sec Microsoft Windows Kerberos (KDC)
135/tcp  open  msrpc         Microsoft Windows RPC
139/tcp  open  netbios-ssn  SMB over NetBIOS
389/tcp  open  ldap          Active Directory LDAP
445/tcp  open  microsoft-ds SMB (signing required)
464/tcp  open  kpasswd5      Kerberos password change
593/tcp  open  ncacn_http   RPC over HTTP 1.0
636/tcp  open  tcpwrapped    LDAPS
3268/tcp open  ldap          Global Catalog LDAP
3269/tcp open  tcpwrapped    Global Catalog LDAPS
5985/tcp open  http          Microsoft HTTPAPI 2.0 → **WinRM**
```

**Key:** Port 5985 = WinRM — initial access vector.

## Initial Access
| User | Password | Source |
|------|----------|--------|
| Olivia | `ichliebedich` | Given / found in enumeration |

## AD Users
| User | Notes |
|------|-------|
| Olivia | In `Remote Management Users` → WinRM access |
| Michael | Target: Olivia has **GenericAll** on him |
| Benjamin | Target: Michael has **ForceChangePassword**; in `Share Moderators` → FTP access |
| Emily | Credentials in `Backup.psafe3` (Password Safe v3) |
| Ethan | Target: Emily has **GenericWrite**; has **DCSync** privileges |

## AD Attack Path (BloodHound)
| Step | From | To | Permission | Abuse |
|------|------|----|-----------|-------|
| 1 | Olivia | Michael | GenericAll | Reset password |
| 2 | Michael | Benjamin | ForceChangePassword | Reset password |
| 3 | Benjamin | Backup.psafe3 | FTP share | Crack Password Safe DB |
| 4 | Emily | Ethan | GenericWrite | Targeted Kerberoasting |
| 5 | Ethan | Domain | DCSync (GetChanges + GetChanges-All) | Full domain hash dump |
