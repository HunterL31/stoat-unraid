# Stoat Chat - Unraid Docker Template

<div align="center">

![Stoat Logo](https://raw.githubusercontent.com/revoltchat/revoltchat-solid/master/public/assets/icons/android-chrome-192x192.png)

**Self-hosted chat platform for Unraid servers**

[![GitHub](https://img.shields.io/badge/GitHub-revoltchat%2Fself--hosted-blue?style=flat-square&logo=github)](https://github.com/revoltchat/self-hosted)
[![Discord Alternative](https://img.shields.io/badge/Discord-Alternative-5865F2?style=flat-square&logo=discord&logoColor=white)](https://revolt.chat)

</div>

---

## Overview

Stoat is a modern, open-source chat platform that you can self-host on your Unraid server. This template provides an easy way to deploy the complete Stoat stack using Docker Compose.

### Features

- 💬 Real-time messaging with WebSocket support
- 📎 File uploads and attachments
- 🖼️ Image and link previews
- 🎭 GIF search via Tenor
- 🔔 Push notifications
- 🔐 End-to-end encryption for files
- 🌐 Full API access

### Requirements

- **Unraid 6.9+** with Docker support
- **Domain name** with DNS pointing to your server
- **Ports 80 and 443** available (or use behind a reverse proxy)
- **2GB+ RAM** recommended
- **10GB+ storage** for data

---

## Quick Start

### 1. SSH into your Unraid server

```bash
ssh root@your-unraid-ip
```

### 2. Clone this repository

```bash
# Clone directly to appdata (replace YOUR_USERNAME with your GitHub username)
git clone https://github.com/YOUR_USERNAME/stoat-unraid.git /mnt/user/appdata/stoat
cd /mnt/user/appdata/stoat
```

### 3. Run the setup script

```bash
chmod +x unraid/setup-unraid.sh
./unraid/setup-unraid.sh your.domain.com
```

### 4. Start Stoat

```bash
# Test in foreground first
docker compose -f unraid/docker-compose.yml up

# If everything works, run in background
docker compose -f unraid/docker-compose.yml up -d
```

### 5. Access your instance

Open `https://your.domain.com` in your browser!

---

## Configuration Options

### Setup Script Options

```bash
./unraid/setup-unraid.sh <domain> [options]

Options:
  --appdata PATH      Custom appdata path (default: /mnt/user/appdata)
  --http-port PORT    HTTP port (default: 80)
  --https-port PORT   HTTPS port (default: 443)
  --behind-proxy      Configure for use behind another reverse proxy
  --help              Show help message
```

### Examples

```bash
# Basic setup
./unraid/setup-unraid.sh chat.example.com

# Custom appdata location
./unraid/setup-unraid.sh chat.example.com --appdata /mnt/cache/appdata

# Behind SWAG/Nginx Proxy Manager
./unraid/setup-unraid.sh chat.example.com --behind-proxy --http-port 8080

# Custom ports
./unraid/setup-unraid.sh chat.example.com --http-port 8080 --https-port 8443
```

---

## Using with Reverse Proxy (SWAG/NPM)

If you're already using SWAG, Nginx Proxy Manager, or another reverse proxy:

### 1. Run setup with `--behind-proxy` flag

```bash
./unraid/setup-unraid.sh chat.example.com --behind-proxy --http-port 8080
```

### 2. Configure your reverse proxy

#### For SWAG (Nginx)

Create `/mnt/user/appdata/swag/nginx/proxy-confs/stoat.subdomain.conf`:

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name chat.*;

    include /config/nginx/ssl.conf;
    client_max_body_size 0;

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        proxy_pass http://stoat-caddy:80;
    }

    location /ws {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        proxy_pass http://stoat-caddy:80;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

#### For Nginx Proxy Manager

1. Add a new Proxy Host
2. Domain: `chat.example.com`
3. Forward Hostname: `stoat-caddy`
4. Forward Port: `80`
5. Enable Websockets Support
6. Configure SSL

---

## Directory Structure

After setup, your appdata folder will look like:

```
/mnt/user/appdata/stoat/
├── unraid/
│   ├── docker-compose.yml  # Unraid-optimized compose file
│   ├── setup-unraid.sh     # Setup script
│   ├── Caddyfile           # Caddy reverse proxy config
│   ├── Revolt.toml         # Stoat configuration (generated)
│   ├── .env                # Environment variables (generated)
│   └── .env.web            # Web client config (generated)
├── compose.yml             # Original compose file (not used)
├── README.md               # Main documentation
├── mongodb/                # MongoDB data
├── redis/                  # Redis/KeyDB data
├── rabbitmq/               # RabbitMQ data
├── minio/                  # File storage (S3)
├── caddy-data/             # Caddy certificates
└── caddy-config/           # Caddy config cache
```

---

## Services

| Service | Description | Port (Internal) |
|---------|-------------|-----------------|
| `stoat-database` | MongoDB database | 27017 |
| `stoat-redis` | KeyDB (Redis) cache | 6379 |
| `stoat-rabbitmq` | RabbitMQ message broker | 5672 |
| `stoat-minio` | MinIO file storage | 9000 |
| `stoat-caddy` | Caddy reverse proxy | 80, 443 |
| `stoat-api` | Main API server | 14702 |
| `stoat-events` | WebSocket events | 14703 |
| `stoat-web` | Web frontend | 5000 |
| `stoat-autumn` | File server | 14704 |
| `stoat-january` | Metadata proxy | 14705 |
| `stoat-gifbox` | Tenor GIF proxy | 14706 |
| `stoat-crond` | Scheduled tasks | - |
| `stoat-pushd` | Push notifications | - |

---

## Management Commands

### View logs

```bash
cd /mnt/user/appdata/stoat

# All services
docker compose -f unraid/docker-compose.yml logs -f

# Specific service
docker compose -f unraid/docker-compose.yml logs -f api
```

### Restart services

```bash
docker compose -f unraid/docker-compose.yml restart

# Specific service
docker compose -f unraid/docker-compose.yml restart api
```

### Update to latest version

```bash
cd /mnt/user/appdata/stoat

# Pull latest repo changes
git pull

# Pull latest Docker images
docker compose -f unraid/docker-compose.yml pull
docker compose -f unraid/docker-compose.yml up -d
```

### Stop all services

```bash
docker compose -f unraid/docker-compose.yml down
```

### Backup data

```bash
cd /mnt/user/appdata/stoat

# Stop services first for consistent backup
docker compose -f unraid/docker-compose.yml down

# Backup the entire stoat folder
tar -czvf stoat-backup-$(date +%Y%m%d).tar.gz /mnt/user/appdata/stoat

# Restart services
docker compose -f unraid/docker-compose.yml up -d
```

---

## Advanced Configuration

### Making Your Instance Invite-Only

1. Edit `unraid/Revolt.toml` and add:

```toml
[general]
invite_only = true
```

2. Create an invite code:

```bash
docker compose -f unraid/docker-compose.yml exec database mongosh

# In mongo shell:
use revolt
db.invites.insertOne({ _id: "your_invite_code_here" })
```

3. Restart services:

```bash
docker compose -f unraid/docker-compose.yml restart api
```

### Custom Configuration

Edit `unraid/Revolt.toml` for advanced settings. See the [full configuration reference](https://github.com/revoltchat/backend/blob/stable/crates/core/config/Revolt.toml).

Notable options:
- Email verification
- Captcha (hCaptcha)
- Custom S3 storage
- Push notifications (iOS/Android)

---

## Troubleshooting

### Services won't start

```bash
# Check for errors
docker compose -f unraid/docker-compose.yml logs

# Verify all images are pulled
docker compose -f unraid/docker-compose.yml pull

# Check disk space
df -h /mnt/user/appdata
```

### Can't access the web interface

1. Verify DNS is pointing to your server
2. Check Caddy logs: `docker compose -f unraid/docker-compose.yml logs caddy`
3. Ensure ports 80/443 aren't blocked
4. Check firewall settings in Unraid

### Database connection issues

```bash
# Check MongoDB status
docker compose -f unraid/docker-compose.yml logs database

# Verify health check
docker compose -f unraid/docker-compose.yml ps
```

### WebSocket connection failed

- Ensure your reverse proxy supports WebSockets
- Check that `/ws` path is properly proxied
- Verify `wss://` is used for HTTPS

### Reset everything

```bash
cd /mnt/user/appdata/stoat
docker compose -f unraid/docker-compose.yml down -v
rm -rf mongodb redis rabbitmq minio caddy-data caddy-config
./unraid/setup-unraid.sh your.domain.com
docker compose -f unraid/docker-compose.yml up -d
```

---

## Support

- **GitHub Issues**: [revoltchat/self-hosted](https://github.com/revoltchat/self-hosted/issues)
- **Documentation**: [developers.revolt.chat](https://developers.revolt.chat)
- **Community**: [Revolt Chat](https://revolt.chat)

---

## License

This project is licensed under the [AGPLv3 License](https://github.com/revoltchat/self-hosted/blob/main/LICENSE).

