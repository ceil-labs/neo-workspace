# Privilege Escalation — Writeup

## Status
- [ ] Initial shell: ✅ `jkr` on 10.129.191.3
- [ ] User flag: 🔄 Pending
- [ ] Privesc enumeration: 🔄 Pending
- [ ] Root access: 🔄 Pending

## Initial Enumeration
*(To be completed after initial shell access)*

### Target Info
```
jkr@writeup:~$ uname -a
Linux writeup 6.1.0-13-amd64 x86_64 GNU/Linux
```

### Standard Checklist
- [ ] `sudo -l` — what can jkr run as root?
- [ ] `find / -perm -4000 -ls 2>/dev/null` — SUID binaries
- [ ] `find / -writable -type d 2>/dev/null | grep -v proc` — writable dirs
- [ ] `cat /etc/passwd | grep -v nologin` — other users
- [ ] `ps aux | grep root` — root-owned processes
- [ ] `crontab -l` and `/etc/crontab` — scheduled tasks
- [ ] `cat /etc/hosts`, `/etc/fstab`, `/etc/sudoers` — config inspection
- [ ] `dpkg -l` / `apt list --installed 2>/dev/null` — installed packages
- [ ] Kernel version check — `uname -r`, searchsploit for kernel exploits

## Vector Found
*(To be documented after enumeration)*

## Exploitation
*(To be documented after privesc is achieved)*

## Root Access
- **User**: root
- **Proof**: *(flag pending)*

## Lessons
*(To be documented after completion)*
