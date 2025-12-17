#!/bin/bash

# =============================================================================
# REVCORD ENABLER SCRIPT
# =============================================================================
# This script checks if all required revcord environment variables are set
# and enables the revcord service in docker-compose if they are.
# =============================================================================

set -e

echo "🌉 Revcord Discord-Revolt Bridge Setup"
echo "======================================"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found!"
    echo "   Please copy env.example to .env and configure your settings first."
    exit 1
fi

# Source the .env file
set -a
source .env
set +a

# Check if all required revcord variables are set and non-empty
missing_vars=()

if [ -z "${REVCORD_DISCORD_TOKEN:-}" ]; then
    missing_vars+=("REVCORD_DISCORD_TOKEN")
fi

if [ -z "${REVCORD_REVOLT_TOKEN:-}" ]; then
    missing_vars+=("REVCORD_REVOLT_TOKEN")
fi

if [ -z "${REVCORD_API_URL:-}" ]; then
    missing_vars+=("REVCORD_API_URL")
fi

if [ -z "${REVCORD_REVOLT_ATTACHMENT_URL:-}" ]; then
    missing_vars+=("REVCORD_REVOLT_ATTACHMENT_URL")
fi

# Report status
if [ ${#missing_vars[@]} -eq 0 ]; then
    echo "✅ All revcord environment variables are configured!"
    echo ""
    echo "Starting Stoat with revcord enabled..."
    echo ""
    
    # Start with revcord profile
    docker compose --profile revcord up -d
    
    echo ""
    echo "🎉 Stoat is running with revcord bridge enabled!"
    echo ""
    echo "Next steps:"
    echo "1. Invite your Discord bot to your Discord server"
    echo "2. Add your Revolt bot to your Revolt server with Masquerade permission"
    echo "3. Use /connect commands in Discord or rc!connect in Revolt to bridge channels"
    echo ""
    echo "For more info, see: https://github.com/mayudev/revcord#configuration"
    
else
    echo "❌ Missing required revcord environment variables:"
    for var in "${missing_vars[@]}"; do
        echo "   - $var"
    done
    echo ""
    echo "To enable revcord:"
    echo "1. Edit your .env file and uncomment/set the missing variables"
    echo "2. Get Discord bot token from: https://discord.com/developers/applications"
    echo "3. Get Revolt bot token from Revolt settings -> My Bots -> Create a bot"
    echo "4. Run this script again"
    echo ""
    echo "Starting Stoat without revcord..."
    
    # Start without revcord profile
    docker compose up -d
    
    echo ""
    echo "✅ Stoat is running (revcord disabled)"
fi
