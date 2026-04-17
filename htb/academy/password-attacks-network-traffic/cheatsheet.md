# Cheatsheet — Credential Hunting in Network Traffic

## Unencrypted Protocols & Ports

| Protocol | Port(s) | Encrypted Version | Risk Level |
|----------|---------|-------------------|------------|
| HTTP | 80 | HTTPS (443) | 🔴 High |
| FTP | 21/20 | FTPS/SFTP | 🔴 High |
| Telnet | 23 | SSH (22) | 🔴 High |
| POP3 | 110 | POP3S (995) | 🔴 High |
| IMAP | 143 | IMAPS (993) | 🔴 High |
| SMTP | 25/587 | SMTPS (465) | 🔴 High |
| LDAP | 389 | LDAPS (636) | 🔴 High |
| SNMP | 161/162 | SNMPv3 | 🟡 Medium |
| DNS | 53 | DoH/DoT | 🟡 Medium |
| SMB | 445 | SMB 3.0+ | 🟡 Medium |

---

## Wireshark Filters for Credential Hunting

### Protocol Filters
```bash
http                    # HTTP traffic only
ftp                     # FTP commands and data
pop                     # POP3 email retrieval
imap                    # IMAP email access
smtp                    # SMTP email sending
snmp                    # SNMP management traffic
telnet                  # Telnet sessions
ldap                    # LDAP directory queries
```

### Content Search Filters
```bash
# Search for password-related strings
http contains "pass"
http contains "password"
http contains "pwd"

# Search for authentication
http contains "auth"
http contains "login"
http contains "user"

# Case insensitive search (use matches with regex)
http matches "(?i)password"
```

### Specific Request Types
```bash
http.request.method == "POST"     # Form submissions (often have creds)
http.request.method == "GET"      # Query parameters may have creds
http.request.uri contains "login" # Login page requests
```

### IP and Port Filtering
```bash
# Specific IP
ip.addr == 192.168.1.100

# IP range
ip.src >= 192.168.1.0 && ip.src <= 192.168.1.255

# Specific port
tcp.port == 21      # FTP
tcp.port == 23      # Telnet
tcp.port == 80      # HTTP
udp.port == 161     # SNMP

# Between two hosts
ip.src == 192.168.1.1 && ip.dst == 10.0.0.1
```

### TCP Stream Analysis
```bash
# Specific stream
tcp.stream eq 0

# Show only SYN packets (new connections)
tcp.flags.syn == 1 && tcp.flags.ack == 0

# Follow a conversation
# Right-click → Follow → TCP Stream
```

### MAC Address Filtering
```bash
eth.addr == 00:11:22:33:44:55
eth.src == 00:11:22:33:44:55
eth.dst == 00:11:22:33:44:55
```

---

## Pcredz Commands

### Basic Usage
```bash
# Analyze pcap file
./Pcredz -f capture.pcapng

# With timestamps and verbose output
./Pcredz -f capture.pcapng -t -v

# Live capture on interface
sudo ./Pcredz -i eth0
```

### What Pcredz Extracts

| Credential Type | Protocols |
|-----------------|-----------|
| HTTP Basic Auth | HTTP |
| HTTP Forms | HTTP |
| NTLM Hashes | HTTP, SMB, LDAP, MSSQL, RPC |
| Kerberos AS-REQ | Kerberos |
| FTP Credentials | FTP |
| POP/IMAP/SMTP | Email protocols |
| SNMP Strings | SNMP |
| Credit Cards | Any cleartext |

---

## Manual Extraction Techniques

### HTTP Basic Authentication
```
Look for: Authorization: Basic base64(username:password)
Decode: echo "dXNlcjpwYXNz" | base64 -d
```

### FTP Credentials
```
Filter: ftp
Look for:
- USER username
- PASS password
```

### Telnet Sessions
```
Filter: telnet
Follow TCP stream to see entire session including login
```

### SNMP Community Strings
```
Filter: snmp
Look for:
- community string in clear (often "public" or "private")
```

---

## Analysis Workflow

**Quick Triaging Large Pcaps:**
```bash
# 1. Check what protocols are present
wireshark -r capture.pcapng -q -z io,phs

# 2. Run automated extraction
./Pcredz -f capture.pcapng -t -v | tee results.txt

# 3. Manual deep dive on interesting streams
wireshark capture.pcapng
# → Apply filters based on Pcredz findings
```

**From Live Capture:**
```bash
# Capture with tcpdump
tcpdump -i eth0 -w capture.pcapng -s0

# Analyze in real-time with Pcredz
sudo ./Pcredz -i eth0
```

---

## References

- Wireshark Display Filters: https://wiki.wireshark.org/DisplayFilters
- Pcredz GitHub: https://github.com/lgandx/PCredz
- MITRE ATT&CK: T1040 (Network Sniffing)
