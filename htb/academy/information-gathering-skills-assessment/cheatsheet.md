# Information Gathering — Cheatsheet

## Active Reconnaissance

```bash
# Nmap quick scan
nmap -sC -sV -oA nmap/initial <target>

# Nmap full port scan
nmap -p- -oA nmap/full <target>

# Nmap UDP scan
nmap -sU --top-ports 100 -oA nmap/udp <target>

# Nmap with default scripts
nmap --script=default -sV <target>
```

## Passive Reconnaissance

```bash
# WHOIS lookup
whois <domain>

# DNS enumeration
dig <domain> ANY
amass enum -passive -d <domain>

# DNSRecon
dnsrecon -d <domain>
```

## Web Recon

```bash
# Nikto web scanner
nikto -h http://<target>

# Gobuster directory busting
gobuster dir -u http://<target> -w /usr/share/wordlists/dirb/common.txt

# WhatWeb
whatweb http://<target>

# SSL/TLS analysis
sslscan <target>
```

## OSINT

```bash
# theHarvester
theHarvester -d <domain> -b all

# Recon-ng
recon-ng

# SpiderFoot
spiderfoot -s <target>
```

## Tools Reference

| Tool | Purpose | Install |
|------|---------|---------|
| `nmap` | Port scanning, service detection | Pre-installed on Kali |
| `nikto` | Web vulnerability scanner | `apt install nikto` |
| `gobuster` | Directory/file enumeration | `apt install gobuster` |
| `theHarvester` | Email/subdomain OSINT | `pip install theHarvester` |
| `recon-ng` | Full recon framework | `pip install recon-ng` |
| `SpiderFoot` | OSINT automation | `pip install spiderfoot` |
