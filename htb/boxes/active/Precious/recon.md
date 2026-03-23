# Precious — Reconnaissance

**Box:** Precious | **Target:** 10.129.228.98 | **Attacker:** 10.10.14.23
**Difficulty:** Very Easy | **OS:** Linux | **Status:** 🟢 ROOTED

---

## Initial Scan

```bash
sudo nmap -p- -sV -sC -oN raw_data/nmap.initial 10.129.228.98
```

| Port | Service | Version         | Notes                         |
|------|---------|-----------------|-------------------------------|
| 22   | SSH     | OpenSSH 8.4p1   | Requires valid credentials    |
| 80   | HTTP    | Caddy           | Main attack surface (pdfkit)  |

> Port 80 runs a web app that converts URLs to PDFs. This is the entry point.

---

## Service Enumeration

### Port 80 — PDF Conversion Web App

- **Stack:** Ruby on Rails + `pdfkit` gem (v0.8.6) + wkhtmltopdf
- **Behavior:** Accepts a `?url=` query parameter, fetches the URL server-side, renders to PDF
- **Vulnerability:** `pdfkit < 0.8.7` does not sanitize URL parameters before passing to the shell → **CVE-2022-25765 command injection**
- **CVSS:** 10.0 (Critical)

---

## Attack Path Summary

```
[1] CVE-2022-25765 (pdfkit) → RCE as 'ruby' user
[2] Find henry's password in /home/ruby/.bundle/config
[3] SSH as henry → user.txt
[4] sudo /usr/bin/ruby /opt/update_dependencies.rb → YAML RCE → root
```

---

## Credentials

| User   | Password     | Source                    | Usage              |
|--------|-------------|---------------------------|--------------------|
| henry  | *(in bundle config)* | `/home/ruby/.bundle/config` | SSH + sudo         |

---

## Key Files on Target

| Path                              | Purpose                                   |
|-----------------------------------|-------------------------------------------|
| `/home/ruby/.bundle/config`       | henry credentials (readable by ruby)       |
| `/home/henry/user.txt`            | User flag                                 |
| `/opt/update_dependencies.rb`     | Privilege escalation — unsafe YAML.load()  |
| `/opt/update_dependencies.yml`    | YAML config consumed by the above script   |

---

## Ruby Version

**Ruby 2.7.0** — affects which YAML deserialization gadget chains work.
> `Gem::DependencyList` chain (original Staaldraad gist) is patched in 2.7+; use the `Gem::Installer` chain instead.
