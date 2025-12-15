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
    echo "  docker compose up -d"
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

# Get the Tailscale IP
TS_IP=$(docker exec stoat-tailscale tailscale ip -4)
echo "Tailscale IP: ${TS_IP}"

# Get the Caddy container IP on the docker network
CADDY_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' stoat-caddy)
echo "Caddy IP: ${CADDY_IP}"

if [ -z "$CADDY_IP" ]; then
    echo -e "${RED}Error: Could not get Caddy container IP${NC}"
    exit 1
fi

# Configure Tailscale Serve to forward HTTPS to Caddy's container IP
echo "Configuring Tailscale Serve to proxy to ${CADDY_IP}:80..."
docker exec stoat-tailscale tailscale serve --bg --https=443 http://${CADDY_IP}:80

# Verify serve is running
echo ""
echo -e "${GREEN}Tailscale Serve configured!${NC}"
echo ""
docker exec stoat-tailscale tailscale serve status

# Get the full Tailscale hostname
TS_HOSTNAME=$(docker exec stoat-tailscale tailscale status --json 2>/dev/null | grep -o '"DNSName":"[^"]*"' | head -1 | sed 's/"DNSName":"//;s/"//' | sed 's/\.$//')

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}                    TAILSCALE SETUP COMPLETE!                       ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
if [ -n "$TS_HOSTNAME" ]; then
    echo -e "Access Stoat at: ${BLUE}https://${TS_HOSTNAME}${NC}"
else
    echo -e "Access Stoat at: ${BLUE}https://stoat.YOUR-TAILNET.ts.net${NC}"
fi
echo ""
echo -e "${YELLOW}To share with others:${NC}"
echo "1. Go to https://login.tailscale.com/admin/machines"
echo "2. Find 'stoat' and click Share"
echo "3. They can ONLY access Stoat, not your server!"
echo ""

