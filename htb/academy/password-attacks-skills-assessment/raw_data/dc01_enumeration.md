# DC01 enumeration

## SMB

```bash
└─$ proxychains netexec smb 172.16.119.11 -u hwilliam -p 'dealer-screwed-gym1' --shares
[proxychains] config file found: /etc/proxychains.conf
[proxychains] preloading /usr/lib/x86_64-linux-gnu/libproxychains.so.4
[proxychains] DLL init: proxychains-ng 4.17
[proxychains] Dynamic chain  ...  127.0.0.1:9050  ...  172.16.119.11:445  ...  OK
[proxychains] Dynamic chain  ...  127.0.0.1:9050  ...  172.16.119.11:445  ...  OK
[proxychains] Dynamic chain  ...  127.0.0.1:9050  ...  172.16.119.11:135  ...  OK
SMB         172.16.119.11   445    DC01             [*] Windows 10 / Server 2019 Build 17763 x64 (name:DC01) (domain:nexura.htb) (signing:True) (SMBv1:None) (Null Auth:True)
[proxychains] Dynamic chain  ...  127.0.0.1:9050  ...  172.16.119.11:445  ...  OK
[proxychains] Dynamic chain  ...  127.0.0.1:9050  ...  172.16.119.11:445  ...  OK
SMB         172.16.119.11   445    DC01             [+] nexura.htb\hwilliam:dealer-screwed-gym1
SMB         172.16.119.11   445    DC01             [*] Enumerated shares
SMB         172.16.119.11   445    DC01             Share           Permissions     Remark
SMB         172.16.119.11   445    DC01             -----           -----------     ------
SMB         172.16.119.11   445    DC01             ADMIN$                          Remote Admin
SMB         172.16.119.11   445    DC01             C$                              Default share
SMB         172.16.119.11   445    DC01             IPC$            READ            Remote IPC
SMB         172.16.119.11   445    DC01             NETLOGON        READ            Logon server share
SMB         172.16.119.11   445    DC01             SYSVOL          READ            Logon server share
```

```bash
└─$ proxychains smbclient -U 'nexura.htb\hwilliam' '\\\\172.16.119.11\\SYSVOL' -p 'dealer-screwed-gym1'
[proxychains] config file found: /etc/proxychains.conf
[proxychains] preloading /usr/lib/x86_64-linux-gnu/libproxychains.so.4
[proxychains] DLL init: proxychains-ng 4.17
do_connect: Connection to  failed (Error NT_STATUS_NOT_FOUND)
```

```bash
┌──(openclaw㉿srv1405873)-[~]
└─$ proxychains smbclient -U 'nexura.htb\hwilliam' '\\\\172.16.119.11\\C$' -p 'dealer-screwed-gym1'
[proxychains] config file found: /etc/proxychains.conf
[proxychains] preloading /usr/lib/x86_64-linux-gnu/libproxychains.so.4
[proxychains] DLL init: proxychains-ng 4.17
do_connect: Connection to  failed (Error NT_STATUS_NOT_FOUND)

┌──(openclaw㉿srv1405873)-[~]
```


## LDAP

```bash
└─$ proxychains ldapdomaindump -u 'nexura.htb\hwilliam' -p 'dealer-screwed-gym1' 172.16.119.11
[proxychains] config file found: /etc/proxychains.conf
[proxychains] preloading /usr/lib/x86_64-linux-gnu/libproxychains.so.4
[proxychains] DLL init: proxychains-ng 4.17
[*] Connecting to host...
[*] Binding to host
[proxychains] Dynamic chain  ...  127.0.0.1:9050  ...  172.16.119.11:389  ...  OK
[+] Bind OK
[*] Starting domain dump
[+] Domain dump finished
```