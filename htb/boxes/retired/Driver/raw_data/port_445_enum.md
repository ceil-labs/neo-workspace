# Port 445 Enumeration

* Guest access doesn't seem to work

```bash
└─$ smbclient -L //driver.htb -N
session setup failed: NT_STATUS_ACCESS_DENIED

┌──(openclaw㉿srv1405873)-[~/.openclaw/workspace-neo/htb/boxes/active/Driver/raw_data]
└─$ smbclient -L //10.129.95.238 -N
session setup failed: NT_STATUS_ACCESS_DENIED

┌──(openclaw㉿srv1405873)-[~/.openclaw/workspace-neo/htb/boxes/active/Driver/raw_data]
└─$ smbclient -L //10.129.95.238 -U ''
Password for [WORKGROUP\]:
session setup failed: NT_STATUS_LOGON_FAILURE

┌──(openclaw㉿srv1405873)-[~/.openclaw/workspace-neo/htb/boxes/active/Driver/raw_data]
└─$ smbclient -L //10.129.95.238 -U guest
Password for [WORKGROUP\guest]:
session setup failed: NT_STATUS_LOGON_FAILURE

┌──(openclaw㉿srv1405873)-[~/.openclaw/workspace-neo/htb/boxes/active/Driver/raw_data]
└─$ smbclient -L //10.129.95.238 -U anonymous
Password for [WORKGROUP\anonymous]:
session setup failed: NT_STATUS_LOGON_FAILURE
```