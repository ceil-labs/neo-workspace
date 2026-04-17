# Section Exercises — Credential Hunting in Network Traffic

**Status:** ⬜ In Progress  
**Exercise File:** `demo.pcapng` (download from module)

---

## Setup

```bash
# Download and extract the pcap file
unzip credential-hunting-in-network-traffic.zip
cd credential-hunting-in-network-traffic/

# Option 1: Analyze with Wireshark
wireshark demo.pcapng &

# Option 2: Analyze with Pcredz
./Pcredz -f demo.pcapng -t -v
```

---

## Analysis Approach

### Wireshark Method

**Step 1 — Identify protocols present:**
```
Statistics → Protocol Hierarchy
```

**Step 2 — Filter for cleartext protocols:**
```
http
ftp
pop
imap
smtp
snmp
telnet
```

**Step 3 — Search for credential patterns:**
```
http contains "pass"
http contains "user"
http.request.method == "POST"
```

**Step 4 — Follow TCP streams for conversations:**
```
Right-click packet → Follow → TCP Stream
```

### Pcredz Method (Automated)

```bash
./Pcredz -f demo.pcapng -t -v
```

**Expected output format:**
```
[Timestamp] protocol: tcp SRC_IP:PORT > DST_IP:PORT
FTP User: username
FTP Pass: password

[Timestamp] protocol: udp SRC_IP:PORT > DST_IP:PORT
Found SNMPv2 Community string: public
```

---

## Questions & Answers

| # | Question | Answer | Status |
|---|----------|--------|--------|
| 1 | What username was sent over HTTP/FTP? | | ⬜ |
| 2 | What password was exposed? | | ⬜ |
| 3 | What SNMP community string is used? | | ⬜ |
| 4 | What protocol had the most credential exposure? | | ⬜ |

---

## Key Findings

(To be filled after analysis)

---

## Lessons Learned

- Wireshark filters for credential hunting
- Pcredz automation advantages
- Which protocols are most likely to expose credentials
- How to quickly triage large pcap files
