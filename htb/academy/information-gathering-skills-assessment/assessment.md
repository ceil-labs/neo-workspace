# Information Gathering — Skills Assessment

**Target:** `154.57.164.77:30516` | **Domain:** `inlanefreight.htb` | **Module:** HTB Academy — Information Gathering

> Target restarted across 5 IPs during assessment. Final instance: `154.57.164.77:30516`.

---

## Reconnaissance

### 1. Initial Scan
```bash
nmap -sC -sV -p- 154.57.164.77 --top-ports 100
```
- **Server:** nginx/1.26.1
- **Open port:** 30516 (HTTP only)
- Main domain `inlanefreight.htb` returns a bare 120-byte stub

### 2. vHost Enumeration — First Level
```bash
gobuster vhost -u http://154.57.164.77:30516 \
  -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt \
  --append-domain -t 50
```
> ⚠️ Server returns 200 for **all** Host headers — filter by **content length**, not status code.

**Discovery:** `web1337.inlanefreight.htb` (Size: 104 vs baseline 120)

### 3. web1337 — robots.txt
```bash
curl -s -H "Host: web1337.inlanefreight.htb" http://154.57.164.77:30516/robots.txt
```
```
Allow: /index.html
Allow: /index-2.html
Allow: /index-3.html
Disallow: /admin_h1dd3n
```
`index-2.html` and `index-3.html` returned 404 on all instances — likely decoys.

### 4. vHost Enumeration — Second Level (Deep)
```bash
gobuster vhost -u http://web1337.inlanefreight.htb:30516 \
  -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt \
  --append-domain -t 50
```
**Discovery:** `dev.web1337.inlanefreight.htb` (Size: 123 — different from baseline)

### 5. Crawling `dev.web1337.inlanefreight.htb`
Manual probe revealed a linked HTML chain (`index-334.html` → `index-641.html` → ...).

```bash
# ReconSpider (Scrapy-based) via venv
cd raw_data/
source ../../recon-env/bin/activate
python ReconSpider.py "http://dev.web1337.inlanefreight.htb:30516/"
```
- **Pages crawled:** 100
- **Links found:** 100 interlinked `index-XXX.html` pages
- **Email:** `1337testing@inlanefreight.htb`
- **Bonus:** HTML comment revealed second API key

---

## Flags / Answers

| # | Question | Answer |
|---|----------|--------|
| 1 | HTTP server software | **nginx** |
| 2 | API key in hidden admin directory | `e963d863ee0e82ba7080fbf558ca0d3f` |
| 3 | Email address found after crawling | `1337testing@inlanefreight.htb` |
| 4 | Other API key used by devs | `ba988b835be4aa97d068941dc852ff33` |

---

## Key Findings

| Item | Value |
|------|-------|
| HTTP Server | nginx 1.26.1 |
| vHosts | `web1337.inlanefreight.htb`, `dev.web1337.inlanefreight.htb` |
| Hidden path | `/admin_h1dd3n/` |
| API key #1 | `e963d863ee0e82ba7080fbf558ca0d3f` |
| API key #2 | `ba988b835be4aa97d068941dc852ff33` |
| Email | `1337testing@inlanefreight.htb` |

---

## Lessons Learned

1. **Size beats status** — nginx returned 200 for every Host header; content length (`104` vs `123` vs `120`) was the signal, not HTTP code.
2. **Go one level deeper** — `web1337` had no useful content; `dev.web1337` had the gold.
3. **robots.txt on subdomains, not root** — main site had no robots.txt; `web1337`'s version exposed `/admin_h1dd3n`.
4. **Linked chains need crawlers** — 100-page random-walk chain impossible to manually traverse; ReconSpider (Scrapy) handled it cleanly.
5. **Don't skip comments** — the second API key came from an HTML comment, not visible content.
6. **Document IP changes** — lab restarts broke continuity multiple times; keeping a running log prevented confusion.
