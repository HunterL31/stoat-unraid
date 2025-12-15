#!/usr/bin/env bash
# =============================================================================
# TAILSCALE SERVE SETUP
# =============================================================================
# Run this AFTER the containers are started to configure Tailscale Serve
# This script sets up HTTPS forwarding from Tailscale to Caddy
#
# Usage: ./tailscale-setup.sh
# =============================================================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Setting up Tailscale Serve...${NC}"

# Check if the tailscale container is running
if ! docker ps --format '{{.Names}}' | grep -q '^stoat-tailscale$'; then
    echo -e "${RED}Error: stoat-tailscale container is not running${NC}"
    echo "Start the containers first with:"
    echo "  docker compose -f unraid/docker-compose.tailscale.yml up -d"
    exit 1
fi

# Wait for Tailscale to be ready
echo "Waiting for Tailscale to connect..."
for i in {1..30}; do
    if docker exec stoat-tailscale tailscale status &>/dev/null; then
        break
    fi
    sleep 2
done

# Check if connected
if ! docker exec stoat-tailscale tailscale status &>/dev/null; then
    echo -e "${RED}Error: Tailscale failed to connect${NC}"
    echo "Check your TAILSCALE_AUTHKEY in .env"
    docker logs stoat-tailscale
    exit 1
fi

echo -e "${GREEN}Tailscale connected!${NC}"

# Get the Tailscale hostname
TS_HOSTNAME=$(docker exec stoat-tailscale tailscale status --json | grep -o '"Self":{"[^"]*' | head -1 | sed 's/"Self":{"//') 
echo "Tailscale node: ${TS_HOSTNAME:-stoat}"

# Configure Tailscale Serve to forward HTTPS to Caddy
echo "Configuring Tailscale Serve..."
docker exec stoat-tailscale tailscale serve --bg --https=443 http://caddy:80

# Verify serve is running
echo ""
echo -e "${GREEN}Tailscale Serve configured!${NC}"
echo ""
docker exec stoat-tailscale tailscale serve status

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}                    TAILSCALE SETUP COMPLETE!                       ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Access Stoat at: ${BLUE}https://stoat.YOUR-TAILNET.ts.net${NC}"
echo ""
echo -e "${YELLOW}To share with others:${NC}"
echo "1. Go to https://login.tailscale.com/admin/machines"
echo "2. Find 'stoat' and click Share"
echo "3. They can ONLY access Stoat, not your server!"
echo ""

