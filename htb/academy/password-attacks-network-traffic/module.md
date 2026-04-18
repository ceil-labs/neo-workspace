# Password Attacks: Credential Hunting in Network Traffic

**Module Path:** HTB Academy / Password Attacks / Credential Hunting in Network Traffic  
**Assessment:** Section Exercises  
**Date Started:** 2026-04-17

---

## Questions
1. The packet capture contains cleartext credit card information. What is the number that was transmitted? 5156 8829 4478 9834
2. What is the SNMPv2 community string that was used? s3cr3tSNMPC0mmun1ty
3. What is the password of the user who logged into FTP? qwerty123
4. What file did the user download over FTP? creds.txt

## Sections

| # | Section | Status | Notes |
|---|---------|--------|-------|
| 1 | Unencrypted Protocols Overview | ⬜ | HTTP, FTP, SNMP, POP3, IMAP, SMTP, LDAP, etc. |
| 2 | Wireshark Analysis | ⬜ | Filters, packet inspection, credential extraction |
| 3 | Pcredz Automation | ⬜ | Automated credential extraction from pcaps |
| 4 | Section Exercises | ⬜ | demo.pcapng analysis |

---

## Key Concepts

### Unencrypted vs Encrypted Protocols

| Unencrypted | Encrypted | Purpose |
|-------------|-----------|---------|
| HTTP | HTTPS | Web pages and resources |
| FTP | FTPS/SFTP | File transfers |
| SNMP | SNMPv3 | Network device management |
| POP3 | POP3S | Email retrieval |
| IMAP | IMAPS | Email access |
| SMTP | SMTPS | Email sending |
| LDAP | LDAPS | Directory services |
| RDP | RDP+TLS | Remote desktop |
| DNS | DoH/DoT | Domain resolution |
| SMB | SMB 3.0+ | File sharing |
| VNC | VNC+TLS | Remote control |

### Why Hunt Network Traffic?

- Legacy systems without TLS
- Misconfigured services
- Test environments
- Internal networks with "trusted" assumptions
- Cleartext credential transmission

---

## Tools Introduced

| Tool | Purpose |
|------|---------|
| **Wireshark** | Packet analysis, manual credential hunting |
| **Pcredz** | Automated credential extraction from pcaps |

---

## Gaps / Follow-up

- [ ] Practice with more Wireshark filters
- [ ] Analyze real-world pcap samples
- [ ] Compare Wireshark manual vs Pcredz automated approaches
