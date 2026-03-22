# Writeup - HTB Box Reconnaissance

## Box Information
- **Name**: Writeup
- **Platform**: HackTheBox
- **IP**: Target acquired (see active session)
- **Difficulty**: Easy/Medium

## Initial Access

### Credentials Obtained
| Field | Value |
|-------|-------|
| Username | `jkr` |
| Password | `raykayjay9` |
| Email | `jkr@writeup.htb` |
| Password Hash (MD5) | `62def4866937f08cc13bab43bb14e6f7` |
| Salt | `5a599ef579066807` |

### SSH Access
```bash
ssh jkr@<TARGET_IP>
# Password: raykayjay9
```

## User Flag
```
539606a7825e5fd092f0e5afa6bd36f2
```

## System Enumeration

### User Context
- **Current User**: `jkr`
- **Groups**: `staff`
- **Hostname**: `srv1405873`

### Kernel Version
- **Target**: Linux 6.1.0-13
- **Attacker (Kali)**: 6.16.8+kali-cloud-amd64

### Network Services
| Service | Address | Port | Notes |
|---------|---------|------|-------|
| MySQL | 127.0.0.1 | 3306 | Bound to localhost only |

### Writable Paths Identified
- `/usr/local/bin`
- `/usr/local/sbin`

### SUID Binaries
- **pkexec** (version 0.105) - Potential PwnKit target

### MySQL Access
- Attempts to login with jkr/raykayjay9 failed - access denied
- Need to find MySQL credentials elsewhere

## Attack Surface

1. **Web Application** - Look for configuration files with MySQL credentials
2. **MySQL Enumeration** - Find proper credentials for database access
3. **SUID Exploitation** - pkexec PwnKit (CVE-2021-4034)
4. **Kernel Exploits** - Consider kernel-based privilege escalation

## Notes
- System appears to be patched against PwnKit exploit
- MySQL credentials not matching user credentials
- Consider enumerating web app files for database credentials
