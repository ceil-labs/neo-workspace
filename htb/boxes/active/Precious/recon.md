# Precious

## Target
- IP: 10.129.228.98
- OS: Linux (Debian)
- Difficulty: 

## Nmap Scan
```
# Nmap 7.98 scan initiated Mon Mar 23 12:02:49 2026
Nmap scan report for 10.129.228.98
Host is up (0.011s latency).
Not shown: 998 closed tcp ports (reset)
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 8.4p1 Debian 5+deb11u1 (protocol 2.0)
| ssh-hostkey: 
|   3072 84:5e:13:a8:e3:1e:20:66:1d:23:55:50:f6:30:47:d2 (RSA)
|   256 a2:ef:7b:96:65:ce:41:61:c4:67:ee:4e:96:c7:c8:92 (ECDSA)
|_  256 33:05:3d:cd:7a:b7:98:45:82:39:e7:ae:3c:91:a6:58 (ED25519)
80/tcp open  http    nginx 1.18.0
|_http-server-header: nginx/1.18.0
|_http-title: Did not follow redirect to http://precious.htb/
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

### SSH Host Keys
- RSA: `84:5e:13:a8:e3:1e:20:66:1d:23:55:50:f6:30:47:d2`
- ECDSA: `a2:ef:7b:96:65:ce:41:61:c4:67:ee:4e:96:c7:c8:92`
- ED25519: `33:05:3d:cd:7a:b7:98:45:82:39:e7:ae:3c:91:a6:58`

## Services
| Port | Service | Version | Notes |
|------|---------|---------|-------|
| 22   | ssh     | OpenSSH 8.4p1 Debian 5+deb11u1 | Protocol 2.0 |
| 80   | http    | nginx 1.18.0 | Phusion Passenger 6.0.15, Ruby |

## Initial Observations
- **Web Application**: Simple page for converting web pages to PDF
- **Stack**: nginx + Phusion Passenger + Ruby
- **Form**: Single URL input field that submits to `/`
- **Redirect**: Page redirects to `http://precious.htb/` (requires /etc/hosts entry)

## Interesting Files/Directories
- `/` - PDF conversion form
- `stylesheets/style.css` - CSS styling

## Next Steps
1. Add `precious.htb` to /etc/hosts
2. Test PDF conversion functionality
3. Look for SSRF, command injection, or file read vulnerabilities in URL parameter
4. Check for known vulnerabilities in Phusion Passenger or PDF generation libraries
