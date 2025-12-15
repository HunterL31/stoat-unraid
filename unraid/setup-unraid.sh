#!/usr/bin/env bash
# =============================================================================
# STOAT CHAT - UNRAID SETUP SCRIPT
# =============================================================================
# This script configures Stoat for your Unraid server
#
# Usage: ./setup-unraid.sh <your.domain.com> [options]
#
# Options:
#   --appdata PATH    Custom appdata path (default: /mnt/user/appdata)
#   --http-port PORT  HTTP port (default: 80)
#   --https-port PORT HTTPS port (default: 443)
#   --behind-proxy    Configure for use behind another reverse proxy
#   --tailscale       Configure for Tailscale access (no public ports)
#   --help            Show this help message
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
APPDATA_PATH="/mnt/user/appdata"
HTTP_PORT="80"
HTTPS_PORT="443"
BEHIND_PROXY=false
USE_TAILSCALE=false

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                   ║"
    echo "║   ███████╗████████╗ ██████╗  █████╗ ████████╗                     ║"
    echo "║   ██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗╚══██╔══╝                     ║"
    echo "║   ███████╗   ██║   ██║   ██║███████║   ██║                        ║"
    echo "║   ╚════██║   ██║   ██║   ██║██╔══██║   ██║                        ║"
    echo "║   ███████║   ██║   ╚██████╔╝██║  ██║   ██║                        ║"
    echo "║   ╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝                        ║"
    echo "║                                                                   ║"
    echo "║              Self-Hosted Chat for Unraid                          ║"
    echo "║                                                                   ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_help() {
    echo "Usage: $0 <domain> [options]"
    echo ""
    echo "Arguments:"
    echo "  domain              Your domain name (e.g., chat.example.com)"
    echo "                      For Tailscale: your-machine.tailnet-name.ts.net"
    echo ""
    echo "Options:"
    echo "  --appdata PATH      Custom appdata path (default: /mnt/user/appdata)"
    echo "  --http-port PORT    HTTP port (default: 80)"
    echo "  --https-port PORT   HTTPS port (default: 443)"
    echo "  --behind-proxy      Configure for use behind another reverse proxy (SWAG, NPM, etc.)"
    echo "  --tailscale         Configure for Tailscale access (no public ports exposed)"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 chat.example.com"
    echo "  $0 chat.example.com --behind-proxy --http-port 8080"
    echo "  $0 chat.example.com --appdata /mnt/cache/appdata"
    echo "  $0 stoat.tail1234.ts.net --tailscale"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    local missing=()
    
    if ! command -v openssl &> /dev/null; then
        missing+=("openssl")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing+=("docker")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing[*]}"
        echo "Please install them before running this script."
        exit 1
    fi
    
    log_success "All dependencies found"
}

generate_secrets() {
    log_info "Generating security keys..."
    
    # Generate VAPID keys for push notifications
    VAPID_PRIVATE_KEY_FILE=$(mktemp)
    openssl ecparam -name prime256v1 -genkey -noout -out "$VAPID_PRIVATE_KEY_FILE" 2>/dev/null
    VAPID_PRIVATE_KEY=$(base64 -w 0 "$VAPID_PRIVATE_KEY_FILE" | tr -d '=')
    VAPID_PUBLIC_KEY=$(openssl ec -in "$VAPID_PRIVATE_KEY_FILE" -outform DER 2>/dev/null | tail -c 65 | base64 -w 0 | tr '/+' '_-' | tr -d '=')
    rm -f "$VAPID_PRIVATE_KEY_FILE"
    
    # Generate encryption key for files
    FILES_ENCRYPTION_KEY=$(openssl rand -base64 32)
    
    log_success "Security keys generated"
}

create_directories() {
    log_info "Creating data directories..."
    
    local dirs=(
        "${APPDATA_PATH}/stoat/mongodb"
        "${APPDATA_PATH}/stoat/redis"
        "${APPDATA_PATH}/stoat/rabbitmq"
        "${APPDATA_PATH}/stoat/minio"
        "${APPDATA_PATH}/stoat/caddy-data"
        "${APPDATA_PATH}/stoat/caddy-config"
    )
    
    # Add Tailscale directory if using Tailscale
    if [ "$USE_TAILSCALE" = true ]; then
        dirs+=("${APPDATA_PATH}/stoat/tailscale")
    fi
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    log_success "Data directories created"
}

create_env_file() {
    log_info "Creating .env file..."
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    cat > "${SCRIPT_DIR}/.env" << EOF
# =============================================================================
# STOAT CHAT - UNRAID CONFIGURATION
# Generated on $(date)
# =============================================================================

# Domain Configuration
STOAT_DOMAIN=${DOMAIN}

# Paths
APPDATA_PATH=${APPDATA_PATH}

# Ports
HTTP_PORT=${HTTP_PORT}
HTTPS_PORT=${HTTPS_PORT}

# RabbitMQ Credentials
RABBITMQ_USER=rabbituser
RABBITMQ_PASS=$(openssl rand -hex 16)

# MinIO Credentials
MINIO_USER=minioautumn
MINIO_PASS=$(openssl rand -hex 16)
EOF

    # Add Tailscale config if enabled
    if [ "$USE_TAILSCALE" = true ]; then
        cat >> "${SCRIPT_DIR}/.env" << EOF

# Tailscale Configuration
# Get an auth key from: https://login.tailscale.com/admin/settings/keys
TAILSCALE_AUTHKEY=tskey-auth-REPLACE_WITH_YOUR_KEY
TAILSCALE_HOSTNAME=${DOMAIN%%.*}
EOF
    fi

    log_success ".env file created"
}

create_env_web() {
    log_info "Creating .env.web file..."
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    if [ "$USE_TAILSCALE" = true ]; then
        # Tailscale mode - Caddy listens on :80, Tailscale handles HTTPS
        cat > "${SCRIPT_DIR}/.env.web" << EOF
HOSTNAME=:80
REVOLT_PUBLIC_URL=https://${DOMAIN}/api
EOF
    elif [ "$BEHIND_PROXY" = true ]; then
        # Behind another proxy - use internal port
        cat > "${SCRIPT_DIR}/.env.web" << EOF
HOSTNAME=:80
REVOLT_PUBLIC_URL=https://${DOMAIN}/api
EOF
    else
        # Direct access with Caddy handling SSL
        cat > "${SCRIPT_DIR}/.env.web" << EOF
HOSTNAME=${DOMAIN}
REVOLT_PUBLIC_URL=https://${DOMAIN}/api
EOF
    fi
    
    log_success ".env.web file created"
}

create_revolt_toml() {
    log_info "Creating Revolt.toml configuration..."
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    cat > "${SCRIPT_DIR}/Revolt.toml" << EOF
# =============================================================================
# STOAT CONFIGURATION
# Generated by setup-unraid.sh on $(date)
# =============================================================================

[hosts]
app = "https://${DOMAIN}"
api = "https://${DOMAIN}/api"
events = "wss://${DOMAIN}/ws"
autumn = "https://${DOMAIN}/autumn"
january = "https://${DOMAIN}/january"

[pushd.vapid]
private_key = "${VAPID_PRIVATE_KEY}"
public_key = "${VAPID_PUBLIC_KEY}"

[files]
encryption_key = "${FILES_ENCRYPTION_KEY}"
EOF

    log_success "Revolt.toml created"
}

copy_caddyfile() {
    log_info "Setting up Caddyfile..."
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Check if Caddyfile already exists in unraid folder
    if [ -f "${SCRIPT_DIR}/Caddyfile" ]; then
        log_success "Caddyfile already exists"
    elif [ -f "${SCRIPT_DIR}/../Caddyfile" ]; then
        cp "${SCRIPT_DIR}/../Caddyfile" "${SCRIPT_DIR}/Caddyfile"
        log_success "Caddyfile copied from parent directory"
    else
        # Create a default Caddyfile
        cat > "${SCRIPT_DIR}/Caddyfile" << 'EOF'
{$HOSTNAME} {
	route /api* {
		uri strip_prefix /api
		reverse_proxy http://api:14702 {
			header_down Location "^/" "/api/"
		}
	}

	route /ws {
		uri strip_prefix /ws
		reverse_proxy http://events:14703 {
			header_down Location "^/" "/ws/"
		}
	}

	route /autumn* {
		uri strip_prefix /autumn
		reverse_proxy http://autumn:14704 {
			header_down Location "^/" "/autumn/"
		}
	}

	route /january* {
		uri strip_prefix /january
		reverse_proxy http://january:14705 {
			header_down Location "^/" "/january/"
		}
	}

	route /gifbox* {
		uri strip_prefix /gifbox
		reverse_proxy http://gifbox:14706 {
			header_down Location "^/" "/gifbox/"
		}
	}

	reverse_proxy http://web:5000
}
EOF
        log_success "Caddyfile created"
    fi
}

print_summary() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    SETUP COMPLETE!                                 ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Domain:        ${BLUE}${DOMAIN}${NC}"
    echo -e "Data Path:     ${BLUE}${APPDATA_PATH}/stoat${NC}"
    
    if [ "$USE_TAILSCALE" = true ]; then
        echo -e "Mode:          ${BLUE}Tailscale${NC}"
        echo ""
        echo -e "${YELLOW}Next Steps:${NC}"
        echo ""
        echo "1. Get a Tailscale auth key from:"
        echo -e "   ${BLUE}https://login.tailscale.com/admin/settings/keys${NC}"
        echo "   (Enable 'Reusable' so it reconnects after restarts)"
        echo ""
        echo "2. Edit unraid/.env and set your auth key:"
        echo -e "   ${BLUE}TAILSCALE_AUTHKEY=tskey-auth-xxxxx${NC}"
        echo ""
        echo "3. Start Stoat with Tailscale compose file:"
        echo -e "   ${BLUE}docker compose -f unraid/docker-compose.tailscale.yml up -d${NC}"
        echo ""
        echo "4. Configure Tailscale Serve (one-time):"
        echo -e "   ${BLUE}chmod +x unraid/tailscale-setup.sh && ./unraid/tailscale-setup.sh${NC}"
        echo ""
        echo "5. Access your instance via Tailscale at:"
        echo -e "   ${BLUE}https://${DOMAIN}${NC}"
    else
        echo -e "HTTP Port:     ${BLUE}${HTTP_PORT}${NC}"
        echo -e "HTTPS Port:    ${BLUE}${HTTPS_PORT}${NC}"
        echo ""
        echo -e "${YELLOW}Next Steps:${NC}"
        echo ""
        echo "1. Ensure your domain DNS points to this server"
        echo ""
        echo "2. Start Stoat in foreground to verify:"
        echo -e "   ${BLUE}docker compose -f unraid/docker-compose.yml up${NC}"
        echo ""
        echo "3. If everything works, run in background:"
        echo -e "   ${BLUE}docker compose -f unraid/docker-compose.yml up -d${NC}"
        echo ""
        echo "4. Access your instance at:"
        echo -e "   ${BLUE}https://${DOMAIN}${NC}"
        echo ""
        if [ "$BEHIND_PROXY" = true ]; then
            echo -e "${YELLOW}Note:${NC} Configured for use behind a reverse proxy."
            echo "      Make sure your proxy forwards to port ${HTTP_PORT}"
            echo ""
        fi
    fi
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
}

# -----------------------------------------------------------------------------
# Main Script
# -----------------------------------------------------------------------------

print_banner

# Parse arguments
DOMAIN=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            print_help
            exit 0
            ;;
        --appdata)
            APPDATA_PATH="$2"
            shift 2
            ;;
        --http-port)
            HTTP_PORT="$2"
            shift 2
            ;;
        --https-port)
            HTTPS_PORT="$2"
            shift 2
            ;;
        --behind-proxy)
            BEHIND_PROXY=true
            shift
            ;;
        --tailscale)
            USE_TAILSCALE=true
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            print_help
            exit 1
            ;;
        *)
            if [ -z "$DOMAIN" ]; then
                DOMAIN="$1"
            else
                log_error "Unexpected argument: $1"
                print_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate domain
if [ -z "$DOMAIN" ]; then
    log_error "Domain name is required"
    echo ""
    print_help
    exit 1
fi

# Validate domain format
if ! [[ "$DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$ ]]; then
    log_error "Invalid domain format: $DOMAIN"
    exit 1
fi

log_info "Configuring Stoat for domain: $DOMAIN"
echo ""

# Run setup steps
check_dependencies
generate_secrets
create_directories
create_env_file
create_env_web
create_revolt_toml
copy_caddyfile

print_summary

