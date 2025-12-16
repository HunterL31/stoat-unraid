#!/bin/bash

# =============================================================================
# Stoat Unraid Files Feature Setup Script
# =============================================================================
# This script helps configure the Unraid array file linking feature
#
# Usage: ./setup-unraid-files.sh [share_path]
# Example: ./setup-unraid-files.sh /mnt/user/Media

set -e

echo "=============================================="
echo "Stoat Unraid Files Feature Setup"
echo "=============================================="
echo ""

# Get share path from argument or prompt
SHARE_PATH="${1}"

if [ -z "$SHARE_PATH" ]; then
    echo "Which Unraid share(s) would you like to access from Stoat?"
    echo ""
    echo "Options:"
    echo "  1) /mnt/user (All shares - convenient but less secure)"
    echo "  2) /mnt/user/Media (Specific share - recommended)"
    echo "  3) Custom path"
    echo ""
    read -p "Enter your choice (1-3): " choice
    
    case $choice in
        1)
            SHARE_PATH="/mnt/user"
            ;;
        2)
            SHARE_PATH="/mnt/user/Media"
            ;;
        3)
            read -p "Enter custom path: " SHARE_PATH
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

# Validate the path exists
if [ ! -d "$SHARE_PATH" ]; then
    echo ""
    echo "ERROR: Path $SHARE_PATH does not exist!"
    echo "Please check your path and try again."
    exit 1
fi

echo ""
echo "✓ Using share path: $SHARE_PATH"

# Check if .env exists
if [ ! -f .env ]; then
    echo ""
    echo "ERROR: .env file not found!"
    echo "Please run ./setup-unraid.sh first to create the base configuration."
    exit 1
fi

# Update or add configuration to .env
echo ""
echo "Updating .env configuration..."

# Remove existing UNRAID_SHARE_PATH and UNRAID_SHARE_MOUNT if present
sed -i '/^UNRAID_SHARE_PATH=/d' .env 2>/dev/null || true
sed -i '/^UNRAID_SHARE_MOUNT=/d' .env 2>/dev/null || true

# Add new configuration
echo "" >> .env
echo "# Unraid Files Configuration" >> .env
echo "UNRAID_SHARE_PATH=$SHARE_PATH" >> .env
echo "UNRAID_SHARE_MOUNT=/unraid-shares" >> .env

echo "✓ Configuration updated"

# Build the unraid-files service
echo ""
echo "Building unraid-files service..."
docker compose build unraid-files

if [ $? -eq 0 ]; then
    echo "✓ Build successful"
else
    echo "ERROR: Build failed"
    exit 1
fi

# Start or restart the service
echo ""
echo "Starting unraid-files service..."
docker compose up -d unraid-files

if [ $? -eq 0 ]; then
    echo "✓ Service started"
else
    echo "ERROR: Service failed to start"
    exit 1
fi

# Wait a moment for the service to initialize
sleep 2

# Check if service is healthy
if docker compose ps unraid-files | grep -q "Up"; then
    echo ""
    echo "=============================================="
    echo "✅ Unraid Files Feature Setup Complete!"
    echo "=============================================="
    echo ""
    echo "Access the file browser at:"
    
    # Get the hostname from .env
    HOSTNAME=$(grep "^TAILSCALE_HOSTNAME=" .env | cut -d'=' -f2)
    
    if [ -n "$HOSTNAME" ]; then
        echo "  https://$HOSTNAME/unraid/"
    else
        echo "  https://your-domain/unraid/"
    fi
    
    echo ""
    echo "Mounted share: $SHARE_PATH"
    echo ""
    echo "For more information, see: UNRAID-FILES-FEATURE.md"
    echo ""
else
    echo ""
    echo "⚠️  WARNING: Service started but may not be healthy"
    echo "Check logs with: docker compose logs unraid-files"
fi

