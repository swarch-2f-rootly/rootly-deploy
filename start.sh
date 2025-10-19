#!/bin/bash

# Auto-detect LAN IP and start Rootly services
# Usage: ./start.sh [--stash]
#   --stash: Stash local changes before updating repositories

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if --stash flag is provided
STASH_CHANGES=false
if [[ "$1" == "--stash" ]]; then
    STASH_CHANGES=true
fi

# Update all repositories to main branch
update_repositories() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Updating Repositories to Main Branch${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    local parent_dir=$(dirname "$(pwd)")
    local repos=(
        "rootly-analytics-backend"
        "rootly-apigateway"
        "rootly-authentication-and-roles-backend"
        "rootly-data-management-backend"
        "rootly-frontend"
        "rootly-user-plant-management-backend"
    )
    
    for repo in "${repos[@]}"; do
        local repo_path="$parent_dir/$repo"
        
        if [ -d "$repo_path/.git" ]; then
            echo -e "${YELLOW}→ Updating $repo...${NC}"
            
            cd "$repo_path" || continue
            
            # Stash local changes only if --stash flag is provided
            if [ "$STASH_CHANGES" = true ] && (! git diff --quiet || ! git diff --cached --quiet); then
                echo -e "${YELLOW}  Stashing local changes...${NC}"
                git stash save "Auto-stash before switching to main - $(date '+%Y-%m-%d %H:%M:%S')"
            fi
            
            # Fetch latest changes
            git fetch origin
            
            # Switch to main branch
            if git checkout main 2>/dev/null; then
                # Pull latest changes
                if git pull origin main; then
                    echo -e "${GREEN}  ✓ $repo updated to main${NC}"
                else
                    echo -e "${RED}  ✗ Failed to pull $repo${NC}"
                fi
            else
                echo -e "${YELLOW}  ⚠ Could not checkout main for $repo (staying on current branch)${NC}"
            fi
            
            cd - > /dev/null
        else
            echo -e "${YELLOW}  ⚠ Skipping $repo (not a git repository)${NC}"
        fi
    done
    
    echo ""
}

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

copy_env_if_not_exists() {
    if [ ! -f .env ]; then
        cp .env.example .env
        echo "Copied .env.example to .env"
    fi
}

copy_env_if_not_exists_frontend() {
    if [ ! -f ../rootly-ssr-frontend/.env ]; then
        cp ../rootly-ssr-frontend/.env.example ../rootly-ssr-frontend/.env
        echo "Copied .env.example to .env for SSR frontend"
    fi
}

# Main execution starts here
update_repositories

copy_env_if_not_exists
copy_env_if_not_exists_frontend

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
echo "  API Gateway: http://$HOST_IP:8080"
echo "  Frontend SSR: http://$HOST_IP:3001"
echo "  GraphQL Playground: http://$HOST_IP:8080/graphql"

if ! command -v docker &> /dev/null; then
    echo "Error: Docker not found"
    exit 1
fi

# Determine compose command (prefer 'docker compose' plugin, fallback to 'docker-compose')
COMPOSE_CMD=""
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    echo "Error: neither 'docker compose' nor 'docker-compose' is available"
    exit 1
fi

echo "Using compose command: $COMPOSE_CMD"

# If services are running, stop them first
if $COMPOSE_CMD ps --format json 2>/dev/null | grep -q "running"; then
    echo "Stopping existing services..."
    $COMPOSE_CMD down
fi

echo "Starting services..."
$COMPOSE_CMD up -d --build

echo ""
echo "Service status:"
$COMPOSE_CMD ps

echo ""
echo "Health check URLs:"
echo "  Data Management: http://$HOST_IP:8002/health"
echo "  Analytics: http://$HOST_IP:8000/health"
echo "  Authentication: http://$HOST_IP:8001/health"
echo "  API Gateway: http://$HOST_IP:8080/health"
echo "  Frontend SSR: http://$HOST_IP:3001"
