# Search Engine Discovery / Google Dorking

> **Source:** HTB Academy — Search Engine Discovery
> OSINT technique using search engines to uncover exposed data, credentials, and hidden content.

## Why It Matters

| Benefit | Description |
|---------|-------------|
| **Open Source** | Publicly accessible — legal and ethical |
| **Breadth** | Search engines index a vast portion of the web |
| **Ease of Use** | No specialized technical skills required |
| **Cost-Free** | Readily available resource |

### Use Cases
- **Security Assessment** — identifying exposed data and attack vectors
- **Competitive Intelligence** — competitor products and strategies
- **Investigative Journalism** — uncovering hidden connections
- **Threat Intelligence** — tracking malicious actors

---

## Search Operators Quick Reference

| Operator | Description | Example |
|----------|-------------|---------|
| `site:` | Limit to a specific domain | `site:example.com` |
| `inurl:` | Term in URL | `inurl:login` |
| `filetype:` | File type | `filetype:pdf` |
| `intitle:` | Term in page title | `intitle:"confidential report"` |
| `intext:` / `inbody:` | Term in body text | `intext:"password reset"` |
| `cache:` | Cached version of page | `cache:example.com` |
| `link:` | Pages linking to a URL | `link:example.com` |
| `related:` | Similar/related websites | `related:example.com` |
| `info:` | Summary about a page | `info:example.com` |
| `define:` | Definition of a word/phrase | `define:phishing` |
| `numrange:` | Numbers within a range | `site:example.com numrange:1000-2000` |
| `allintext:` | All words in body text | `allintext:admin password reset` |
| `allinurl:` | All words in URL | `allinurl:admin panel` |
| `allintitle:` | All words in title | `allintitle:confidential report 2023` |
| `AND` | All terms required | `site:example.com AND inurl:admin` |
| `OR` | Any term matches | `"linux" OR "ubuntu" OR "debian"` |
| `NOT` / `-` | Exclude term | `site:bank.com NOT inurl:login` |
| `*` | Wildcard | `site:socialnetwork.com filetype:pdf user* manual` |
| `..` | Numerical range | `site:ecommerce.com "price" 100..500` |
| `" "` | Exact phrase | `"information security policy"` |

---

## Google Dorking (Google Hacking)

Using search operators to find sensitive information, vulnerabilities, and hidden content.

### Finding Login Pages
```bash
site:example.com inurl:login
site:example.com (inurl:login OR inurl:admin)
```

### Identifying Exposed Files
```bash
site:example.com filetype:pdf
site:example.com (filetype:xls OR filetype:docx OR filetype:xlsx)
```

### Uncovering Configuration Files
```bash
site:example.com inurl:config.php
site:example.com (ext:conf OR ext:cnf OR ext:ini OR ext:env)
```

### Locating Database Backups
```bash
site:example.com inurl:backup
site:example.com filetype:sql
site:example.com filetype:bak
site:example.com inurl:dump
```

### Finding Credentials / Secrets
```bash
site:example.com filetype:xml exim
site:example.com inurl:wp-content/uploads "password"
site:example.com filetype:log "password"
site:example.com "password" filetype:txt
```

### Searching for Exposed API Keys / Tokens
```bash
site:example.com "api_key"
site:example.com "aws_access_key"
site:example.com "sk-live-"  # Stripe keys
```

### Apache/Nginx Config Files
```bash
site:example.com (ext:htaccess OR ext:conf OR inurl:apache.conf)
```

### Database Dumps
```bash
site:example.com filetype:sql.gz
site:example.com filetype:bak "MySQL"
```

### Find Admin Panels
```bash
site:example.com (inurl:admin OR inurl:administrator OR inurl:cp)
```

### Git Repository Exposure
```bash
site:example.com inurl:.git
site:github.com "example.com" password
```

---

## Automation Tools

| Tool | What It Does | Link |
|------|-------------|------|
| **FinalRecon** | SSL/Whois/header analysis, web crawling, modular structure | https://github.com/thewhiteh4t/FinalRecon |
| **Recon-ng** | DNS enum, subdomain discovery, port scanning, web crawling, vulnerability exploitation — full framework | https://github.com/lanmaster53/recon-ng |
| **theHarvester** | Emails, subdomains, hosts, employee names, open ports, banners from search engines/PGP/SHODAN | https://github.com/laramies/theHarvester |
| **SpiderFoot** | OSINT automation — DNS, web crawl, port scan, integrates multiple data sources | https://github.com/smicallef/spiderfoot |
| **OSINT Framework** | Curated collection of OSINT tools organized by source/target type | https://osintframework.com/ |

### Quick Install

```bash
# FinalRecon
git clone https://github.com/thewhiteh4t/FinalRecon.git
cd FinalRecon
pip install -r requirements.txt
python3 finalrecon.py --url <target>

# theHarvester
git clone https://github.com/laramies/theHarvester.git
cd theHarvester
pip install -r requirements.txt
python3 theHarvester.py -d <domain> -b all

# Recon-ng (already in Kali)
recon-ng

# SpiderFoot
git clone https://github.com/smicallef/spiderfoot.git
cd spiderfoot
pip install -r requirements.txt
python3 sf.py -s <target>
```

## Reference

- **Google Hacking Database (Exploit-DB):** https://www.exploit-db.com/google-hacking-database
- **OSINT Framework:** https://osintframework.com/
- Operators work similarly across Google, Bing, DuckDuckGo, and Yandex (syntax may vary slightly)
- Not everything is indexed — deliberately hidden or unlinked content won't appear

---

## HTB Footprinting Context

During footprinting assessments, Google Dorking can reveal:
- Exposed `intranet.` / `.internal` subdomains
- Employee names/emails via cached documents
- Old backup files indexed by Google
- Login portals that aren't linked from the main site
- Passwords or credentials in indexed documents

**Example for Inlanefreight HTB lab:**
```bash
site:inlanefreight.htb filetype:pdf
site:inlanefreight.htb inurl:backup
site:dev.inlanefreight.htb inurl:config
```

---

## OSINT Automation Tools

These tools automate search engine discovery, DNS enumeration, web crawling, and intelligence gathering.

| Tool | URL | Description |
|------|-----|-------------|
| **FinalRecon** | https://github.com/thewhiteh4t/FinalRecon | Python reconnaissance tool — SSL certs, Whois, headers, crawling. Modular structure for customisation. |
| **Recon-ng** | https://github.com/lanmaster53/recon-ng | Full Python framework — DNS enum, subdomain discovery, port scanning, web crawling, vulnerability exploitation. |
| **theHarvester** | https://github.com/laramies/theHarvester | Email addresses, subdomains, hosts, employee names, open ports, banners from search engines, PGP key servers, SHODAN. CLI, Python. |
| **SpiderFoot** | https://github.com/smicallef/spiderfoot | OSINT automation — integrates multiple data sources: DNS, web crawling, port scanning, social media, email. |
| **OSINT Framework** | https://osintframework.com/ | Curated collection of OSINT tools and resources covering social media, search engines, public records, and more. |

### Quick Install
```bash
# FinalRecon
git clone https://github.com/thewhiteh4t/FinalRecon.git
cd FinalRecon
pip install -r requirements.txt
python3 finalrecon.py --url https://example.com --full

# theHarvester
pip install theHarvester
theHarvester -d example.com -b google

# Recon-ng
pip install recon-ng
recon-ng

# SpiderFoot
pip install spiderfoot
sf -s "https://example.com"
```
