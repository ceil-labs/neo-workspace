# Precious — Reconnaissance

**Box:** Precious | **Target:** 10.129.228.98 | **Attacker:** 10.10.14.23  
**Difficulty:** Very Easy | **OS:** Linux | **Status:** 🟢 ROOTED

---

## Port Scan

```bash
sudo nmap -p- -sV -sC -oN raw_data/nmap.initial 10.129.228.98
```

| Port | Service | Version        |
|------|---------|----------------|
| 22   | SSH     | OpenSSH 8.4p1  |
| 80   | HTTP    | Caddy          |

## Service: Port 80 — PDF Conversion App

- **Stack:** Ruby on Rails + `pdfkit` gem (v0.8.6) + wkhtmltopdf
- **Behavior:** Accepts `?url=` parameter → fetches URL → renders to PDF server-side
- **Attack surface:** CVE-2022-25765 command injection in pdfkit < 0.8.7 (CVSS 10.0)

---

## Attack Path

```
[1] CVE-2022-25765 (pdfkit) → RCE as 'ruby' user
[2] Read henry credentials from /home/ruby/.bundle/config
[3] SSH as henry → user.txt
[4] sudo ruby /opt/update_dependencies.rb → YAML deserialization → root
```

## Credentials

| User  | Source                       | Usage           |
|-------|------------------------------|-----------------|
| henry | `/home/ruby/.bundle/config`  | SSH + sudo      |

## Key Files on Target

| Path                                | Purpose                                    |
|-------------------------------------|--------------------------------------------|
| `/home/ruby/.bundle/config`         | henry SSH password                         |
| `/home/henry/user.txt`              | User flag                                  |
| `/opt/update_dependencies.rb`       | Privilege escalation — unsafe YAML.load()  |
| `/opt/update_dependencies.yml`     | YAML config consumed by above script       |
