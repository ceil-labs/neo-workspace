# Password Attacks: Credential Hunting in Network Traffic

**Module:** Password Attacks — HTB Academy  
**Focus:** Identifying exposed credentials in plaintext network traffic  
**Assessment:** ❌ Not Started (Section Exercises Only)

---

## Sections

| # | Section | Status |
|---|---------|--------|
| 1 | Credential Hunting in Network Traffic | ✅ |
| 2 | Wireshark | ✅ |
| 3 | Pcredz | ✅ |
| 4 | Exercise | ⏳ |

---

## Key Concepts

### Why Hunt in Network Traffic?
Most applications use TLS to encrypt data in transit, but **legacy systems, misconfigured services, or test applications** launched without HTTPS can expose credentials in plaintext.

### Protocol Encryption Overview

| Unencrypted | Encrypted | Description |
|------------|----------|-------------|
| HTTP | HTTPS | Web pages and resources |
| FTP | FTPS/SFTP | File transfers |
| SNMP | SNMPv3 | Network device management |
| POP3 | POP3S | Email retrieval |
| IMAP | IMAPS | Server-side email management |
| SMTP | SMTPS | Email relay |
| LDAP | LDAPS | Directory services |
| RDP | RDP + TLS | Remote desktop |
| DNS | DoH | Name resolution |
| SMB | SMB over TLS | Network file/printer sharing |
| VNC | VNC + TLS/SSL | Graphical remote control |

---

## Tools Introduced

### Wireshark
Powerful packet analyzer with display filter engine.

**Useful Filters:**
| Filter | Description |
|--------|-------------|
| `ip.addr == X.X.X.X` | Filter by IP address |
| `tcp.port == 80` | Filter by port |
| `http` | HTTP traffic |
| `dns` | DNS traffic |
| `tcp.flags.syn == 1 && tcp.flags.ack == 0` | SYN packets (scanning detection) |
| `icmp` | ICMP/Ping traffic |
| `http.request.method == "POST"` | HTTP POST (often contains passwords) |
| `tcp.stream eq 53` | Specific TCP stream |
| `eth.addr == 00:11:22:33:44:55` | MAC address filter |
| `ip.src == X && ip.dst == Y` | Source→destination filter |
| `http contains "passw"` | String search in HTTP packets |

**Search for credentials in packets:** `Edit > Find Packet` → search for `"passw"` or similar strings.

### Pcredz
Tool for extracting credentials from live traffic or PCAP files.

**Supports:**
- Credit card numbers
- POP/SMTP/IMAP credentials
- SNMP community strings
- FTP credentials
- HTTP NTLM/Basic headers + HTTP Forms
- NTLMv1/v2 hashes (DCE-RPC, SMB, LDAP, MSSQL, HTTP)
- Kerberos (AS-REQ Pre-Auth etype 23) hashes

**Usage:**
```bash
# From pcap file
./Pcredz -f demo.pcapng -t -v

# From live interface
sudo ./Pcredz -i eth0 -v
```

---

## Exercise

**Task:** Download the attached `credential-hunting-in-network-traffic` archive and extract `demo.pcapng`. Use Wireshark or PCredz to answer the questions.

**Tools needed:** Wireshark or PCredz

---

## Key Takeaways

1. Legacy/unencrypted protocols still exist in many environments
2. Wireshark filters enable fast credential hunting in large captures
3. `http contains "passw"` is a quick way to find plaintext passwords
4. Pcredz automates credential extraction from PCAP files at scale
5. NTLM/Basic auth headers in HTTP are high-value targets
