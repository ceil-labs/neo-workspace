# Writeup - Reconnaissance

## Box Info
- **Name**: Writeup
- **Platform**: HackTheBox
- **IP**: 10.129.191.3
- **Difficulty**: Easy

---

## Initial Access Credentials

| Field | Value |
|-------|-------|
| Username | `jkr` |
| Password | `raykayjay9` |
| Email | `jkr@writeup.htb` |
| MD5 Hash | `62def4866937f08cc13bab43bb14e6f7` |
| Salt | `5a599ef579066807` |

### SSH Access
```bash
ssh jkr@10.129.191.3
# Password: raykayjay9
```

---

## User Flag
```
539606a7825e5fd092f0e5afa6bd36f2
```

---

## System Enumeration

### User Context
- **User**: `jkr` | **Groups**: `staff` | **Hostname**: `srv1405873`

### Key Findings
| Item | Value |
|------|-------|
| Writable Path | `/usr/local/bin` (via `staff` group) |
| MySQL | 127.0.0.1:3306 (localhost only) |

### Failed Privesc Vectors
| Method | Reason |
|--------|--------|
| PwnKit (CVE-2021-4034) | System patched |
| MySQL Access | No valid credentials |
| Looney Tunables (CVE-2023-4911) | Exploit didn't trigger |
| OverlayFS (CVE-2023-0386) | Module not loaded |

---

## Attack Surface
1. **Web App** → SQL Injection → Credentials
2. **SSH** → Initial access as jkr
3. **PrivEsc** → PATH hijacking via PAM MOTD
