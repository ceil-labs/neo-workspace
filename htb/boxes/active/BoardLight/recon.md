# BoardLight

## Target
- IP: 10.129.231.37
- OS: Linux (Ubuntu)
- Difficulty: Unknown
- Date: 2026-03-26

## Nmap Scan
```
# Nmap 7.98 scan initiated Thu Mar 26 13:32:53 2026
Nmap scan report for 10.129.231.37
Host is up (0.011s latency).
Not shown: 998 closed tcp ports (reset)

PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 8.2p1 Ubuntu 4ubuntu0.11 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    Apache httpd 2.4.41 ((Ubuntu))
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

## Services
| Port | Service | Version | Notes |
|------|---------|---------|-------|
| 22   | ssh     | OpenSSH 8.2p1 Ubuntu 4ubuntu0.11 | Key: RSA 3072, ECDSA, ED25519 |
| 80   | http    | Apache 2.4.41 (Ubuntu) | PHP application |

## DNS Enumeration
- **Zone transfer**: `dig axfr boardlight.htb @10.129.231.37` — connection refused (no DNS service on target)
- **HTTPS**: `curl -k https://boardlight.htb` — connection refused (no HTTPS)

## Web Enumeration (Port 80) — Updated: 2026-03-26 14:30 UTC

### Discovered Endpoints (feroxbuster, dirb common.txt)
| URL | Status | Lines | Notes |
|-----|--------|-------|-------|
| `/` | 200 | 517 | index.php — BoardLight cybersecurity consulting firm |
| `/about.php` | 200 | 280 | Static about page |
| `/contact.php` | 200 | 294 | Contact page with non-functional form |
| `/do.php` | 200 | 294 | **Interesting** — possible form action handler |
| `/admin.php` | 404 | — | |
| `/portfolio.php` | 404 | — | |
| `/info.php` | 404 | — | |
| `/phpinfo.php` | 404 | — | |
| `/xmlrpc.php` | 404 | — | WordPress indicator — 404 (not found) |
| `/css/` | 301 | — | Directory listing |
| `/images/` | 301 | — | Directory listing |
| `/js/` | 301 | — | Directory listing |

### VHost Enumeration
- **boardlight.htb** vhosts (ffuf, subdomains-top1million-5000.txt): **No results found** — all responses filtered to size 15949 (main site)
- **board.htb** vhosts (ffuf, subdomains-top1million-5000.txt): **Found `crm.board.htb`** (Status: 200, Size: 6360)
  - `crm.board.htb` returns a different page (6360 bytes vs 15949 for main site) — **CRM application, needs investigation**

### Website Analysis
- **BoardLight** — Cybersecurity consulting firm website
- **Stack**: Apache 2.4.41, PHP (likely 7.x), custom PHP application (not WordPress despite xmlrpc.php probe)
- **Contact form**: `<form action="">` — no action, likely handled by `/do.php`
- **Framework hints**: Bootstrap 3.4.1, jQuery 3.4.1 — standard PHP site template

## Key Findings — 2026-03-26 14:30 UTC

1. **SSH (22)** — OpenSSH 8.2p1 — valid attack surface for brute force or key-based auth
2. **crm.board.htb** — Discovered via vhost enumeration. Different content from main site. **HIGH PRIORITY** — CRM application could have exploitable vulnerabilities
3. **do.php** — Form handler (294 lines) — investigate what it does
4. **Contact form** — Non-functional (no action attribute) — could be LFI/RFI if `do.php` processes `include()` calls
5. **No HTTPS** — Only port 80 accessible
6. **No DNS service** — Zone transfer not possible

## Next Steps
1. **[HIGH]** Access `crm.board.htb` via proxy — enumerate this CRM application
2. **[HIGH]** Investigate `do.php` — what parameters does it accept?
3. **[MED]** Test contact form submission (POST to `/do.php`)
4. **[MED]** Check `contact.php` and `about.php` for any hidden info
5. **[LOW]** SSH brute force if credentials available
6. **[INFO]** Check for virtual host routing — add `10.129.231.37 board.htb crm.board.htb` to `/etc/hosts`
