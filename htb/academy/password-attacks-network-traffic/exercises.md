# Exercises — Credential Hunting in Network Traffic

---

## Section: Unencrypted Protocols Overview

### Exercise 1
**Question:** What is the encrypted counterpart to HTTP?  
**Answer:** HTTPS  
**Explanation:** HTTPS uses TLS/SSL to encrypt web traffic, protecting credentials and data in transit.

---

### Exercise 2
**Question:** Which protocol is used for managing network devices like routers and switches, and what is its encrypted version?  
**Answer:** SNMP (unencrypted) / SNMPv3 with encryption  
**Explanation:** SNMPv3 added encryption and authentication to the previously cleartext SNMP protocol.

---

### Exercise 3
**Question:** What port does unencrypted FTP use?  
**Answer:** 21 (control channel) and 20 (data channel)  
**Explanation:** FTP uses separate ports for control commands and data transfer, both unencrypted by default.

---

## Section: Wireshark Analysis

### Exercise 1
**Question:** What Wireshark filter shows only HTTP traffic?  
**Answer:** `http`  
**Explanation:** Protocol filter to isolate web traffic for analysis.

---

### Exercise 2
**Question:** What filter shows HTTP POST requests specifically?  
**Answer:** `http.request.method == "POST"`  
**Explanation:** POST requests often contain form data including usernames and passwords in cleartext HTTP.

---

### Exercise 3
**Question:** How do you filter for packets containing the string "passw"?  
**Answer:** `http contains "passw"`  
**Explanation:** Searches packet payloads for partial string matches — useful for finding password fields.

---

### Exercise 4
**Question:** What filter isolates traffic between two specific IPs?  
**Answer:** `ip.src == 192.168.1.1 && ip.dst == 10.0.0.1`  
**Explanation:** Combines source and destination filters with AND logic.

---

### Exercise 5
**Question:** How do you view a specific TCP conversation/stream?  
**Answer:** `tcp.stream eq 0` (or any stream number)  
**Explanation:** Follows a complete TCP session between two hosts.

---

## Section: Pcredz Automation

### Exercise 1
**Question:** What types of credentials can Pcredz extract from network traffic?  
**Answer:**  
- Credit card numbers
- POP/IMAP/SMTP/FTP credentials
- SNMP community strings
- HTTP NTLM/Basic auth credentials
- NTLMv1/v2 hashes (DCE-RPC, SMB, LDAP, MSSQL, HTTP)
- Kerberos AS-REQ hashes

**Explanation:** Pcredz automates extraction of credentials from multiple protocols in pcap files.

---

### Exercise 2
**Question:** What command runs Pcredz against a pcap file?  
**Answer:** `./Pcredz -f capture.pcapng -t -v`  
**Explanation:** `-f` specifies file, `-t` enables timestamp, `-v` enables verbose output.

---

## Section: Practical Analysis (demo.pcapng)

### Exercise 1
**Question:** What protocol is carrying credentials in the demo.pcapng?  
**Answer:** (To be determined from analysis)  
**Approach:** Use `http` filter in Wireshark or run `Pcredz -f demo.pcapng`

---

### Exercise 2
**Question:** What username and password can be extracted?  
**Answer:** (To be determined from analysis)  
**Approach:** Look for POST requests with form data, or check Pcredz output for FTP/HTTP auth

---

### Exercise 3
**Question:** What SNMP community string is visible?  
**Answer:** (To be determined from analysis)  
**Approach:** Filter `snmp` in Wireshark or check Pcredz output

---

### Exercise 4
**Question:** What FTP credentials are exposed?  
**Answer:** (To be determined from analysis)  
**Approach:** Filter `ftp` in Wireshark — look for USER and PASS commands
