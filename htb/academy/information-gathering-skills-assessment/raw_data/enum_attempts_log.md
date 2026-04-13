# Enumeration Attempts Log
## HTB Academy — Information Gathering Skills Assessment

**Target:** `inlanefreight.htb` / `web1337.inlanefreight.htb`
**Current IP:Port:** `154.57.164.77:32404`
**Document created:** 2026-04-13
**Chronological order — oldest to newest**

---

## 1. WHOIS Analysis — `inlanefreight.com`

**Command:**
```bash
whois inlanefreight.com
```

**Result:**
- Registrar: Amazon Registrar, Inc.
- Creation Date: 2019-08-05
- Expiry: 2026-08-05
- Nameservers: AWS Route53 (NS-161, NS-671, NS-1580, NS-1303)
- Registrant: **Identity Protection Service (GB)** — privacy protected
- Tech contact: **Identity Protection Service (GB)** — privacy protected
- Full output: `raw_data/whois_inlanefreight_com.txt`

**Outcome:** No email found. Registrant info redacted by privacy service.

---

## 2. Initial Nmap Scan — Port Discovery

**Commands:**
```bash
nmap -sC -sV -oA nmap/initial 154.57.164.68 -p 32653
nmap -p- -oA nmap/full 154.57.164.68
```

**Result:** Confirmed nginx server, port 32653 open on that IP at the time. (Target has restarted multiple times with IP/port changes.)

**Outcome:** nginx identified.

---

## 3. Gobuster — Directory Enumeration on Main Domain (Port 31232)

**Command:**
```bash
gobuster dir -u http://inlanefreight.htb:31232/ \
  -w /usr/share/wordlists/seclists/Discovery/Web-Content/common.txt
```

**Result:**
```
index.html           (Status: 200) [Size: 120]
```

**Outcome:** Only `index.html` found. No other paths. Main site is essentially empty.

---

## 4. Gobuster — vHost Enumeration on Main Domain (Port 32653)

**Command:**
```bash
gobuster vhost -u http://inlanefreight.htb:32653 \
  -w /usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt \
  --append-domain
```

**Result:**
```
web1337.inlanefreight.htb:32653 Status: 200 [Size: 104]
```

All other subdomains returned Status: 400. The key differentiator was **content length**: `web1337` returned 104 bytes while all others returned 157 bytes.

**Outcome:** `web1337.inlanefreight.htb` discovered. Added to `/etc/hosts`.

Full output: `raw_data/gobuster_vhosts`

---

## 5. Gobuster — Directory Enumeration on `web1337` (Port 32653)

**Command:**
```bash
gobuster dir -u http://web1337.inlanefreight.htb:32653/ \
  -w /usr/share/wordlists/seclists/Discovery/Web-Content/common.txt
```

**Result:**
```
index.html           (Status: 200) [Size: 104]
robots.txt           (Status: 200) [Size: 99]
```

**Outcome:** Found `robots.txt`. Full output: `raw_data/gobuster_web1337.txt`

---

## 6. robots.txt Analysis — `web1337`

**Command:**
```bash
curl http://web1337.inlanefreight.htb:32653/robots.txt
```

**Result:**
```
Allow: /index.html
Allow: /index-2.html
Allow: /index-3.html
Disallow: /admin_h1dd3n
```

**Outcome:** Exposed hidden path `/admin_h1dd3n/` and alternate index pages.

---

## 7. Gobuster — Directory Enumeration on `/admin_h1dd3n/` (Port 31936)

**Command:**
```bash
gobuster dir -u http://web1337.inlanefreight.htb:31936/admin_h1dd3n/ \
  -w /usr/share/wordlists/seclists/Discovery/Web-Content/common.txt
```

**Result:**
```
index.html           (Status: 200) [Size: 255]
```

**Outcome:** Only `index.html` found. No additional files or subdirectories.

---

## 8. Fetching `index-2.html` and `index-3.html` — Both Return 404

**Commands:**
```bash
curl http://web1337.inlanefreight.htb:32653/index-2.html
curl http://web1337.inlanefreight.htb:32653/index-3.html
```

**Result:** Both returned nginx 404 pages. Despite being listed in `robots.txt`, these pages do not exist.

Saved output: `raw_data/index-2.html`, `raw_data/index-3.html`

**Outcome:** No content. Pages are either removed or were never implemented.

---

## 9. Content Analysis — Main `web1337` Page

**Command:**
```bash
curl http://web1337.inlanefreight.htb:32653/
```

**Result:**
```html
<!DOCTYPE html><html><head><title>web1337</title></head><body><h1>Welcome to web1337</h1></body></html>
```

**Outcome:** Minimal HTML stub. No email, no links, no metadata.

---

## 10. Content Analysis — `/admin_h1dd3n/` Page

**Command:**
```bash
curl http://web1337.inlanefreight.htb:32653/admin_h1dd3n/
```

**Result:**
```html
<!DOCTYPE html><html><head><title>web1337 admin</title></head>
<body>
<h1>Welcome to web1337 admin site</h1>
<h2>The admin panel is currently under maintenance,
but the API is still accessible with the key e963d863ee0e82ba7080fbf558ca0d3f</h2>
</body></html>
```

**Outcome:** API key found: `e963d863ee0e82ba7080fbf558ca0d3f`

---

## 11. wget Recursive Mirror

**Command:**
```bash
wget -r -l 2 http://web1337.inlanefreight.htb:32653/
```

**Result:** Only `index.html` downloaded. No additional pages were found to recurse into.

**Outcome:** Minimal site structure confirmed — nothing to recursively crawl.

---

## 12. Gobuster — Large Directory Wordlist on Main Domain (Port 32653)

**Command:**
```bash
gobuster dir -u http://inlanefreight.htb:32653/ \
  -w /usr/share/wordlists/seclists/Discovery/Web-Content/raft-large-directories.txt
```

**Result:** No paths found (all returned 404 or were filtered).

Full output: `raw_data/gobuster_large_dir`

**Outcome:** No additional directories on the main domain.

---

## 13. CEWL — Custom Wordlist + Email Scraping

**Command:**
```bash
cewl http://web1337.inlanefreight.htb:32653/ -m 3
```

**Result:** No words extracted (site has almost no text content).

**Outcome:** No email found. Page content too minimal to generate a useful wordlist or extract any contact info.

---

## 14. theHarvester — OSINT Email Search

**Command:**
```bash
theHarvester -d inlanefreight.htb -b google,bing,virustotal
```

**Result:** No results.

**Outcome:** No email addresses discovered via OSINT.

---

## 15. DNS Reconnaissance

**Commands attempted:**
```bash
dig inlanefreight.htb A
dig inlanefreight.htb MX
dig inlanefreight.htb TXT
dig inlanefreight.htb AXFR inlanefreight.htb
```

**Result:** All queries returned `connection refused` or `timed out`. DNS server not accessible from our position.

Full output: `raw_data/dns_recon.txt` (empty — no useful data)

**Outcome:** No DNS records retrievable. Could not enumerate mail servers, SPF, or perform zone transfer.

---

## 16. HTTP Headers Inspection

**Command:**
```bash
curl -I http://web1337.inlanefreight.htb:32653/
```

**Result:** Standard nginx headers only. No `Server:` surprises. No custom headers containing emails or sensitive data.

**Outcome:** No email or contact info in headers.

---

## 17. HTML Comments Search

**Methods:** Manual page review + Scrapy-based comment extraction

**Result:** No HTML comments found on any page (`<!-- ... -->`).

**Outcome:** No hidden information in comments.

---

## 18. ReconSpider.py — Web Crawl (Scrapy)

**Commands:**
```bash
python3 ReconSpider.py http://web1337.inlanefreight.htb:32653/
# (results saved to raw_data/results_root.json)
python3 ReconSpider.py http://web1337.inlanefreight.htb:32653/admin_h1dd3n/
# (results saved to raw_data/results_admin.json)
```

**Script:** `raw_data/ReconSpider.py`

**Results:**
- `results_root.json`: All fields empty — no emails, no links, no external files, no comments
- `results_admin.json`: All fields empty — no emails, no links, no external files, no comments

**Outcome:** Complete crawl of all accessible pages yielded no emails whatsoever.

---

## 19. Common Path Guessing — Manual Fuzzing

**Paths tested (all returned 404):**
```
/contact
/about
/contact.html
/about.html
/contact.txt
/about.txt
/team
/info
/support
/privacy
/terms
```

**Outcome:** No contact pages or info pages exist.

---

## 20. ffuf — Directory Fuzzing

**Command:**
```bash
ffuf -w /usr/share/wordlists/seclists/Discovery/Web-Content/common.txt \
  -u http://web1337.inlanefreight.htb:32653/FUZZ
```

**Result:** No distinct results found beyond the known `index.html` and `robots.txt`. No new paths surfaced.

Full output: `raw_data/ffuf_port_theory.txt` (mostly theoretical notes)

**Outcome:** Consistent with gobuster findings — no additional paths.

---

## Summary Table

| Technique | Target | Result |
|-----------|--------|--------|
| whois | inlanefreight.com | Privacy protected — no email |
| gobuster dir (common.txt) | Main domain (31232) | index.html only |
| gobuster vhost | Main domain (32653) | **web1337 found** |
| gobuster dir (common.txt) | web1337 | index.html + robots.txt |
| robots.txt analysis | web1337 | Exposed /admin_h1dd3n + index-2/3 |
| gobuster dir | /admin_h1dd3n/ | index.html only |
| Fetch index-2.html | web1337 | 404 |
| Fetch index-3.html | web1337 | 404 |
| wget recursive | web1337 | Only index.html |
| gobuster large dir | Main domain (32653) | No results |
| CEWL | web1337 | No words extracted |
| theHarvester | inlanefreight.htb | No results |
| DNS (A/MX/TXT/AXFR) | inlanefreight.htb | Server unreachable |
| HTTP headers | web1337 | No email |
| HTML comments | web1337 + admin | None found |
| ReconSpider crawl | web1337 + admin | No emails, no links |
| Common path guessing | web1337 | All 404 |
| ffuf fuzzing | web1337 | No new paths |

---

## Confirmed Findings

| Item | Value |
|------|-------|
| HTTP Server | nginx (version unknown, banner hidden) |
| vHost | `web1337.inlanefreight.htb` |
| Hidden path | `/admin_h1dd3n/` |
| API key | `e963d863ee0e82ba7080fbf558ca0d3f` |

## Unresolved

| Item | Status |
|------|--------|
| **Email address** | ❌ NOT FOUND — after exhaustive enumeration |
