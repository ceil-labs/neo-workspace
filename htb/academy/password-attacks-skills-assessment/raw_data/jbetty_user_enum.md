# jbetty User Enum (port 22)

## Linux Kernel

```bash
jbetty@DMZ01:~$ uname -r
5.4.0-216-generic
```

## SUID binaries

```bash
$ find / -perm -4000 -type f 2>/dev/null | head -20
/usr/lib/openssh/ssh-keysign
/usr/lib/snapd/snap-confine
/usr/lib/policykit-1/polkit-agent-helper-1
/usr/lib/eject/dmcrypt-get-device
/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/usr/bin/pkexec
/usr/bin/passwd
/usr/bin/chsh
/usr/bin/fusermount
/usr/bin/sudo
/usr/bin/newgrp
/usr/bin/mount
/usr/bin/gpasswd
/usr/bin/umount
/usr/bin/su
/usr/bin/at
/usr/bin/chfn
/snap/snapd/23771/usr/lib/snapd/snap-confine
/snap/core20/2582/usr/bin/chfn
/snap/core20/2582/usr/bin/chsh
```

## Writable directories

```bash
jbetty@DMZ01:~$ find / -type d -writable 2>/dev/null | grep -v proc | head -10
/dev/mqueue
/dev/shm
/run/user/1001
/run/user/1001/gnupg
/run/user/1001/systemd
/run/user/1001/systemd/units
/run/screen
/run/lock
/tmp
/tmp/.X11-unix
jbetty@DMZ01:~$
```

## Cron jobs (scheduled tasks running as root?)

```bash
jbetty@DMZ01:~$ cat /etc/crontab
# /etc/crontab: system-wide crontab
# Unlike any other crontab you don't have to run the `crontab'
# command to install the new version when you edit this file
# and files in /etc/cron.d. These files also have username fields,
# that none of the other crontabs do.

SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name command to be executed
17 *    * * *   root    cd / && run-parts --report /etc/cron.hourly
25 6    * * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )
47 6    * * 7   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.weekly )
52 6    1 * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.monthly )

jbetty@DMZ01:~$ ls -lah /etc/cron.d/
total 20K
drwxr-xr-x  2 root root 4.0K Apr 29  2025 .
drwxr-xr-x 96 root root 4.0K Jun  2  2025 ..
-rw-r--r--  1 root root  201 Feb 14  2020 e2scrub_all
-rw-r--r--  1 root root  102 Feb 13  2020 .placeholder
-rw-r--r--  1 root root  191 Apr 23  2020 popularity-contest
jbetty@DMZ01:~$ ls -lah /etc/cron.daily/
total 48K
drwxr-xr-x  2 root root 4.0K May 30  2025 .
drwxr-xr-x 96 root root 4.0K Jun  2  2025 ..
-rwxr-xr-x  1 root root  376 Dec  4  2019 apport
-rwxr-xr-x  1 root root 1.5K Apr  9  2020 apt-compat
-rwxr-xr-x  1 root root  355 Dec 29  2017 bsdmainutils
-rwxr-xr-x  1 root root 1.2K Sep  5  2019 dpkg
-rwxr-xr-x  1 root root  377 Jan 21  2019 logrotate
-rwxr-xr-x  1 root root 1.1K Feb 25  2020 man-db
-rw-r--r--  1 root root  102 Feb 13  2020 .placeholder
-rwxr-xr-x  1 root root 4.5K Jul 18  2019 popularity-contest
-rwxr-xr-x  1 root root  214 Apr  2  2020 update-notifier-common


jbetty@DMZ01:~$ cat /etc/cron.d/es2scrub_all
cat: /etc/cron.d/es2scrub_all: No such file or directory
jbetty@DMZ01:~$ cat /etc/cron.d/e2scrub_all
30 3 * * 0 root test -e /run/systemd/system || SERVICE_MODE=1 /usr/lib/x86_64-linux-gnu/e2fsprogs/e2scrub_all_cron
10 3 * * * root test -e /run/systemd/system || SERVICE_MODE=1 /sbin/e2scrub_all -A -r
jbetty@DMZ01:~$ cat /etc/cron.d/popularity-contest
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
28 23 * * *   root    test -x /etc/cron.daily/popularity-contest && /etc/cron.daily/popularity-contest --crond
```

## Bash History

```bash
jbetty@DMZ01:~$ ls -lah
total 32K
drwxr-xr-x 4 jbetty jbetty 4.0K Jun  2  2025 .
drwxr-xr-x 4 root   root   4.0K May 30  2025 ..
-rw-r--r-- 1 jbetty jbetty 2.1K Jun  2  2025 .bash_history
-rw-r--r-- 1 jbetty jbetty  220 Apr 29  2025 .bash_logout
-rw-r--r-- 1 jbetty jbetty 3.7K Apr 29  2025 .bashrc
drwx------ 2 jbetty jbetty 4.0K May 30  2025 .cache
drwxrwxr-x 3 jbetty jbetty 4.0K May 30  2025 .local
-rw-r--r-- 1 jbetty jbetty  807 Apr 29  2025 .profile

jbetty@DMZ01:~$ cat .bash_history
cd ~/projects
ls
git status
git pull origin main
vim README.md
cat ~/.bashrc
sudo apt update
sudo apt upgrade -y
clear
cd ~/Downloads
ls -lh
rm -rf old_project/
mkdir temp
cd temp
touch test.py
nano test.py
python3 test.py
pip install requests
pip install flask
history
df -h
free -m
top
htop
sshpass -p "dealer-screwed-gym1" ssh hwilliam@file01
sudo systemctl status apache2
sudo systemctl restart apache2
cd /etc/nginx/sites-available
ls
cat default
sudo nano default
sudo nginx -t
sudo systemctl reload nginx
cd ~
mkdir scripts
cd scripts
vim backup.sh
chmod +x backup.sh
./backup.sh
ssh user@192.168.0.101
scp file.txt user@192.168.0.101:~/Documents/
logout
exit
cd /var/log
ls -ltr
sudo tail -f syslog
sudo journalctl -xe
sudo dmesg | less
ps aux | grep python
kill -9 13245
git clone https://github.com/example/repo.git
cd repo
ls -a
code .
npm install
npm run dev
cd ..
rm -rf repo/
curl https://ipinfo.io
ping google.com
traceroute github.com
whoami
groups
sudo adduser testuser
sudo usermod -aG sudo testuser
su - testuser
exit
passwd
uptime
reboot
mkdir ~/backup
rsync -av ~/Documents/ ~/backup/
du -sh *
alias ll='ls -alF'
unalias ll
history | grep ssh
find . -name "*.log"
grep -r "ERROR" /var/log/
awk '{print $1}' access.log | sort | uniq -c | sort -nr | head
chmod 755 script.sh
chown user:user script.sh
git checkout -b feature/login
git commit -am "Add login feature"
git push origin feature/login
git merge main
git push
git log --oneline
docker ps
docker images
docker run -it ubuntu bash
exit
cd /tmp
touch index.html
echo "<h1>Hello World</h1>" > index.html
cat index.html
python3 -m http.server
curl localhost:8000
ctrl+c
tmux
tmux new -s dev
tmux ls
tmux attach -t dev
tmux kill-session -t dev
man rsync
man chown
crontab -e
lsblk
mount
umount /dev/sdb1
lsusb
lscpu
sudo apt install tree
tree
zip -r archive.zip folder/
unzip archive.zip
wget http://example.com/file.zip
tar -xzvf file.tar.gz
tar -czvf archive.tar.gz folder/
logout

clear
ls -l
clear
ls -l
clear
nano .bash_history
su
clear
ls -l
nano .bash_history
echo > .bash_history
nano .bash_history
less .bash_history
clear
exit
pwd
cat .bash_history
exit
jbetty@DMZ01:~$
```

## Check other users

```bash
jbetty@DMZ01:/home/lab_adm$ ls -lah
total 28K
drwxr-xr-x 3 lab_adm lab_adm 4.0K May 30  2025 .
drwxr-xr-x 4 root    root    4.0K May 30  2025 ..
lrwxrwxrwx 1 root    root       9 May 30  2025 .bash_history -> /dev/null
-rw-r--r-- 1 lab_adm lab_adm  220 Feb 25  2020 .bash_logout
-rw-r--r-- 1 lab_adm lab_adm 3.7K Feb 25  2020 .bashrc
drwx------ 2 lab_adm lab_adm 4.0K Oct  6  2021 .cache
-rw-r--r-- 1 lab_adm lab_adm  807 Feb 25  2020 .profile
-rw-r--r-- 1 lab_adm lab_adm    0 Oct  6  2021 .sudo_as_admin_successful
-rw------- 1 lab_adm lab_adm 1.6K Oct  6  2021 .viminfo
```

## Passwords

```bash
jbetty@DMZ01:/home/lab_adm$ grep -r "password" /home/ 2>/dev/null | head -10
jbetty@DMZ01:/home/lab_adm$ grep -r "passwd" /home/ 2>/dev/null | head -10
/home/jbetty/.bash_history:passwd
```

## env vars

```bash
jbetty@DMZ01:~$ env
SHELL=/bin/bash
PWD=/home/jbetty
LOGNAME=jbetty
XDG_SESSION_TYPE=tty
MOTD_SHOWN=pam
HOME=/home/jbetty
LANG=en_US.UTF-8
LS_COLORS=rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:
SSH_CONNECTION=10.10.15.34 47894 10.129.234.116 22
LESSCLOSE=/usr/bin/lesspipe %s %s
XDG_SESSION_CLASS=user
TERM=tmux-256color
LESSOPEN=| /usr/bin/lesspipe %s
USER=jbetty
SHLVL=1
XDG_SESSION_ID=1
XDG_RUNTIME_DIR=/run/user/1001
SSH_CLIENT=10.10.15.34 47894 22
LC_ALL=en_US.utf-8
XDG_DATA_DIRS=/usr/local/share:/usr/share:/var/lib/snapd/desktop
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1001/bus
SSH_TTY=/dev/pts/0
_=/usr/bin/env
OLDPWD=/home
jbetty@DMZ01:~$ who
jbetty   pts/0        2026-04-18 13:45 (10.10.15.34)
```

## Check for other network and hosts

```bash
jbetty@DMZ01:~$ ifconfig
                                                                                                              ens160: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.129.234.116  netmask 255.255.0.0  broadcast 10.129.255.255
        inet6 fe80::250:56ff:fe8a:497a  prefixlen 64  scopeid 0x20<link>
        inet6 dead:beef::250:56ff:fe8a:497a  prefixlen 64  scopeid 0x0<global>
        ether 00:50:56:8a:49:7a  txqueuelen 1000  (Ethernet)
        RX packets 2747  bytes 262330 (262.3 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1878  bytes 209345 (209.3 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

ens192: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.16.119.13  netmask 255.255.255.0  broadcast 172.16.119.255
        inet6 fe80::250:56ff:fe8a:f638  prefixlen 64  scopeid 0x20<link>
        ether 00:50:56:8a:f6:38  txqueuelen 1000  (Ethernet)
        RX packets 979  bytes 62005 (62.0 KB)
        RX errors 0  dropped 11  overruns 0  frame 0
        TX packets 36  bytes 3036 (3.0 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 2752  bytes 216458 (216.4 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 2752  bytes 216458 (216.4 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

jbetty@DMZ01:~$ which nmap
jbetty@DMZ01:~$ for i in $(seq 1 254); do ping -c1 -W1 172.16.119.$i & done 2>/dev/null | grep "bytes from"
64 bytes from 172.16.119.13: icmp_seq=1 ttl=64 time=0.017 ms
64 bytes from 172.16.119.11: icmp_seq=1 ttl=128 time=1.77 ms
```