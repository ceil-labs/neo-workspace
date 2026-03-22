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