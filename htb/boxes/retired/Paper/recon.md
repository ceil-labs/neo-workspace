# Paper — Reconnaissance Report

## Target
| Field | Value |
|-------|-------|
| IP (VPN) | 10.129.136.31 |
| OS | Linux (CentOS 8) |
| Difficulty | Easy |
| Box Status | ✅ **ROOTED** |
| Completed | 2026-03-22 |

---

## ✅ Box Status — COMPLETE

| Field | Value |
|-------|-------|
| **user.txt** | `f10419a09348ecd49a3545d5b12661f7` |
| **root.txt** | `e50eb2bb38c864627c54b8c0d9f0802f` |
| **SSH** | ✅ `dwight` / `Queenofblad3s!23` |
| **Privilege Escalation** | ✅ CVE-2021-3560 via 50011.sh |

---

## Final Attack Chain

```
WordPress 5.2.3 (office.paper)
    │
    │ CVE-2019-17671
    │ ?static=1&order=asc
    │
    ▼
Private posts leaked
    │ Secret URL: chat.office.paper/register/8qozr226AhkCHZdyY
    ▼
chat.office.paper (RocketChat)
    │ Recyclops bot LFI: sale/../../home/dwight/hubot/.env
    ▼
Credentials: recyclops / Queenofblad3s!23
    │ Password reuse
    ▼
SSH: dwight@10.129.136.31
    │
    ▼
user.txt ✅ f10419a09348ecd49a3545d5b12661f7
    │
    ▼
CVE-2021-3560 (50011.sh)
    │ User "hacker" created (sudo group)
    ▼
su - hacker → sudo -i
    │
    ▼
root.txt ✅ e50eb2bb38c864627c54b8c0d9f0802f
```

---

## CVEs Exploited

| CVE | Description | Stage |
|-----|-------------|-------|
| CVE-2019-17671 | WordPress unauthenticated private post disclosure | Initial Access |
| CVE-2021-3560 | polkit D-Bus race condition (via 50011.sh) | Privilege Escalation |

---

## Credentials

| Username | Password | Service |
|----------|----------|---------|
| `recyclops` | `Queenofblad3s!23` | RocketChat |
| `dwight` | `Queenofblad3s!23` | SSH (password reuse) |
| `hacker` | `password` | Privesc user (created via 50011.sh) |

---

## Summary

Paper is an Easy-rated Linux box that chains two CVEs:

1. **CVE-2019-17671** — Simple `curl` exploit to leak private WordPress posts, revealing a secret chat registration URL
2. **CVE-2021-3560** — polkit race condition to create a sudo-capable user and gain root

No custom exploitation, no buffer overflows — pure known vulnerability exploitation with credential reuse for the initial shell.

---

*Recon document completed: 2026-03-22 — BOX ROOTED*
