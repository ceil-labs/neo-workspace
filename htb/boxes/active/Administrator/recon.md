# Administrator

## Target
- **Current IP:** `10.129.213.179` (HTB reset on 2026-04-11)
- **Previous IP:** `10.129.245.95`
- **OS:** Windows Server 2022 (Domain Controller)
- **Hostname:** `DC`
- **Domain:** `administrator.htb`

## Nmap Scan
```
Starting Nmap 7.98 ( https://nmap.org ) at 2026-04-09 16:56 +0800
Nmap scan report for 10.129.245.95
Host is up (0.012s latency).
Not shown: 987 closed tcp ports (reset)
PORT     STATE SERVICE       VERSION
21/tcp   open  ftp           Microsoft ftpd
53/tcp   open  domain        Simple DNS Plus
88/tcp   open  kerberos-sec  Microsoft Windows Kerberos (server time: 2026-04-09 15:57:03Z)
135/tcp  open  msrpc         Microsoft Windows RPC
139/tcp  open  netbios-ssn   Microsoft Windows netbios-ssn
389/tcp  open  ldap          Microsoft Windows Active Directory LDAP (Domain: administrator.htb, Site: Default-First-Site-Name)
445/tcp  open  microsoft-ds?
464/tcp  open  kpasswd5?
593/tcp  open  ncacn_http    Microsoft Windows RPC over HTTP 1.0
636/tcp  open  tcpwrapped
3268/tcp open  ldap          Microsoft Windows Active Directory LDAP (Domain: administrator.htb, Site: Default-First-Site-Name)
3269/tcp open  tcpwrapped
5985/tcp open  http          Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
|_http-server-header: Microsoft-HTTPAPI/2.0
|_http-title: Not Found
Service Info: Host: DC; OS: Windows; CPE: cpe:/o:microsoft:windows

Host script results:
| smb2-security-mode: 
|   3.1.1: 
|_    Message signing enabled and required
|_clock-skew: 7h00m01s
| smb2-time: 
|   date: 2026-04-09T15:57:05
|_  start_date: N/A
```

## Services
| Port | Service | Version | Notes |
|------|---------|---------|-------|
| 21 | ftp | Microsoft ftpd | Anonymous? Try anonymous login |
| 53 | domain | Simple DNS Plus | DNS server |
| 88 | kerberos-sec | Microsoft Windows Kerberos | KDC - Domain: administrator.htb |
| 135 | msrpc | Microsoft Windows RPC | DCE/RPC |
| 139 | netbios-ssn | Microsoft Windows netbios-ssn | SMB over NetBIOS |
| 389 | ldap | Microsoft Windows Active Directory LDAP | Domain: administrator.htb |
| 445 | microsoft-ds | SMB | Signing required |
| 464 | kpasswd5 | Kerberos password change | - |
| 593 | ncacn_http | RPC over HTTP 1.0 | - |
| 636 | tcpwrapped | LDAPS (secure LDAP) | - |
| 3268 | ldap | Global Catalog LDAP | - |
| 3269 | tcpwrapped | Global Catalog LDAPS | - |
| 5985 | http | Microsoft HTTPAPI 2.0 | **WinRM** - potential remoting access |

## Initial Credentials
- Username: **Olivia**
- Password: **ichliebedich**

## BloodHound Findings

### Key AD Attack Path
| Step | From User | Permission | Target | Abuse |
|------|-----------|-----------|--------|-------|
| 1 | Olivia | GenericAll | Michael | Reset Michael's password |
| 2 | Michael | ForceChangePassword | Benjamin | Reset Benjamin's password |
| 3 | Benjamin | FTP / SMB share access | Backup.psafe3 | Retrieve Password Safe database |
| 4 | Emily | GenericWrite | Ethan | Targeted Kerberoasting |

## Users Discovered
| User | Notes |
|------|-------|
| Olivia | Initial access — member of Remote Management Users |
| Michael | In Remote Management Users group |
| Benjamin | In Share Moderators group; has FTP access |
| Emily | Credentials in Backup.psafe3 (Password Safe v3) |
| Ethan | Target for Targeted Kerberoasting |

## Next Steps
- [x] WinRM access with Olivia's credentials
- [x] Enumerated AD with BloodHound
- [x] Checked FTP access (found `Backup.psafe3`)
- [x] Lateral moved Olivia → Michael → Benjamin → Emily
- [x] Targeted Kerberoasting Ethan via Emily's GenericWrite (password: `limpbizkit`)
- [ ] Use Ethan's credentials for further privilege escalation
