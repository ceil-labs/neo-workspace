---
name: htb-proxy
description: Set up temporary HTTP proxy from VPS to HTB box. Supports multiple target ports and pass-through Host headers for vhost enumeration.
---

# htb-proxy

Ephemeral HTTP proxy for HTB boxes. Exposes a local port on your VPS (accessible via Tailscale) that forwards to the HTB machine.

**Key Features:**
- **Configurable target port:** Proxy to any port on the HTB box (80, 8080, 3000, etc.)
- **Multiple proxies per box:** Run separate proxies for different services on the same target
- **Pass-through Host headers:** Supports vhost/subdomain enumeration
- **Full lifecycle management:** Start, stop, and list all active proxies

## Quick Start

```bash
# Basic proxy to port 80
openclaw skills run htb-proxy up Devvortex 10.129.190.60

# Proxy to alternate port
openclaw skills run htb-proxy up Devvortex 10.129.190.60 --target-port 8080

# Check status
openclaw skills run htb-proxy status

# Stop proxy
openclaw skills run htb-proxy down Devvortex
```

## Commands

### `up` - Start a proxy

```bash
htb-proxy.sh up <box-name> <htb-ip> [options]
```

**Options:**
| Option | Description | Default |
|--------|-------------|---------|
| `--target-port <port>` | Target port on HTB box | 80 |
| `--ssl` | Enable HTTPS proxying (VPS cert + HTTPS upstream) | HTTP only |
| `--port <port>` | Specific VPS port to use | Auto (8080-8099) |
| `--host <hostname>` | Fixed Host header | Pass-through |
| `--pass-through` | Preserve client Host header | Enabled |

**Examples:**
```bash
# Port 80 (default)
htb-proxy.sh up Devvortex 10.129.190.60

# HTTPS proxy to port 443 (full HTTPS on VPS side)
htb-proxy.sh up Paper 10.129.136.31 --target-port 443 --ssl

# HTTPS proxy with fixed Host header (common for HTB web apps)
htb-proxy.sh up Paper 10.129.136.31 --target-port 443 --ssl --host paper.htb

# Port 8080
htb-proxy.sh up Devvortex 10.129.190.60 --target-port 8080

# Multiple services on same box
htb-proxy.sh up Devvortex 10.129.190.60              # port 80
htb-proxy.sh up Devvortex-admin 10.129.190.60 --target-port 8080
htb-proxy.sh up Devvortex-api 10.129.190.60 --target-port 3000

# Fixed Host header (no pass-through)
htb-proxy.sh up Devvortex 10.129.190.60 --host devvortex.htb
```

### `down` - Stop a proxy

```bash
htb-proxy.sh down <box-name>
```

Stops the proxy and releases all resources (port, files, process).

**Example:**
```bash
htb-proxy.sh down Devvortex
htb-proxy.sh down Devvortex-admin
```

### `status` - List active proxies

```bash
htb-proxy.sh status
```

Shows all running proxies with their target IPs, ports, and VPS ports.

**Example output:**
```
Active HTB Proxies
==================

  Devvortex
    Target: 10.129.190.60:80
    VPS Port: 8080
    Mode: pass-through
    Status: running (PID: 12345)

  Devvortex-admin
    Target: 10.129.190.60:8080
    VPS Port: 8081
    Mode: pass-through
    Status: running (PID: 12346)
```

## HTTPS Proxying (`--ssl`)

Use `--ssl` when the target service on the HTB box uses HTTPS (e.g., port 443). This enables:

1. **HTTPS on the VPS side** — Caddy generates a self-signed certificate (`tls internal`) so your browser connects over TLS to the proxy
2. **HTTPS upstream** — Caddy connects to the HTB box using `https://` with `tls_insecure_skip_verify` (HTB boxes use self-signed certs)

```bash
# HTTPS proxy to port 443 with pass-through Host
htb-proxy.sh up Paper 10.129.136.31 --target-port 443 --ssl

# HTTPS proxy with fixed Host header
htb-proxy.sh up Paper 10.129.136.31 --target-port 443 --ssl --host paper.htb
```

**Access:**
```bash
# Add to local /etc/hosts
echo "<vps-tailscale-ip> paper.htb" | sudo tee -a /etc/hosts

# Browse — accept the self-signed cert warning in your browser
https://paper.htb:<vps-port>
```

> **Browser certificate warning:** Your browser will warn about the self-signed cert on the VPS side. This is expected — click "Advanced" / "Accept Risk and Continue" to proceed. The traffic is still properly proxied.

## Multiple Ports Per Box

When a box exposes multiple ports, create separate proxies:

```bash
# Start proxies for each port
htb-proxy.sh up Devvortex 10.129.190.60 --target-port 80      # VPS:8080
htb-proxy.sh up Devvortex 10.129.190.60 --target-port 8080    # VPS:8081  
htb-proxy.sh up Devvortex 10.129.190.60 --target-port 3000    # VPS:8082

# Access them via different names in /etc/hosts
echo "100.108.21.107 devvortex.htb dev.devvortex.htb" | sudo tee -a /etc/hosts

# Browse:
# http://devvortex.htb:8080      → HTB:80
# http://devvortex.htb:8081      → HTB:8080
# http://devvortex.htb:8082      → HTB:3000

# Cleanup when done
htb-proxy.sh down Devvortex	htb-proxy.sh down Devvortex-admin
```

## Host Header Modes

### Pass-through (default)
Preserves the original Host header from your browser:
```bash
htb-proxy.sh up Devvortex 10.129.190.60
```
- Browse to `dev.devvortex.htb:8080` → forwards `Host: dev.devvortex.htb`
- Browse to `devvortex.htb:8080` → forwards `Host: devvortex.htb`
- **Use for:** Vhost enumeration, accessing subdomains

### Fixed Host
Forces a specific Host header for all requests:
```bash
htb-proxy.sh up Devvortex 10.129.190.60 --host devvortex.htb
```
- Any request gets `Host: devvortex.htb` regardless of URL
- **Use for:** Simple forwarding when you know the target vhost

## Access Patterns

### Pattern 1: Local /etc/hosts (Recommended)
```bash
# On your laptop
sudo echo "<vps-tailscale-ip> devvortex.htb dev.devvortex.htb" >> /etc/hosts

# Browse normally
firefox http://dev.devvortex.htb:8080
```

### Pattern 2: Direct curl with Host header
```bash
curl -H "Host: dev.devvortex.htb" http://<vps-tailscale-ip>:8080
```

### Pattern 3: Vhost enumeration through proxy
```bash
# With pass-through mode, ffuf/gobuster can test subdomains:
ffuf -w subdomains.txt -u http://devvortex.htb:8080 -H 'Host: FUZZ.devvortex.htb'
```

## File Locations

Per-box files in `~/.openclaw/workspace-neo/htb/proxy/`:
- `<box>.Caddyfile` — Caddy configuration
- `<box>.port` — Assigned VPS port
- `<box>.pid` — Process ID
- `<box>.conf` — Settings (target IP/port, mode)
- `<box>.log` — Caddy stdout/stderr
- `<box>.access.log` — HTTP access logs

## Requirements

- Caddy installed on VPS
- Tailscale running on VPS
- `/etc/hosts` entries on your local machine for domain-based access

## Limitations

- VPS port range: 8080-8099 (max ~20 concurrent proxies)
- One Caddy process per proxy (lightweight, but not infinite scale)
- In `--ssl` mode, your browser will show a certificate warning for the self-signed VPS-side cert — this is expected and safe to accept

## Why Caddy

- Single binary, no dependencies
- Clean config syntax
- Flexible header manipulation
- Graceful shutdowns

## Cleanup

Always tear down proxies when done:
```bash
htb-proxy.sh down <box-name>
```

Or stop all at once:
```bash
htb-proxy.sh status | grep "running" | while read line; do
    box=$(echo "$line" | awk '{print $1}')
    htb-proxy.sh down "$box"
done
```
