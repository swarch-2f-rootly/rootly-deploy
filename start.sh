#!/bin/bash

# Auto-detect LAN IP and start Rootly services

detect_lan_ip() {
    local lan_ip=""
    
    # Try ip route first
    lan_ip=$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ {print $7}' | head -1)
    if [[ -n "$lan_ip" && "$lan_ip" != "127.0.0.1" ]]; then
        echo "$lan_ip"
        return 0
    fi
    
    # Check network interfaces
    while IFS= read -r interface; do
        if [[ "$interface" =~ ^(eth|wlan|wlp|enp|ens) ]]; then
            lan_ip=$(ip addr show "$interface" 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -1)
            if [[ -n "$lan_ip" ]]; then
                echo "$lan_ip"
                return 0
            fi
        fi
    done < <(ls /sys/class/net/ 2>/dev/null)
    
    # Fallback to hostname
    lan_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [[ -n "$lan_ip" && "$lan_ip" != "127.0.0.1" ]]; then
        echo "$lan_ip"
        return 0
    fi
    
    echo ""
    return 1
}

LAN_IP=$(detect_lan_ip)

if [[ -n "$LAN_IP" ]]; then
    echo "Detected LAN IP: $LAN_IP"
    export HOST_IP="$LAN_IP"
else
    echo "Could not detect LAN IP, using localhost"
    export HOST_IP="localhost"
fi

echo "Host IP: $HOST_IP"
echo "Services will be available at:"
echo "  Data Management: http://$HOST_IP:8002"
echo "  Analytics: http://$HOST_IP:8000"
echo "  Authentication: http://$HOST_IP:8001"
echo "  Frontend: http://$HOST_IP:3000"

if ! command -v docker &> /dev/null; then
    echo "Error: Docker not found"
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    echo "Error: docker compose not available"
    exit 1
fi

if docker compose ps --format json 2>/dev/null | grep -q "running"; then
    echo "Stopping existing services..."
    docker compose down
fi

echo "Starting services..."
docker compose up -d

echo ""
echo "Service status:"
docker compose ps

echo ""
echo "Health check URLs:"
echo "  http://$HOST_IP:8002/health"
echo "  http://$HOST_IP:8000/health"
echo "  http://$HOST_IP:8001/health"
