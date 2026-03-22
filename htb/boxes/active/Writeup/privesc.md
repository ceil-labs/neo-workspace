# Writeup - Privilege Escalation

## Current Status: IN PROGRESS

## Failed Attempts

### PwnKit (CVE-2021-4034)
- **pkexec version**: 0.105
- **Kernel**: 6.1.0-13
- **Result**: Exploit did not work
- **Conclusion**: System appears patched

### MySQL Credentials Attack
- **Service**: MySQL (127.0.0.1:3306)
- **Credentials tried**: jkr/raykayjay9
- **Result**: Access denied

## Active Enumeration Vectors

### 1. MySQL Access (Priority: HIGH)
- [ ] Enumerate web app config files
- [ ] Check `/var/www/html/` for database credentials
- [ ] Look for `wp-config.php`, `.env`, or similar files
- [ ] Check MySQL user tables if accessible

### 2. SUID Binary Exploitation
- [ ] Review full `find / -perm -4000 2>/dev/null` output
- [ ] Check for writable SUID binaries
- [ ] pkexec is candidate but appears patched

### 3. Kernel Exploits
- [ ] Kernel 6.1.0-13 - research applicable exploits
- [ ] Consider overlayfs, io_uring, or similar exploits
- [ ] Verify exploit compatibility before running

### 4. Writable Path Exploitation
- **Writable directories identified**:
  - `/usr/local/bin`
  - `/usr/local/sbin`
- [ ] Look for cron jobs calling scripts in these paths
- [ ] Check for service binaries that could be replaced
- [ ] Enumerate what binaries exist in these paths

### 5. Web Application Enumeration
- [ ] Enumerate `/var/www/html/`
- [ ] Find CMS or application type
- [ ] Search for configuration files with credentials
- [ ] Check for backup files or git repositories

## Privilege Escalation Path Strategy

```
User (jkr)
    │
    ├── MySQL (if credentials found) ─→ UDF exploitation?
    │
    ├── SUID Binaries ─→ Find vulnerable binary
    │
    ├── Writable Paths ─→ Cron job / Service binary replacement
    │
    └── Kernel Exploit ─→ Linux 6.1.0-13
            │
            ▼
        ROOT
```

## Commands Reference

### MySQL Enumeration
```bash
mysql -u root -p  # Try found credentials
mysql -u root -h 127.0.0.1
```

### SUID Enumeration
```bash
find / -perm -4000 2>/dev/null
```

### Kernel Exploits Research
```bash
searchsploit linux 6.1
```

### Writable Path Enumeration
```bash
find /usr/local/bin -type f -ls
ls -la /usr/local/bin /usr/local/sbin
```

## Target Services
| Service | Port | User | Notes |
|---------|------|------|-------|
| SSH | 22 | jkr | Gained access |
| MySQL | 3306 | ? | Bound to localhost, need creds |

## Notes
- System kernel 6.1.0-13 is relatively recent
- PwnKit exploit failed - system is likely patched
- MySQL credentials needed - web app enumeration required
- Consider looking for web-facing vulnerabilities as alternative path
