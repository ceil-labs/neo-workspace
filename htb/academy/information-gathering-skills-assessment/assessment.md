# Information Gathering — Skills Assessment

## Target Metadata

| Field | Value |
|-------|-------|
| **IP** | `154.57.164.77` |
| **Port** | `32404` |
| **Target OS** | Linux (Ubuntu) |
| **Difficulty** | Academy Assessment |
| **Module** | Information Gathering |
| **Domain** | `inlanefreight.htb` |
| **vHost** | `web1337.inlanefreight.htb` |

> **Note:** Target restarted multiple times during assessment. IPs: `154.57.164.70:31232` → `154.57.164.68:32653` → `154.57.164.79:31936` → `154.57.164.77:32404`.

---

## Reconnaissance

### whois Analysis
```bash
whois inlanefreight.com
```
- **Registrar:** Amazon Registrar, Inc.
- **Creation Date:** 2019-08-05
- **Nameservers:** AWS Route53 (NS-161, NS-671, NS-1580, NS-1303)
- **Registrant:** Identity Protection Service (GB)
- Full output: [raw_data/whois_inlanefreight_com.txt](raw_data/whois_inlanefreight_com.txt)

### Web Enumeration — Main Site
```bash
# Nmap scan (initial)
nmap -sC -sV -oA nmap/initial 154.57.164.68 -p 32653

# Directory enumeration
nmap -p- -oA nmap/full 154.57.164.68

# Directory brute force (common.txt)
gobuster dir -u http://inlanefreight.htb:32653 -w /usr/share/wordlists/dirb/common.txt
```
- **Server:** nginx/1.26.1
- **Main page:** Only `/index.html` (120 bytes)
- **robots.txt:** 404 on main site
- **nikto:** No CGI dirs, no hidden paths — only missing security headers

### Subdomain / vHost Enumeration
- Initial HTTP vHost tests returned 200/120 for **all** subdomains tested → server seemed single-site
- **Larger wordlist revealed the truth:**

```bash
gobuster vhost -u http://inlanefreight.htb:32653 \
  -w /usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt \
  --append-domain
```

**Discovery:**
```
web1337.inlanefreight.htb:32653 Status: 200 [Size: 104]
```

- Added to `/etc/hosts`: `154.57.164.68 web1337.inlanefreight.htb`
- Full gobuster output: [raw_data/gobuster_vhosts](raw_data/gobuster_vhosts)

### web1337 Subdomain Enumeration
```bash
gobuster dir -u http://web1337.inlanefreight.htb:32653/ \
  -w /usr/share/wordlists/seclists/Discovery/Web-Content/common.txt
```

**Findings:**
- `/robots.txt` — **exists**
- Contents revealed:
  - `Allow: /index.html`
  - `Allow: /index-2.html`
  - `Allow: /index-3.html`
  - `Disallow: /admin_h1dd3n`

Full gobuster output: [raw_data/gobuster_web1337.txt](raw_data/gobuster_web1337.txt)

---

## Exploitation

_(N/A — this is an information-gathering assessment)_

---

## Flags / Answers

| Question | Answer | Status |
|----------|--------|--------|
| What http server software is powering the site? | **nginx** | ✅ |
| What is the API key in the hidden admin directory? | `e963d863ee0e82ba7080fbf558ca0d3f` | ✅ |
| What email address was found after crawling? | | ⬜ (next: crawl `web1337.inlanefreight.htb`) |

---

## Current Status

### ✅ Confirmed / Found

| Item | Value | Source |
|------|-------|--------|
| HTTP Server | `nginx` (version hidden) | Nmap + HTTP headers |
| vHost | `web1337.inlanefreight.htb` | gobuster vhost enumeration |
| Hidden path | `/admin_h1dd3n/` | robots.txt on web1337 |
| API key | `e963d863ee0e82ba7080fbf558ca0d3f` | `web1337.inlanefreight.htb/admin_h1dd3n/index.html` |

### ❌ Unresolved

| Item | Status |
|------|--------|
| **Email address** | NOT FOUND — exhaustive enumeration attempted |

### Why the Email Address Remains Elusive

After exhaustive enumeration across multiple vectors, **no email address has been found**. Here's a summary of why:

1. **Minimal page content** — Both `web1337.inlanefreight.htb` (index.html, 104 bytes) and `/admin_h1dd3n/` (index.html, 255 bytes) are bare HTML stubs with no email addresses, no links, no forms, and no contact information.

2. **index-2.html and index-3.html return 404** — Despite being listed in `robots.txt` as `Allow:` entries, both pages return nginx 404. They either never existed or were removed.

3. **No DNS access** — DNS queries (A, MX, TXT records and AXFR zone transfer) against `inlanefreight.htb` all failed with "connection refused" or timeout. No mail servers or TXT records (which sometimes contain email addresses) are accessible.

4. **WHOIS privacy protection** — The domain `inlanefreight.com` uses Identity Protection Service (UK) — all registrant, admin, and tech contacts are redacted.

5. **No external OSINT footprint** — `theHarvester` across Google, Bing, and VirusTotal returned no results.

6. **No crawling surface** — CEWL found no words to extract. ReconSpider crawled all accessible pages and found zero emails, zero links, zero external resources.

7. **Common paths all 404** — `/contact`, `/about`, `/team`, and similar paths do not exist.

**Next steps to consider:** Try deeper subdomain enumeration (beyond `subdomains-top1million-110000.txt`), check if any alternate vHosts exist on other ports, or re-examine HTTP response bodies/headers with different User-Agent strings.

---

## Lessons Learned

1. **vHost brute force needs large wordlists** — `subdomains-top1million-110000.txt` found `web1337` when `5000.txt` and `common.txt` returned nothing.
2. **Not all vHosts change status codes** — the server returned 200 for everything, but **content length** differed (120 vs 104 bytes).
3. **robots.txt might be on a subdomain, not the root** — main site had 404, but `web1337.inlanefreight.htb/robots.txt` existed and exposed the hidden path.
4. **Target restarts happen** — documented IP changes to maintain continuity.
