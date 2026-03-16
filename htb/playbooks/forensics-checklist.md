# Forensics Checklist

Systematic approach to forensic analysis.

## Disk/Memory Analysis

### Acquisition
- [ ] Verify integrity (hashes)
- [ ] Document chain of custody
- [ ] Note acquisition method and tools

### Initial Triage
- [ ] OS version and patch level
- [ ] User accounts
- [ ] Running processes at time of capture
- [ ] Network connections

### Analysis Areas

#### Filesystem
- [ ] Deleted files (file carving)
- [ ] Timeline analysis (MAC times)
- [ ] Suspicious files in temp directories
- [ ] Browser history and downloads
- [ ] Recently accessed files

#### Registry (Windows)
- [ ] Run keys (persistence)
- [ ] Shim cache
- [ ] Amcache
- [ ] UserAssist
- [ ] RecentDocs

#### Memory
- [ ] Process list and relationships
- [ ] Network connections
- [ ] Loaded DLLs
- [ ] Command history
- [ ] Credentials in memory

#### Logs
- [ ] System logs
- [ ] Security logs
- [ ] Application logs
- [ ] PowerShell history

## Network Forensics

### PCAP Analysis
- [ ] Protocol distribution
- [ ] Large transfers
- [ ] Suspicious ports/destinations
- [ ] DNS queries
- [ ] HTTP requests (User-Agent, URI patterns)

### Indicators of Compromise (IOCs)
- [ ] IP addresses
- [ ] Domain names
- [ ] File hashes (MD5, SHA1, SHA256)
- [ ] Registry keys
- [ ] File paths

## Timeline Construction

1. First malicious activity
2. Initial access vector
3. Persistence established
4. Lateral movement
5. Data staging/exfiltration
6. Evidence of cleanup

## Tools

### Disk/Memory
- Autopsy
- Volatility
- Rekall
- FTK Imager

### Network
- Wireshark
- Zeek
- NetworkMiner

### Log Analysis
- Splunk
- ELK Stack
- Graylog
