# Linux Privilege Escalation Playbook

Quick reference for common Linux privesc techniques.

## Enumeration

### System Info
```bash
uname -a
cat /etc/os-release
cat /proc/version
```

### User Context
```bash
whoami
id
groups
```

### Sudo Permissions
```bash
sudo -l
```

### SUID Binaries
```bash
find / -perm -4000 -type f 2>/dev/null
```

### Capabilities
```bash
getcap -r / 2>/dev/null
```

### Cron Jobs
```bash
cat /etc/crontab
ls -la /etc/cron.d/
```

### Writable Paths
```bash
find / -writable -type d 2>/dev/null
```

## Common Vectors

### Kernel Exploits
- Check kernel version against known exploits
- Tools: linux-exploit-suggester, linux-smart-enumeration

### Sudo Abuse
- If `sudo -l` shows allowed commands without password
- Check GTFOBins for escalation via allowed binaries

### SUID/SGID
- Find unusual SUID binaries
- Check GTFOBins for exploitation methods

### Path Hijacking
- If scripts call binaries without full path
- Create malicious binary in writable directory

### Capabilities
- `cap_setuid+ep` on binary = potential privesc
- Check GTFOBins

### Cron Abuse
- Writable scripts called by cron
- PATH hijacking in cron
- Wildcard injection

### Writable Files
- `/etc/passwd` writable → add user
- `/etc/shadow` readable → crack passwords
- Service configs → add malicious service

## Tools
- linPEAS
- linux-exploit-suggester
- pspy (monitor processes)

## References
- [GTFOBins](https://gtfobins.github.io/)
