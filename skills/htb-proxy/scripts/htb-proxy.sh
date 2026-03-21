#!/bin/bash
# htb-proxy.sh - Manage ephemeral Caddy proxies for HTB boxes
# Usage: ./htb-proxy.sh up|down|status <box-name> [options]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_DIR="$HOME/.openclaw/workspace-neo/htb/proxy"
CADDY_BASE_PORT=8080
CADDY_MAX_PORT=8099

# Ensure proxy directory exists
mkdir -p "$PROXY_DIR"

# Function: Show usage
show_usage() {
    cat << 'EOF'
Usage: htb-proxy.sh <command> [options]

Commands:
  up <box-name> <htb-ip> [options]   - Start proxy for box
  down <box-name>                    - Stop and cleanup proxy
  status                             - Show all active proxies

Options for 'up':
  --target-port <port>  - Target port on HTB box (default: 80)
  --ssl                 - Use HTTPS proxying (enables TLS on VPS + upstream)
  --host <hostname>     - Set specific Host header (default: pass-through)
  --pass-through        - Pass original Host header from client (default)
  --port <port>         - Specific local VPS port (auto-assigned if omitted)

Examples:
  # Basic proxy to port 80 (HTTP)
  htb-proxy.sh up Devvortex 10.129.190.60

  # HTTPS proxy to port 443 (full HTTPS on VPS side)
  htb-proxy.sh up Devvortex 10.129.190.60 --target-port 443 --ssl

  # Proxy to alternate port
  htb-proxy.sh up Devvortex 10.129.190.60 --target-port 8080

  # Multiple proxies for same box (different ports)
  htb-proxy.sh up Devvortex 10.129.190.60              # port 80
  htb-proxy.sh up Devvortex-admin 10.129.190.60 --target-port 8080
  htb-proxy.sh up Devvortex-api 10.129.190.60 --target-port 3000

  # Force specific Host header
  htb-proxy.sh up Devvortex 10.129.190.60 --host devvortex.htb

  # HTTPS proxy with fixed Host (HTB box uses self-signed cert)
  htb-proxy.sh up Paper 10.129.136.31 --target-port 443 --ssl --host paper.htb

  # Cleanup
  htb-proxy.sh down Devvortex
  htb-proxy.sh down Devvortex-admin

  # Check status
  htb-proxy.sh status

Access Pattern:
  Once running, add to local /etc/hosts:
    <vps-tailscale-ip> devvortex.htb
  
  HTTP:  http://devvortex.htb:<vps-port>
  HTTPS: https://devvortex.htb:<vps-port>  (--ssl mode only)

  Note: In --ssl mode your browser will show a certificate warning
  because Caddy uses a self-signed cert on the VPS side. This is
  expected — accept it to proceed.
EOF
}

# Function: Get next available port
get_available_port() {
    local box_name="$1"
    
    # Check if this box already has a port assigned
    if [ -f "$PROXY_DIR/$box_name.port" ]; then
        cat "$PROXY_DIR/$box_name.port"
        return 0
    fi
    
    # Find next available port
    for port in $(seq $CADDY_BASE_PORT $CADDY_MAX_PORT); do
        if ! lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            # Check if port file exists for another box
            local port_in_use=0
            for f in "$PROXY_DIR"/*.$port; do
                [ -e "$f" ] && port_in_use=1 && break
            done
            if [ $port_in_use -eq 0 ]; then
                echo $port
                return 0
            fi
        fi
    done
    
    echo "Error: No available ports in range $CADDY_BASE_PORT-$CADDY_MAX_PORT" >&2
    return 1
}

# Function: Start proxy
start_proxy() {
    local box_name=""
    local htb_ip=""
    local target_port="80"
    local host_header=""
    local force_port=""
    local pass_through=1
    local use_ssl=0
    
    # Parse arguments
    if [ $# -lt 2 ]; then
        echo "Error: Missing required arguments"
        show_usage
        exit 1
    fi
    
    box_name="$1"
    htb_ip="$2"
    shift 2
    
    # Parse options
    while [ $# -gt 0 ]; do
        case "$1" in
            --target-port)
                target_port="$2"
                shift 2
                ;;
            --host)
                host_header="$2"
                pass_through=0
                shift 2
                ;;
            --pass-through)
                pass_through=1
                shift
                ;;
            --port)
                force_port="$2"
                shift 2
                ;;
            --ssl)
                use_ssl=1
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    if [ -z "$box_name" ] || [ -z "$htb_ip" ]; then
        echo "Error: box-name and htb-ip are required"
        show_usage
        exit 1
    fi
    
    local caddyfile="$PROXY_DIR/$box_name.Caddyfile"
    local port_file="$PROXY_DIR/$box_name.port"
    local pid_file="$PROXY_DIR/$box_name.pid"
    local config_file="$PROXY_DIR/$box_name.conf"
    
    # Check if already running
    if [ -f "$port_file" ]; then
        local existing_port
        existing_port=$(cat "$port_file")
        echo "Proxy already running for $box_name on VPS port $existing_port"
        echo "Target: $htb_ip:$target_port"
        echo "Access: http://<vps-tailscale-ip>:$existing_port"
        exit 0
    fi
    
    # Determine VPS port
    local port
    if [ -n "$force_port" ]; then
        port="$force_port"
    else
        port=$(get_available_port "$box_name")
    fi
    
    # Build Caddyfile based on host header mode and SSL flag
    if [ $use_ssl -eq 1 ]; then
        # HTTPS on VPS side, HTTPS to HTB upstream (HTB boxes use self-signed certs)
        # Generate self-signed certificate for the VPS IP
        openssl req -x509 -nodes -days 1 -newkey rsa:2048 \
            -keyout "$PROXY_DIR/$box_name.key" \
            -out "$PROXY_DIR/$box_name.crt" \
            -subj "/CN=htb-proxy" \
            -addext "subjectAltName=IP:0.0.0.0" 2>/dev/null || {
            echo "Warning: Failed to generate self-signed certificate"
        }
        if [ $pass_through -eq 1 ] || [ -z "$host_header" ]; then
            cat > "$caddyfile" << EOF
https://:$port {
    tls $PROXY_DIR/$box_name.crt $PROXY_DIR/$box_name.key
    reverse_proxy https://$htb_ip:$target_port {
        header_up Host {host}
        transport http {
            tls_insecure_skip_verify
        }
    }
    log {
        output file $PROXY_DIR/$box_name.access.log
    }
}
EOF
            echo "mode=pass-through" > "$config_file"
        else
            cat > "$caddyfile" << EOF
https://:$port {
    tls $PROXY_DIR/$box_name.crt $PROXY_DIR/$box_name.key
    reverse_proxy https://$htb_ip:$target_port {
        header_up Host $host_header
        transport http {
            tls_insecure_skip_verify
        }
    }
    log {
        output file $PROXY_DIR/$box_name.access.log
    }
}
EOF
            echo "mode=fixed" > "$config_file"
            echo "host=$host_header" >> "$config_file"
        fi
        echo "ssl=true" >> "$config_file"
    else
        # HTTP proxy (plaintext on VPS side)
        if [ $pass_through -eq 1 ] || [ -z "$host_header" ]; then
            # Pass-through mode (default) - preserves original Host header
            cat > "$caddyfile" << EOF
:$port {
    reverse_proxy $htb_ip:$target_port {
        header_up Host {host}
    }
    log {
        output file $PROXY_DIR/$box_name.access.log
    }
}
EOF
            echo "mode=pass-through" > "$config_file"
        else
            # Fixed Host header mode
            cat > "$caddyfile" << EOF
:$port {
    reverse_proxy $htb_ip:$target_port {
        header_up Host $host_header
    }
    log {
        output file $PROXY_DIR/$box_name.access.log
    }
}
EOF
            echo "mode=fixed" > "$config_file"
            echo "host=$host_header" >> "$config_file"
        fi
        echo "ssl=false" >> "$config_file"
    fi
    
    # Save config
    echo "htb_ip=$htb_ip" >> "$config_file"
    echo "htb_port=$target_port" >> "$config_file"
    echo "vps_port=$port" >> "$config_file"
    
    # Save port assignment
    echo "$port" > "$port_file"
    touch "$PROXY_DIR/$box_name.$port"  # Port lock file
    
    # Start caddy
    nohup caddy run --config "$caddyfile" --adapter caddyfile > "$PROXY_DIR/$box_name.log" 2>&1 &
    local pid=$!

    # Wait for Caddy to fork/daemonize and confirm it's alive
    sleep 2
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "❌ Failed to start proxy. Check log:"
        cat "$PROXY_DIR/$box_name.log"
        rm -f "$port_file" "$PROXY_DIR/$box_name.$port" "$caddyfile" "$config_file"
        exit 1
    fi

    # Only write PID file AFTER confirmed alive
    echo "$pid" > "$pid_file"

    # Success output
    local scheme="http"
    [ $use_ssl -eq 1 ] && scheme="https"

    echo ""
    echo "✅ Proxy active: $box_name"
    echo "   HTB Target: $htb_ip:$target_port"
    echo "   VPS Port:   $port"
    if [ $pass_through -eq 1 ] || [ -z "$host_header" ]; then
        echo "   Host Mode:  Pass-through (preserves client Host header)"
    else
        echo "   Host Mode:  Fixed (Host: $host_header)"
    fi
    if [ $use_ssl -eq 1 ]; then
        echo "   TLS:        Enabled (VPS cert: self-signed internal)"
        echo "   ⚠️  Browser will show a cert warning — accept it to proceed"
    fi
    echo ""
    echo "Setup on your LOCAL machine:"
    echo "   1. Add to /etc/hosts:"
    echo "      <vps-tailscale-ip> <target-domain>"
    echo "   2. Browse: ${scheme}://<target-domain>:$port"
    echo ""
    echo "To stop: htb-proxy.sh down $box_name"
}

# Function: Stop proxy
stop_proxy() {
    local box_name="$1"
    
    if [ -z "$box_name" ]; then
        echo "Usage: htb-proxy.sh down <box-name>"
        exit 1
    fi
    
    local port_file="$PROXY_DIR/$box_name.port"
    local pid_file="$PROXY_DIR/$box_name.pid"
    local caddyfile="$PROXY_DIR/$box_name.Caddyfile"
    local config_file="$PROXY_DIR/$box_name.conf"
    
    if [ ! -f "$port_file" ]; then
        echo "No active proxy found for '$box_name'"
        echo "Run 'htb-proxy.sh status' to see active proxies"
        exit 1
    fi
    
    local port
    port=$(cat "$port_file")
    
    # Get target info for display
    local htb_ip="unknown"
    local htb_port="unknown"
    if [ -f "$config_file" ]; then
        htb_ip=$(grep "^htb_ip=" "$config_file" | cut -d= -f2 || echo "unknown")
        htb_port=$(grep "^htb_port=" "$config_file" | cut -d= -f2 || echo "unknown")
    fi
    
    # Stop Caddy gracefully using its admin API, fallback to kill
    local stopped=0
    if [ -f "$caddyfile" ]; then
        if caddy stop --config "$caddyfile" 2>/dev/null; then
            echo "Stopped: $box_name (graceful shutdown)"
            stopped=1
        fi
    fi

    # Fallback to PID-based kill if caddy stop failed or no Caddyfile
    if [ $stopped -eq 0 ] && [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file")
        if kill "$pid" 2>/dev/null; then
            echo "Stopped: $box_name (PID: $pid)"
        else
            echo "Process not running, cleaning up..."
        fi
    fi

    # Verify process is gone, force-kill if still running
    if [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file")
        sleep 1
        if kill -0 "$pid" 2>/dev/null; then
            echo "⚠️  Warning: Process $pid still running, forcing..."
            kill -9 "$pid" 2>/dev/null || true
        fi
        rm -f "$pid_file"
    fi
    
    # Cleanup files
    rm -f "$port_file"
    rm -f "$PROXY_DIR/$box_name.$port"
    rm -f "$caddyfile"
    rm -f "$config_file"
    rm -f "$PROXY_DIR/$box_name.log"
    rm -f "$PROXY_DIR/$box_name.access.log"
    
    echo "✅ Torn down: $box_name"
    echo "   Target: $htb_ip:$htb_port"
    echo "   Port $port released"
}

# Function: List active proxies
list_proxies() {
    echo "Active HTB Proxies"
    echo "=================="
    echo ""
    
    local found=0
    for port_file in "$PROXY_DIR"/*.port; do
        [ -e "$port_file" ] || continue
        found=1
        
        local box_name
        box_name=$(basename "$port_file" .port)
        local port
        port=$(cat "$port_file")
        local config_file="$PROXY_DIR/$box_name.conf"
        local pid_file="$PROXY_DIR/$box_name.pid"
        
        # Get config details
        local htb_ip="unknown"
        local htb_port="unknown"
        local mode="unknown"
        local ssl="false"
        if [ -f "$config_file" ]; then
            htb_ip=$(grep "^htb_ip=" "$config_file" | cut -d= -f2 || echo "unknown")
            htb_port=$(grep "^htb_port=" "$config_file" | cut -d= -f2 || echo "unknown")
            mode=$(grep "^mode=" "$config_file" | cut -d= -f2 || echo "unknown")
            ssl=$(grep "^ssl=" "$config_file" | cut -d= -f2 || echo "false")
        fi
        
        # Check if process is running
        local status="stopped"
        if [ -f "$pid_file" ]; then
            local pid
            pid=$(cat "$pid_file")
            if kill -0 "$pid" 2>/dev/null; then
                status="running (PID: $pid)"
            fi
        fi
        
        local scheme="http"
        [ "$ssl" = "true" ] && scheme="https"
        
        echo "  $box_name"
        echo "    Target: $htb_ip:$htb_port"
        echo "    VPS Port: $port ($scheme)"
        echo "    Mode: $mode"
        echo "    Status: $status"
        echo ""
    done
    
    if [ $found -eq 0 ]; then
        echo "  No active proxies"
        echo ""
        echo "Start one with: htb-proxy.sh up <box> <ip>"
    fi
}

# Main
case "${1:-}" in
    up|start)
        shift
        start_proxy "$@"
        ;;
    down|stop)
        shift
        stop_proxy "$@"
        ;;
    status|list)
        list_proxies
        ;;
    -h|--help|help)
        show_usage
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
