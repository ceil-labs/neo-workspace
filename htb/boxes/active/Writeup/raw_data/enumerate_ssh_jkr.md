# Enumerate SSH user jkr

* Got user.txt

```bash
$ ssh jkr@10.129.191.3
jkr@10.129.191.3's password: raykayjay9
```

* Got user.txt

```bash
$ cat user.txt
539606a7825e5fd092f0e5afa6bd36f2
```

* No sudo command

```bash
jkr@writeup:~$ sudo -l
-bash: sudo: command not found
```

* Some system info

```bash
jkr@writeup:~$ id
uid=1000(jkr) gid=1000(jkr) groups=1000(jkr),24(cdrom),25(floppy),29(audio),30(dip),44(video),46(plugdev),50(staff),103(netdev)
jkr@writeup:~$ uname -a
Linux writeup 6.1.0-13-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.55-1 (2023-09-29) x86_64 GNU/Linux
jkr@writeup:~$ ifconfig
-bash: ifconfig: command not found
```

* SUID binaries

```bash
jkr@writeup:~$ find / -perm -4000 -ls 2>/dev/null
      934     40 -rwsr-xr-x   1 root     root        40536 May 17  2017 /bin/su
    10463     32 -rwsr-xr-x   1 root     root        30800 Aug 21  2018 /bin/fusermount
      296     40 -rwsr-xr-x   1 root     root        40200 May  4  2018 /bin/mount
     1080     60 -rwsr-xr-x   1 root     root        61240 Nov 10  2016 /bin/ping
      297     28 -rwsr-xr-x   1 root     root        27616 May  4  2018 /bin/umount
   131153     76 -rwsr-xr-x   1 root     root        75792 May 17  2017 /usr/bin/gpasswd
   147121     28 -rwsr-xr-x   1 root     root        27448 Mar 18  2019 /usr/bin/pkexec
   131150     52 -rwsr-xr-x   1 root     root        50040 May 17  2017 /usr/bin/chfn
   131154     60 -rwsr-xr-x   1 root     root        59680 May 17  2017 /usr/bin/passwd
   134385     40 -rwsr-xr-x   1 root     root        40312 May 17  2017 /usr/bin/newgrp
   131151     40 -rwsr-xr-x   1 root     root        40504 May 17  2017 /usr/bin/chsh
   142453     12 -rwsr-xr-x   1 root     root        10232 Mar 28  2017 /usr/lib/eject/dmcrypt-get-device
   147124     16 -rwsr-xr-x   1 root     root        14848 Mar 18  2019 /usr/lib/policykit-1/polkit-agent-helper-1
   133268    640 -rwsr-xr-x   1 root     root       653888 Sep 23  2023 /usr/lib/openssh/ssh-keysign
   157371     16 -r-sr-xr-x   1 root     root        14320 Aug 23  2019 /usr/lib/vmware-tools/bin64/vmware-user-suid-wrapper
   158879     16 -r-sr-xr-x   1 root     root        13628 Aug 23  2019 /usr/lib/vmware-tools/bin32/vmware-user-suid-wrapper
   140165     44 -rwsr-xr--   1 root     messagebus    44048 Mar 16  2019 /usr/lib/dbus-1.0/dbus-daemon-launch-helper
```

* Writable directories

```bash
jkr@writeup:~$ find / -writable -type d 2>/dev/null | grep -v proc
/var/local
/var/lib/php/sessions
/var/tmp
/usr/local
/usr/local/bin
/usr/local/include
/usr/local/share
/usr/local/share/sgml
/usr/local/share/sgml/misc
/usr/local/share/sgml/stylesheet
/usr/local/share/sgml/entities
/usr/local/share/sgml/dtd
/usr/local/share/sgml/declaration
/usr/local/share/fonts
/usr/local/share/ca-certificates
/usr/local/share/man
/usr/local/share/emacs
/usr/local/share/emacs/site-lisp
/usr/local/share/xml
/usr/local/share/xml/schema
/usr/local/share/xml/misc
/usr/local/share/xml/entities
/usr/local/share/xml/declaration
/usr/local/games
/usr/local/src
/usr/local/etc
/usr/local/lib
/usr/local/lib/python3.5
/usr/local/lib/python3.5/dist-packages
/usr/local/lib/python2.7
/usr/local/lib/python2.7/dist-packages
/usr/local/lib/python2.7/site-packages
/usr/local/sbin
/run/user/1000
/run/shm
/run/lock
/home/jkr
/tmp
```

* No login from /etc/passwd

```bash
jkr@writeup:~$ cat /etc/passwd | grep -v nologin
root:x:0:0:root:/root:/bin/bash
sync:x:4:65534:sync:/bin:/bin/sync
_apt:x:100:65534::/nonexistent:/bin/false
messagebus:x:101:104::/var/run/dbus:/bin/false
jkr:x:1000:1000:jkr,,,:/home/jkr:/bin/bash
mysql:x:103:106:MySQL Server,,,:/nonexistent:/bin/false
```

* crontab + /etc/hosts

```bash
jkr@writeup:~$ crontab -l
no crontab for jkr
jkr@writeup:~$ cat /etc/hosts
127.0.0.1       localhost
10.10.10.138    writeup.htb     writeup

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

* $PATH + mysql

```bash
jkr@writeup:/$ ls -la /root/ 2>/dev/null || echo "No access"
No access
jkr@writeup:/$ echo $PATH
/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
jkr@writeup:/$ which mysql
/usr/bin/mysql
```

* pkexec

```bash
jkr@writeup:/$ which pkexec
/usr/bin/pkexec

jkr@writeup:/$ /usr/bin/pkexec --version
pkexec version 0.105
```

* Explored mysql:

```bash
jkr@writeup:/tmp$ systemctl status mysql 2>/dev/null || service mysql status 2>/dev/null || ps aux | grep mysql
root      1775  0.0  0.1   6016  3040 ?        S    05:30   0:00 /bin/bash /usr/bin/mysqld_safe
mysql     1923  0.0  5.3 627500 108560 ?       Sl   05:30   0:06 /usr/sbin/mysqld --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib/x86_64-linux-gnu/mariadb18/plugin --user=mysql --skip-log-error --pid-file=/var/run/mysqld/mysqld.pid --socket=/var/run/mysqld/mysqld.sock --port=3306
root      1924  0.0  0.0   2484   936 ?        S    05:30   0:00 logger -t mysqld -p daemon error
jkr       3711  0.0  0.0   8208  1156 pts/0    S+   09:37   0:00 grep mysql
jkr@writeup:/tmp$ ss -tlnp | grep 3306
LISTEN     0      80     127.0.0.1:3306                     *:*
jkr@writeup:/tmp$ find /var/www -name "config.php" -exec grep -l "database\|mysql\|pass" {} \;
find: ‘/var/www/html/writeup’: Permission denied
jkr@writeup:/tmp$
jkr@writeup:/tmp$ cat /etc/mysql/my.cnf | grep bind-address
jkr@writeup:/tmp$ cat /etc/mysql/mariadb.conf.d/50-server.cnf | grep bind-address
bind-address            = 127.0.0.1
jkr@writeup:/tmp$ mysql -u root -e "SHOW DATABASES;" 2>/dev/null && echo "Root access!"
jkr@writeup:/tmp$ mysql -u jkr -p'raykayjay9' -e "SHOW DATABASES;"
ERROR 1045 (28000): Access denied for user 'jkr'@'localhost' (using password: YES)
jkr@writeup:/tmp$ ls -la /var/www/html/
total 20
drwxr-xr-x 3 root     root     4096 Apr 24  2019 .
drwxr-xr-x 3 root     root     4096 Apr 19  2019 ..
-rw-r--r-- 1 root     root     3032 Apr 24  2019 index.html
-rw-r--r-- 1 root     root      310 Apr 24  2019 robots.txt
drwx------ 9 www-data www-data 4096 Apr 19  2019 writeup
jkr@writeup:/tmp$ # See what permissions exist
jkr@writeup:/tmp$ find / -name "*.php~" -o -name "config.php.bak" 2>/dev/null
jkr@writeup:/tmp$ grep -r "password" /var/www/html/ 2>/dev/null | head -10
```

* Looking for .*php files that may have config

```

jkr@writeup:/var/www/html$ id
uid=1000(jkr) gid=1000(jkr) groups=1000(jkr),24(cdrom),25(floppy),29(audio),30(dip),44(video),46(plugdev),50(staff),103(netdev)
jkr@writeup:/var/www/html$ uname -a
Linux writeup 6.1.0-13-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.55-1 (2023-09-29) x86_64 GNU/Linux
jkr@writeup:/var/www/html$ find /var -name "*.php" -readable 2>/dev/null
/var/cache/dictionaries-common/sqspell.php
jkr@writeup:/var/www/html$ find /opt /home -name "config*" -o -name "*.env" 2>/dev/null
jkr@writeup:/var/www/html$ cat /var/cache/dictionaries-common/sqspell.php
<?php
### This file is part of the dictionaries-common package.
### It has been automatically generated.
### DO NOT EDIT!
$SQSPELL_APP = array (
  'American English (ispell)' => 'ispell -a    -B -d american',
  'British English (ispell)' => 'ispell -a    -B -d british'
);
```

* fusermount

```bash
jkr@writeup:/var/www/html$ cat /etc/fuse.conf
# /etc/fuse.conf - Configuration file for Filesystem in Userspace (FUSE)

# Set the maximum number of FUSE mounts allowed to non-root users.
# The default is 1000.
#mount_max = 1000

# Allow non-root users to specify the allow_other or allow_root mount options.
#user_allow_other
jkr@writeup:/var/www/html$
```

* keysign

```bash
jkr@writeup:/var/www/html$ /usr/lib/openssh/ssh-keysign --help 2>&1 | head -5
ssh-keysign not enabled in /etc/ssh/ssh_config
```

* vmware
```bash
jkr@writeup:/var/www/html$ /usr/lib/vmware-tools/bin64/vmware-user-suid-wrapper --version 2>&1 | head
vmware-user: could not obtain SBINDIR
vmware-user: failed to start vmware-user
jkr@writeup:/var/www/html$
```

* CRON

jkr@writeup:/var/www/html$ ls /etc/cron.d
php
jkr@writeup:/var/www/html$ ls /etc/cron.d/php
/etc/cron.d/php
jkr@writeup:/var/www/html$ ls -lah /etc/cron.d/php
-rw-r--r-- 1 root root 702 Apr 19  2019 /etc/cron.d/php
jkr@writeup:/var/www/html$ cat /etc/cron.d/php
# /etc/cron.d/php@PHP_VERSION@: crontab fragment for PHP
#  This purges session files in session.save_path older than X,
#  where X is defined in seconds as the largest value of
#  session.gc_maxlifetime from all your SAPI php.ini files
#  or 24 minutes if not defined.  The script triggers only
#  when session.save_handler=files.
#
#  WARNING: The scripts tries hard to honour all relevant
#  session PHP options, but if you do something unusual
#  you have to disable this script and take care of your
#  sessions yourself.

# Look for and purge old sessions every day
09 0     * * *     root   [ -x /usr/lib/php/sessionclean ] && if [ ! -d /run/systemd/system ]; then /usr/lib/php/sessionclean; fi
jkr@writeup:/var/www/html$ ls -d /run/systemd/system 2>/dev/null && echo "systemd running - cron won't fire" || echo "NO systemd - cron WILL fire"
NO systemd - cron WILL fire
jkr@writeup:/var/www/html$ ls -la /usr/lib/php/sessionclean
-rwxr-xr-x 1 root root 2922 Jan  1  2017 /usr/lib/php/sessionclean
jkr@writeup:/var/www/html$ file /usr/lib/php/sessionclean
/usr/lib/php/sessionclean: POSIX shell script, UTF-8 Unicode text executable
jkr@writeup:/var/www/html$ cat /usr/lib/php/sessionclean
#!/bin/sh -e
#
# sessionclean - a script to cleanup stale PHP sessions
#
# Copyright 2013-2015 Ondřej Surý <ondrej@sury.org>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

SAPIS="apache2:apache2 apache2filter:apache2 cgi:php@VERSION@ fpm:php-fpm@VERSION@ cli:php@VERSION@"

# Iterate through all web SAPIs
(
proc_names=""
for version in $(/usr/sbin/phpquery -V); do
    for sapi in ${SAPIS}; do
        conf_dir=${sapi%%:*}
        proc_name=${sapi##*:}
        if [ -e /etc/php/${version}/${conf_dir}/php.ini ]; then
            # Get all session variables once so we don't need to start PHP to get each config option
            session_config=$(PHP_INI_SCAN_DIR=/etc/php/${version}/${conf_dir}/conf.d/ php${version} -c /etc/php/${version}/${co
nf_dir}/php.ini -d "error_reporting='~E_ALL'" -r 'foreach(ini_get_all("session") as $k => $v) echo "$k=".$v["local_value"]."\n";')
            save_handler=$(echo "$session_config" | sed -ne 's/^session\.save_handler=\(.*\)$/\1/p')
            save_path=$(echo "$session_config" | sed -ne 's/^session\.save_path=\(.*;\)\?\(.*\)$/\2/p')
            gc_maxlifetime=$(($(echo "$session_config" | sed -ne 's/^session\.gc_maxlifetime=\(.*\)$/\1/p')/60))

            if [ "$save_handler" = "files" -a -d "$save_path" ]; then
                proc_names="$proc_names $(echo "$proc_name" | sed -e "s,@VERSION@,$version,")";
                printf "%s:%s\n" "$save_path" "$gc_maxlifetime"
            fi
        fi
    done
done
# first find all open session files and touch them (hope it's not massive amount of files)
for pid in $(pidof $proc_names); do
    find "/proc/$pid/fd" -ignore_readdir_race -lname "$save_path/sess_*" -exec touch -c {} \; 2>/dev/null
done ) | \
    sort -rn -t: -k2,2 | \
    sort -u -t: -k 1,1 | \
    while IFS=: read -r save_path gc_maxlifetime; do
        # find all files older then maxlifetime and delete them
        find -O3 "$save_path/" -ignore_readdir_race -depth -mindepth 1 -name 'sess_*' -type f -cmin "+$gc_maxlifetime" -delete
    done

exit 0
jkr@writeup:/var/www/html$

* More on CRON

```bash
jkr@writeup:/var/www/html$ cat /etc/crontab
# /etc/crontab: system-wide crontab
# Unlike any other crontab you don't have to run the `crontab'
# command to install the new version when you edit this file
# and files in /etc/cron.d. These files also have username fields,
# that none of the other crontabs do.

SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# m h dom mon dow user  command
17 *    * * *   root    cd / && /bin/run-parts --report /etc/cron.hourly
25 6    * * *   root    test -x /usr/sbin/anacron || ( cd / && /bin/run-parts --report /etc/cron.daily )
47 6    * * 7   root    test -x /usr/sbin/anacron || ( cd / && /bin/run-parts --report /etc/cron.weekly )
52 6    1 * *   root    test -x /usr/sbin/anacron || ( cd / && /bin/run-parts --report /etc/cron.monthly )
#
jkr@writeup:/var/www/html$ cd /etc/cron
-bash: cd: /etc/cron: No such file or directory
jkr@writeup:/var/www/html$ ls
index.html  robots.txt  writeup
jkr@writeup:/var/www/html$ cd /etc/cron
cron.d/       cron.daily/   cron.hourly/  cron.monthly/ crontab       cron.weekly/
jkr@writeup:/var/www/html$ cd /etc/cron
cron.d/       cron.daily/   cron.hourly/  cron.monthly/ crontab       cron.weekly/
jkr@writeup:/var/www/html$ cd /etc/cron.hourly/
jkr@writeup:/etc/cron.hourly$ ls
jkr@writeup:/etc/cron.hourly$ ls -lah
total 12K
drwxr-xr-x  2 root root 4.0K Apr 19  2019 .
drwxr-xr-x 85 root root 4.0K Mar 22 10:33 ..
-rw-r--r--  1 root root  102 Oct  7  2017 .placeholder
jkr@writeup:/etc/cron.hourly$ ls -la ../cron.daily/
total 36
drwxr-xr-x  2 root root 4096 Apr 19  2019 .
drwxr-xr-x 85 root root 4096 Mar 22 10:33 ..
-rwxr-xr-x  1 root root  539 Nov  3  2018 apache2
-rwxr-xr-x  1 root root 1474 Sep 13  2017 apt-compat
-rwxr-xr-x  1 root root  355 Oct 25  2016 bsdmainutils
-rwxr-xr-x  1 root root 1597 Feb 22  2017 dpkg
-rwxr-xr-x  1 root root   89 May  5  2015 logrotate
-rwxr-xr-x  1 root root  249 May 17  2017 passwd
-rw-r--r--  1 root root  102 Oct  7  2017 .placeholder
jkr@writeup:/etc/cron.hourly$ ls -lah ../cron.weekly/
total 12K
drwxr-xr-x  2 root root 4.0K Apr 19  2019 .
drwxr-xr-x 85 root root 4.0K Mar 22 10:33 ..
-rw-r--r--  1 root root  102 Oct  7  2017 .placeholder
jkr@writeup:/etc/cron.hourly$
```

Seems dead end with CRON. Requires root

```bash
jkr@writeup:/etc/cron.hourly$ ls -la /etc/default/apache-htcacheclean
-rw-r--r-- 1 root root 556 Nov  3  2018 /etc/default/apache-htcacheclean
jkr@writeup:/etc/cron.hourly$ ls -la $(which htcacheclean)
-rwxr-xr-x 1 root root 30720 Apr  2  2019 /usr/bin/htcacheclean
jkr@writeup:/etc/cron.hourly$ ls -la /var/cache/apache2/mod_cache_disk 2>/dev/null
total 8
drwxr-xr-x 2 www-data www-data 4096 Apr  2  2019 .
drwxr-xr-x 3 root     root     4096 Apr 19  2019 ..
jkr@writeup:/etc/cron.hourly$
```

* IP Enum

```bash
jkr@writeup:~$ ip addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:50:56:95:5a:d2 brd ff:ff:ff:ff:ff:ff
    inet 10.129.191.3/16 brd 10.129.255.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::250:56ff:fe95:5ad2/64 scope link
       valid_lft forever preferred_lft forever
jkr@writeup:~$ mount | grep -E "usb|media"
jkr@writeup:~$ ls -la /media/ /mnt/ 2>/dev/null
/media/:
total 12
drwxr-xr-x  3 root root 4096 Apr 19  2019 .
drwxr-xr-x 22 root root 4096 Oct 25  2023 ..
lrwxrwxrwx  1 root root    6 Apr 19  2019 cdrom -> cdrom0
drwxr-xr-x  2 root root 4096 Apr 19  2019 cdrom0

/mnt/:
total 8
drwxr-xr-x  2 root root 4096 Apr 19  2019 .
drwxr-xr-x 22 root root 4096 Oct 25  2023 ..
jkr@writeup:~$ lsblk 2>/dev/null || blkid 2>/dev/null
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0   5G  0 disk
├─sda1   8:1    0   4G  0 part /
├─sda2   8:2    0   1K  0 part
└─sda5   8:5    0   1G  0 part [SWAP]
jkr@writeup:~$ dmesg | grep -i "usb\|remov" 2>/dev/null | tail -10
dmesg: read kernel buffer failed: Operation not permitted
```