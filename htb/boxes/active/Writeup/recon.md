# Writeup

## Target
- IP: 10.129.191.3
- OS: Linux (Debian)
- Difficulty: Easy

## Nmap Scan
```
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 9.2p1 Debian 2+deb12u1 (protocol 2.0)
80/tcp open  http    Apache httpd 2.4.25 ((Debian))
| http-robots.txt: 1 disallowed entry 
|_/writeup/
|_http-server-header: Apache httpd 2.4.25 (Debian)
|_http-title: Nothing here yet.
Service Info: OS: Linux
```

## Services
| Port | Service | Version | Notes |
|------|---------|---------|-------|
| 22   | ssh     | OpenSSH 9.2p1 Debian 2+deb12u1 | Protocol 2.0 |
| 80   | http    | Apache httpd 2.4.25 | robots.txt discloses /writeup/ directory |

### SSH Host Keys
- ECDSA: `37:2e:14:68:ae:b9:c2:34:2b:6e:d9:92:bc:bf:bd:28`
- ED25519: `93:ea:a8:40:42:c1:a8:33:85:b3:56:00:62:1c:a0:ab`

## Initial Observations
- **robots.txt** reveals a disallowed entry: `/writeup/` — likely the intended attack path
- **DoS protection**: Page mentions "Eeyore DoS protection script" that watches for Apache 40x errors and bans IPs — enumerating aggressively will get the proxy/IP banned
- Contact email: `jkr@writeup.htb` — potential username for SSH
- Default Apache page title: "Nothing here yet." — site is under construction or index is hidden
- Domain resolved to: `writeup.htb` — add to /etc/hosts if needed

## Interesting Files/Directories
| Path | Source | Notes |
|------|--------|-------|
| /writeup/ | robots.txt | Primary target directory — CMS Made Simple 2.2.9.1 |
| /writeup/admin/ | Enumeration | Behind HTTP basic auth — no credentials yet |
| /robots.txt | Port 80 | Discloses /writeup/ path |

## CMS Made Simple — Target Analysis
**Version: 2.2.9.1** (confirmed from page source meta tag)

```
<meta name="Generator" content="CMS Made Simple - Copyright (C) 2004-2019. All rights reserved." />
```

### Known Vulnerabilities (searchsploit)
| Exploit | EDB-ID | Type |
|---------|--------|------|
| CMS Made Simple < 2.2.10 SQL Injection | 46635.py | Unauthenticated SQLi |
| CMS Made Simple 2.2.14 Auth File Upload | 48779.py | Auth RCE |
| CMS Made Simple 2.2.15 RCE (Authenticated) | 49345.txt | Auth RCE |
| CMS Made Simple 2.2.7 Remote Code Execution | 45793.py | Auth RCE |
| CMS Made Simple 2.2.17 RCE | 51600.txt | RCE |
| CMS Made Simple 2.2.17 session hijacking | 51599.txt | Session hijacking |

> **Key insight**: EDB-ID 46635 is an unauthenticated SQL injection — this was the viable entry point since `/writeup/admin/` requires credentials.

## Next Steps
1. ~~Add `writeup.htb` to /etc/hosts~~ ✅
2. ~~Enumerate `/writeup/` directory — low-and-slow to avoid DoS protection~~ ✅
3. ~~Confirm CMS version and check for unauthenticated vulnerabilities (SQLi EDB 46635)~~ ✅ EXploited
4. ~~Investigate path to credentials for `/writeup/admin/` — try SQLi for admin hash~~ ✅ DONE
5. ~~Check for any exposed credentials or backup files on the server~~ ✅ SSH creds obtained
6. ~~Enumerate SSH users — focus on `jkr` from email~~ ✅ Gained SSH access as jkr
7. **Privilege Escalation** — enumerate for privesc vectors
