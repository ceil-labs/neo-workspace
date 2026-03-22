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

## Initial Observations
- **robots.txt** reveals a disallowed entry: `/writeup/` — likely the intended attack path
- **DoS protection**: Page mentions "Eeyore DoS protection script" that watches for Apache 40x errors and bans IPs — enumerating aggressively will get the proxy/IP banned
- Contact email: `jkr@writeup.htb` — potential username for SSH
- Default Apache page title: "Nothing here yet." — site is under construction or index is hidden
- Domain resolved to: `writeup.htb` — add to /etc/hosts if needed

## Interesting Files/Directories
| Path | Source | Notes |
|------|--------|-------|
| /writeup/ | robots.txt | Primary target directory — likely contains the writeup CMS |
| /robots.txt | Port 80 | Discloses /writeup/ path |

## Next Steps
1. Add `writeup.htb` to /etc/hosts
2. Enumerate `/writeup/` directory — low-and-slow to avoid DoS protection
3. Identify the CMS/application running on /writeup/
4. Check for publicly known vulnerabilities
5. Enumerate SSH user `jkr` (from email) or other users
6. Run dirbuster/gobuster on /writeup/ with a wordlist (respecting DoS protection — slow timing)
