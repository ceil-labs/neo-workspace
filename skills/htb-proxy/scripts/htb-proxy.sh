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
  --host <hostname>     - Set specific Host header (default: pass-through)
  --pass-through        - Pass original Host header from client (default)
  --port <port>         - Specific local VPS port (auto-assigned if omitted)

Examples:
  # Basic proxy to port 80
  htb-proxy.sh up Devvortex 10.129.190.60

  # Proxy to alternate port
  htb-proxy.sh up Devvortex 10.129.190.60 --target-port 8080

  # Multiple proxies for same box (different ports)
  htb-proxy.sh up Devvortex 10.129.190.60              # port 80
  htb-proxy.sh up Devvortex-admin 10.129.190.60 --target-port 8080
  htb-proxy.sh up Devvortex-api 10.129.190.60 --target-port 3000

  # Force specific Host header
  htb-proxy.sh up Devvortex 10.129.190.60 --host devvortex.htb

  # Cleanup
  htb-proxy.sh down Devvortex
  htb-proxy.sh down Devvortex-admin

  # Check status
  htb-proxy.sh status

Access Pattern:
  Once running, add to local /etc/hosts:
    <vps-tailscale-ip> devvortex.htb
  
  Then browse: http://devvortex.htb:<vps-port>
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
    
    # Build Caddyfile based on host header mode
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
    echo "$pid" > "$pid_file"
    
    # Wait a moment and verify it started
    sleep 2
    if kill -0 "$pid" 2>/dev/null; then
        echo ""
        echo "✅ Proxy active: $box_name"
        echo "   HTB Target: $htb_ip:$target_port"
        echo "   VPS Port:   $port"
        if [ $pass_through -eq 1 ] || [ -z "$host_header" ]; then
            echo "   Host Mode:  Pass-through (preserves client Host header)"
        else
            echo "   Host Mode:  Fixed (Host: $host_header)"
        fi
        echo ""
        echo "Setup on your LOCAL machine:"
        echo "   1. Add to /etc/hosts:"
        echo "      <vps-tailscale-ip> <target-domain>"
        echo "   2. Browse: http://<target-domain>:$port"
        echo ""
        echo "To stop: htb-proxy.sh down $box_name"
    else
        echo "❌ Failed to start proxy. Check log:"
        cat "$PROXY_DIR/$box_name.log"
        rm -f "$port_file" "$PROXY_DIR/$box_name.$port" "$caddyfile" "$config_file"
        exit 1
    fi
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
    
    # Kill process if PID file exists
    if [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file")
        if kill "$pid" 2>/dev/null; then
            echo "Stopped: $box_name (PID: $pid)"
        else
            echo "Process not running, cleaning up..."
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
        if [ -f "$config_file" ]; then
            htb_ip=$(grep "^htb_ip=" "$config_file" | cut -d= -f2 || echo "unknown")
            htb_port=$(grep "^htb_port=" "$config_file" | cut -d= -f2 || echo "unknown")
            mode=$(grep "^mode=" "$config_file" | cut -d= -f2 || echo "unknown")
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
        
        echo "  $box_name"
        echo "    Target: $htb_ip:$htb_port"
        echo "    VPS Port: $port"
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
