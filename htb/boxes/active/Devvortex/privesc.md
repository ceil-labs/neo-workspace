# Privilege Escalation

## Context
- **Target**: Linux devvortex 5.4.0-167-generic (Ubuntu)
- **Current user**: www-data (uid=33)
- **Shell status**: Active, basic (no TTY)
- **Initial access**: Joomla template webshell

## Enumeration

### Current User
```
id
# uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

### Target Files / Flags
| Target | Location | Status |
|--------|----------|--------|
| User flag | /home/logan/user.txt | Permission denied (www-data cannot read) |

### Privilege Checks
- **sudo -l**: Requires password (not available for www-data)
- **SUID binaries**: Standard system set (no obvious escalation candidates yet)

#### SUID Binaries Found
```
/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/usr/lib/eject/dmcrypt-get-device
/usr/lib/policykit-1/polkit-agent-helper-1
/usr/lib/openssh/ssh-keysign
/usr/bin/mount
/usr/bin/sudo
/usr/bin/gpasswd
/usr/bin/umount
/usr/bin/passwd
/usr/bin/fusermount
/usr/bin/chsh
/usr/bin/at
/usr/bin/chfn
/usr/bin/newgrp
/usr/bin/su
```

### Users on System
```
# Check /etc/passwd for other users
cat /etc/passwd | grep -v nologin
```

### Next Steps Checklist
- [ ] Try database password (P4ntherg0t1n5r3c0n##) for user `logan` via `su`
- [ ] Check /etc/passwd for other users
- [ ] Enumerate running processes (`ps aux`)
- [ ] Check for cron jobs (`crontab -l`, `/etc/crontab`)
- [ ] Look for writable files/directories
- [ ] Check for kernel exploits (uname -r → search)
- [ ] Check if logan has sudo privileges discoverable elsewhere
- [ ] Check /var/www/html for configuration files with credentials
- [ ] Check /home/logan for readable files

## Vector Found
[What misconfiguration or vulnerability?]

## Exploitation
```
# Commands or code used
```

## Root/Admin Access
- User: root / administrator
- Proof: 

## Lessons
[What did you learn from this privesc?]
