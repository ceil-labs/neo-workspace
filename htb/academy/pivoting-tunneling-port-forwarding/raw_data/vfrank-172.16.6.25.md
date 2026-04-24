# vfrank - 172.16.6.25

Initial enum:

```powershell
c:\>whoami /all

USER INFORMATION
----------------

User Name            SID
==================== =============================================
inlanefreight\vfrank S-1-5-21-3858284412-1730064152-742000644-1103


GROUP INFORMATION
-----------------

Group Name                                           Type             SID                                          Attributes
==================================================== ================ ============================================ ===============================================================
Everyone                                             Well-known group S-1-1-0                                      Mandatory group, Enabled by default, Enabled group
BUILTIN\Users                                        Alias            S-1-5-32-545                                 Mandatory group, Enabled by default, Enabled group
BUILTIN\Administrators                               Alias            S-1-5-32-544                                 Mandatory group, Enabled by default, Enabled group, Group owner
NT AUTHORITY\REMOTE INTERACTIVE LOGON                Well-known group S-1-5-14                                     Mandatory group, Enabled by default, Enabled group
NT AUTHORITY\INTERACTIVE                             Well-known group S-1-5-4                                      Mandatory group, Enabled by default, Enabled group
NT AUTHORITY\Authenticated Users                     Well-known group S-1-5-11                                     Mandatory group, Enabled by default, Enabled group
NT AUTHORITY\This Organization                       Well-known group S-1-5-15                                     Mandatory group, Enabled by default, Enabled group
LOCAL                                                Well-known group S-1-2-0                                      Mandatory group, Enabled by default, Enabled group
INLANEFREIGHT\Domain Admins                          Group            S-1-5-21-3858284412-1730064152-742000644-512 Mandatory group, Enabled by default, Enabled group
Authentication authority asserted identity           Well-known group S-1-18-1                                     Mandatory group, Enabled by default, Enabled group
INLANEFREIGHT\Denied RODC Password Replication Group Alias            S-1-5-21-3858284412-1730064152-742000644-572 Mandatory group, Enabled by default, Enabled group, Local Group
Mandatory Label\High Mandatory Level                 Label            S-1-16-12288


PRIVILEGES INFORMATION
----------------------

Privilege Name                            Description                                                        State
========================================= ================================================================== ========
SeIncreaseQuotaPrivilege                  Adjust memory quotas for a process                                 Disabled
SeSecurityPrivilege                       Manage auditing and security log                                   Disabled
SeTakeOwnershipPrivilege                  Take ownership of files or other objects                           Disabled
SeLoadDriverPrivilege                     Load and unload device drivers                                     Disabled
SeSystemProfilePrivilege                  Profile system performance                                         Disabled
SeSystemtimePrivilege                     Change the system time                                             Disabled
SeProfileSingleProcessPrivilege           Profile single process                                             Disabled
SeIncreaseBasePriorityPrivilege           Increase scheduling priority                                       Disabled
SeCreatePagefilePrivilege                 Create a pagefile                                                  Disabled
SeBackupPrivilege                         Back up files and directories                                      Disabled
SeRestorePrivilege                        Restore files and directories                                      Disabled
SeShutdownPrivilege                       Shut down the system                                               Disabled
SeDebugPrivilege                          Debug programs                                                     Disabled
SeAuditPrivilege                          Generate security audits                                           Disabled
SeSystemEnvironmentPrivilege              Modify firmware environment values                                 Disabled
SeChangeNotifyPrivilege                   Bypass traverse checking                                           Enabled
SeRemoteShutdownPrivilege                 Force shutdown from a remote system                                Disabled
SeUndockPrivilege                         Remove computer from docking station                               Disabled
SeManageVolumePrivilege                   Perform volume maintenance tasks                                   Disabled
SeImpersonatePrivilege                    Impersonate a client after authentication                          Enabled
SeCreateGlobalPrivilege                   Create global objects                                              Enabled
SeIncreaseWorkingSetPrivilege             Increase a process working set                                     Disabled
SeTimeZonePrivilege                       Change the time zone                                               Disabled
SeCreateSymbolicLinkPrivilege             Create symbolic links                                              Disabled
SeDelegateSessionUserImpersonatePrivilege Obtain an impersonation token for another user in the same session Disabled


USER CLAIMS INFORMATION
-----------------------

User claims unknown.

Kerberos support for Dynamic Access Control on this device has been disabled.
```

Check network. It's dual home as well

```
c:\Users>ipconfig /all

Windows IP Configuration

   Host Name . . . . . . . . . . . . : PIVOTWIN10
   Primary Dns Suffix  . . . . . . . : INLANEFREIGHT.LOCAL
   Node Type . . . . . . . . . . . . : Hybrid
   IP Routing Enabled. . . . . . . . : No
   WINS Proxy Enabled. . . . . . . . : No
   DNS Suffix Search List. . . . . . : INLANEFREIGHT.LOCAL

Ethernet adapter Ethernet0 2:

   Connection-specific DNS Suffix  . :
   Description . . . . . . . . . . . : vmxnet3 Ethernet Adapter
   Physical Address. . . . . . . . . : 00-50-56-8A-CF-06
   DHCP Enabled. . . . . . . . . . . : No
   Autoconfiguration Enabled . . . . : Yes
   Link-local IPv6 Address . . . . . : fe80::24e0:2414:531f:f10%9(Preferred)
   IPv4 Address. . . . . . . . . . . : 172.16.6.25(Preferred)
   Subnet Mask . . . . . . . . . . . : 255.255.0.0
   Default Gateway . . . . . . . . . : 172.16.6.1
   DHCPv6 IAID . . . . . . . . . . . : 117461078
   DHCPv6 Client DUID. . . . . . . . : 00-01-00-01-31-7C-5C-61-00-50-56-B9-E0-46
   DNS Servers . . . . . . . . . . . : 172.16.10.5
                                       127.0.0.1
   NetBIOS over Tcpip. . . . . . . . : Enabled

Ethernet adapter Ethernet1 2:

   Connection-specific DNS Suffix  . :
   Description . . . . . . . . . . . : vmxnet3 Ethernet Adapter #2
   Physical Address. . . . . . . . . : 00-50-56-8A-08-CF
   DHCP Enabled. . . . . . . . . . . : No
   Autoconfiguration Enabled . . . . : Yes
   Link-local IPv6 Address . . . . . : fe80::dd7a:62aa:cb97:f8d0%4(Preferred)
   IPv4 Address. . . . . . . . . . . : 172.16.10.25(Preferred)
   Subnet Mask . . . . . . . . . . . : 255.255.0.0
   Default Gateway . . . . . . . . . :
   DHCPv6 IAID . . . . . . . . . . . : 335564886
   DHCPv6 Client DUID. . . . . . . . : 00-01-00-01-31-7C-5C-61-00-50-56-B9-E0-46
   DNS Servers . . . . . . . . . . . : 172.16.10.5
                                       127.0.0.1
   NetBIOS over Tcpip. . . . . . . . : Enabled
```

Got access to DC at 172.16.10.5 using `vfrank` creds since it's part the `DOMAIN ADMINS` group

```
PS C:\Windows\system32> Enter-PSSession -ComputerName ACADEMY-PIVOT-D -Credential (Get-Credential)

cmdlet Get-Credential at command pipeline position 1
Supply values for the following parameters:
Credential
[ACADEMY-PIVOT-D]: PS C:\Users\vfrank\Documents> dir
[ACADEMY-PIVOT-D]: PS C:\Users\vfrank\Documents> cd ..
[ACADEMY-PIVOT-D]: PS C:\Users\vfrank> cd ..
[ACADEMY-PIVOT-D]: PS C:\Users> cd ..
[ACADEMY-PIVOT-D]: PS C:\> dir


    Directory: C:\


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d-----        9/15/2018  12:12 AM                PerfLogs
d-r---       12/14/2020   6:43 PM                Program Files
d-----        9/15/2018  12:21 AM                Program Files (x86)
d-r---        4/23/2026   6:59 PM                Users
d-----         5/3/2022  10:09 AM                Windows
-a----        5/18/2022   1:33 PM             20 Flag.txt.txt


[ACADEMY-PIVOT-D]: PS C:\> type .\Flag.txt.txt
3nd-0xf-Th3-R@inbow!
[ACADEMY-PIVOT-D]: PS C:\>
```
