# TwoMillion - Privilege Escalation

## Status
**Current Position:** Admin user shell obtained via SSH. Root escalation in progress.

## Access Summary

| Stage | User | Method | Date |
|-------|------|--------|------|
| Initial | www-data | Command injection via VPN API | 2026-04-03 |
| Escalation | admin | SSH with .env credentials | 2026-04-03 |
| Target | root | [In progress] | - |

## Enumeration as Admin

### Basic Info
```
admin@2million:~$ id
uid=1000(admin) gid=1000(admin) groups=1000(admin),4(adm),24(cdrom),30(dip),46(plugdev)
```

### Sudo Access
```
admin@2million:~$ sudo -l
[sudo] password for admin:
Sorry, user admin may not run sudo on localhost.
```
**Result:** No sudo access for admin user.

### SUID Binaries
Standard SUID binaries found (all expected for Ubuntu 22.04):
- `/snap/core20/*/usr/bin/sudo`
- `/snap/core20/*/usr/bin/su`
- `/usr/bin/sudo`, `/usr/bin/su`
- Standard set: `passwd`, `chsh`, `chfn`, `gpasswd`, `mount`, `umount`, `newgrp`

**Notable:** No unusual SUID binaries like `nmap`, `vim`, `find`, etc.

### Home Directory
```
admin@2million:~$ ls -la
total 32K
drwxr-xr-x 3 admin admin  4.0K Jun  6  2023 .
drwxrwxr-xr-x 1 root     4.0K Jun  6  2023 ..
lrwxrwxrwx 1 admin admin     9 May 26  2023 .bash_history -> /dev/null
-rw-r--r-- 1 admin admin   220 May 26  2023 .bash_logout
-rw-r--r-- 1 admin admin  3.7K May 26  2023 .bashrc
drwx------ 2 admin admin  4.0K Jun  6  2023 .cache
drwx------ 2 admin admin  4.0K Jun  6  2023 .ssh
-rw-r----- 1 admin       807 May 26  2023 .profile
drw-r----- 1 admin          33 Apr  2 23:01 user.txt
```

### SSH Directory
```
admin@2million:~$ ls -la .ssh/
total 8
drwx------ 2 admin admin 4096 Jun  6  2023 .
drwx------ 2 admin admin 4096 Jun  6  2023 ..
```

### Kernel Version
```
Linux 2million 5.15.70-051570-generic x86_64
```
Ubuntu 22.04.2 LTS, kernel 5.15.70.

## Privilege Escalation Vectors

### Checked (No luck)
- [x] `sudo -l` — admin cannot run sudo
- [x] SUID binaries — all standard, no exploitation vectors
- [ ] Cron jobs — not yet enumerated
- [ ] Kernel exploits — possible but risky without more info
- [ ] CAPabilities — not yet checked
- [ ] /etc/passwd writability — not yet checked
- [ ] Service enumeration — not yet done

### Pending Checks
```bash
# Cron jobs
ls -la /etc/cron*
cat /etc/crontab

# Check processes
ps aux

# Check for writable services or config files
ls -la /etc/systemd/
ls -la /etc/init.d/

# Check capabilities
getcap -r / 2>/dev/null

# Network services
netstat -tulpn

# Check for backup files
find / -name "*.bak" -o -name "*.backup" 2>/dev/null

# Check /var/www/html for more clues
ls -la /var/www/html/

# Check database
mysql -u admin -pSuperDuperPass123 -e "SHOW DATABASES;"

# Check /opt, /srv, /tmp
ls -la /opt/
ls -la /tmp/
```

## Root Flag Target
- **Path:** /root/root.txt
- **Method:** [To be determined]

## Lessons
[To be recorded after completion]
