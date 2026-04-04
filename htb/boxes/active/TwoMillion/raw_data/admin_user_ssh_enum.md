# admin user - SSH Enumeration

```
└─$ ssh admin@10.129.229.66
The authenticity of host '10.129.229.66 (10.129.229.66)' can't be established.
ED25519 key fingerprint is: SHA256:TgNhCKF6jUX7MG8TC01/MUj/+u0EBasUVsdSQMHdyfY
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.129.229.66' (ED25519) to the list of known hosts.
admin@10.129.229.66's password:
Welcome to Ubuntu 22.04.2 LTS (GNU/Linux 5.15.70-051570-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Fri Apr  3 08:45:09 AM UTC 2026

  System load:           0.0
  Usage of /:            74.4% of 4.82GB
  Memory usage:          8%
  Swap usage:            0%
  Processes:             224
  Users logged in:       0
  IPv4 address for eth0: 10.129.229.66
  IPv6 address for eth0: dead:beef::250:56ff:feb9:c1c0


Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update

You have mail.
Last login: Tue Jun  6 12:43:11 2023 from 10.10.14.6
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.
```

Notes:
* There seems to be email
* Seems can not run as sudo

```
admin@2million:~$ sudo -l
[sudo] password for admin:
Sorry, user admin may not run sudo on localhost.
```

Got user.txt

```bash
admin@2million:~$ cat user.txt
e0d52f0fa1c2e8756998955b5bd7158e
```

* SUID binaries

```bash
admin@2million:~$ find / -perm -4000 -ls 2>/dev/null
      297    129 -rwsr-xr-x   1 root     root       131832 Apr 18  2023 /snap/snapd/19122/usr/lib/snapd/snap-confine
      821     84 -rwsr-xr-x   1 root     root        85064 Nov 29  2022 /snap/core20/1891/usr/bin/chfn
      827     52 -rwsr-xr-x   1 root     root        53040 Nov 29  2022 /snap/core20/1891/usr/bin/chsh
      896     87 -rwsr-xr-x   1 root     root        88464 Nov 29  2022 /snap/core20/1891/usr/bin/gpasswd
      980     55 -rwsr-xr-x   1 root     root        55528 Feb  7  2022 /snap/core20/1891/usr/bin/mount
      989     44 -rwsr-xr-x   1 root     root        44784 Nov 29  2022 /snap/core20/1891/usr/bin/newgrp
     1004     67 -rwsr-xr-x   1 root     root        68208 Nov 29  2022 /snap/core20/1891/usr/bin/passwd
     1114     67 -rwsr-xr-x   1 root     root        67816 Feb  7  2022 /snap/core20/1891/usr/bin/su
     1115    163 -rwsr-xr-x   1 root     root       166056 Apr  4  2023 /snap/core20/1891/usr/bin/sudo
     1173     39 -rwsr-xr-x   1 root     root        39144 Feb  7  2022 /snap/core20/1891/usr/bin/umount
     1262     51 -rwsr-xr--   1 root     systemd-resolve    51344 Oct 25  2022 /snap/core20/1891/usr/lib/dbus-1.0/dbus-daemon-launch-helper
     1634    463 -rwsr-xr-x   1 root     root              473576 Mar 30  2022 /snap/core20/1891/usr/lib/openssh/ssh-keysign
      842     40 -rwsr-xr-x   1 root     root               40496 Nov 24  2022 /usr/bin/newgrp
      697     72 -rwsr-xr-x   1 root     root               72072 Nov 24  2022 /usr/bin/gpasswd
     1111     56 -rwsr-xr-x   1 root     root               55672 Feb 21  2022 /usr/bin/su
     1187     36 -rwsr-xr-x   1 root     root               35192 Feb 21  2022 /usr/bin/umount
      573     44 -rwsr-xr-x   1 root     root               44808 Nov 24  2022 /usr/bin/chsh
      681     36 -rwsr-xr-x   1 root     root               35200 Mar 23  2022 /usr/bin/fusermount3
     2484    228 -rwsr-xr-x   1 root     root              232416 Apr  3  2023 /usr/bin/sudo
      876     60 -rwsr-xr-x   1 root     root               59976 Nov 24  2022 /usr/bin/passwd
      830     48 -rwsr-xr-x   1 root     root               47480 Feb 21  2022 /usr/bin/mount
      567     72 -rwsr-xr-x   1 root     root               72712 Nov 24  2022 /usr/bin/chfn
     1409     36 -rwsr-xr--   1 root     messagebus         35112 Oct 25  2022 /usr/lib/dbus-1.0/dbus-daemon-launch-helper
    28894    136 -rwsr-xr-x   1 root     root              138408 May 29  2023 /usr/lib/snapd/snap-confine
     1603    332 -rwsr-xr-x   1 root     root              338536 Nov 23  2022 /usr/lib/openssh/ssh-keysign
    13665     20 -rwsr-xr-x   1 root     root               18736 Feb 26  2022 /usr/libexec/polkit-agent-helper-1
```

Found email from admin:

```bash
admin@2million:~$ cat /var/mail/admin
From: ch4p <ch4p@2million.htb>
To: admin <admin@2million.htb>
Cc: g0blin <g0blin@2million.htb>
Subject: Urgent: Patch System OS
Date: Tue, 1 June 2023 10:45:22 -0700
Message-ID: <9876543210@2million.htb>
X-Mailer: ThunderMail Pro 5.2

Hey admin,

I'm know you're working as fast as you can to do the DB migration. While we're partially down, can you also upgrade the OS on our web host? There have been a few serious Linux kernel CVEs already this year. That one in OverlayFS / FUSE looks nasty. We can't get popped by that.

HTB Godfather
```

Check for exploit vulnerabilities:

```bash
admin@2million:~$ uname -a
Linux 2million 5.15.70-051570-generic #202209231339 SMP Fri Sep 23 13:45:37 UTC 2022 x86_64 x86_64 x86_64 GNU/Linux
admin@2million:~$ which fusermount
/usr/bin/fusermount
admin@2million:~$ ls -la /dev/fuse
crw-rw-rw- 1 root root 10, 229 Apr  4 05:42 /dev/fuse
```

Got root using exploit and instructions here: https://github.com/sxlmnwb/CVE-2023-0386

```bash
root@2million:/tmp/CVE-2023-0386# cat /root/root.txt
7368102e7142483b2a66a81260081672
root@2million:/tmp/CVE-2023-0386#
```