# Skills Assessment

## Context
> A team member started a Penetration Test against the Inlanefreight environment but was moved to another project. They left a **web shell** in place for us to continue. We need to leverage the web shell to enumerate hosts, identify services, and pivot through internal networks until we reach the **Inlanefreight Domain Controller**.

## Objectives
- [ ] Access the first system via the web shell
- [ ] Enumerate and pivot to an internal host
- [ ] Continue pivoting until reaching the Domain Controller
- [ ] Capture all flags along the way
- [ ] Use any data, credentials, scripts found in the environment

## Starting Point
- **External Access:** Web shell at `10.129.229.129`
- **Target Environment:** Inlanefreight internal network
- **Goal:** Domain Controller flag

## Target Map

```
[External]
    |
    v
[10.129.229.129] ← Web Shell (starting point)
    |
    v
[Internal Hosts] ← Pivot target #1
    |
    v
[Domain Controller] ← Final target / Flag
```

## Recon

### Web Shell Access
- **URL:** `http://10.129.229.129/...` (path TBD)
- **Type:** PHP web shell (left by previous team member)
- **Next Steps:** Identify web shell parameters, test command execution

### Tools to Try
- `whoami` — current user context
- `ipconfig` / `ifconfig` — network interfaces
- `netstat -an` — listening ports / connections
- `systeminfo` — OS info
- `tasklist` — running processes
- `net users` / `net localgroup administrators` — local accounts
- `type C:\Users\*\flag.txt` — look for flags

## Exploitation

### Phase 1: Web Shell Enumeration
```bash
# Test web shell — find the correct parameter
curl "http://10.129.229.129/shell.php?cmd=whoami"
```

### Phase 2: Network Discovery
```bash
# From web shell — identify internal network ranges
ipconfig
route print
arp -a
```

### Phase 3: Pivot Setup
```bash
# Options based on what we find:
# 1. Chisel (reverse tunnel)
# 2. Ligolo-ng (if we can upload agent)
# 3. Plink / SSH tunnel (if SSH keys found)
# 4. Built-in Windows tools (netsh, portproxy)
```

## Flags
| Host | Location | Flag | Status |
|------|----------|------|--------|
| 10.129.229.129 | Web shell host | HTB{...} | ⏳ Pending |
| Internal host | TBD | HTB{...} | ⏳ Pending |
| Domain Controller | Final target | HTB{...} | ⏳ Pending |

## Credentials Discovered
| Account | Password | Source | Valid On |
|---------|----------|--------|----------|
| TBD | TBD | TBD | TBD |

## Pivot Map
```
[External Attacker]
    |
    | HTTP → Web Shell
    v
[10.129.229.129] — Initial foothold
    |
    | ??? (tunnel/pivot)
    v
[Internal Network]
    |
    | ???
    v
[Domain Controller] — Final target
```

## Lessons Learned
- TBD

---

*Started: 2026-04-23*
*Status: 🔄 IN PROGRESS — Web shell enumeration starting*