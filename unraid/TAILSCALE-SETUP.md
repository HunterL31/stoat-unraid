# Stoat with Tailscale - Isolated Secure Access

This guide sets up Stoat with its **own Tailscale identity**, completely separate from your Unraid server. When you share access to Stoat, users can ONLY access the chat service - they cannot access your Unraid server or any other services.

---

## Why Use This Setup?

| Feature | Benefit |
|---------|---------|
| **Isolated Identity** | Stoat gets its own node on your tailnet, separate from Unraid |
| **Secure Sharing** | Share Stoat with friends/family without exposing your server |
| **No Public Ports** | Ports 80/443 stay closed - only accessible via Tailscale |
| **Automatic HTTPS** | Tailscale Serve provides valid HTTPS certificates |
| **Access Control** | Use Tailscale ACLs to control who can access Stoat |

---

## Setup Instructions

### Step 1: Get a Tailscale Auth Key

1. Go to [Tailscale Admin Console → Settings → Keys](https://login.tailscale.com/admin/settings/keys)
2. Click **Generate auth key**
3. Configure the key:
   - ✅ **Reusable** - So the container can reconnect after restarts
   - ✅ **Ephemeral** (optional) - Node auto-removes when container stops
   - Set expiration as needed (or no expiry for permanent setup)
4. Copy the key (starts with `tskey-auth-`)

### Step 2: Clone and Setup

```bash
# SSH into Unraid
ssh root@YOUR-UNRAID-IP

# Clone the repository
git clone https://github.com/YOUR_USERNAME/stoat-unraid.git /mnt/user/appdata/stoat
cd /mnt/user/appdata/stoat

# Run setup with Tailscale flag
chmod +x unraid/setup-unraid.sh
./unraid/setup-unraid.sh stoat --tailscale
```

> **Note:** The hostname `stoat` will become `stoat.your-tailnet.ts.net`

### Step 3: Add Your Auth Key

Edit the generated `.env` file:

```bash
nano unraid/.env
```

Find this line and replace with your actual key:
```
TAILSCALE_AUTHKEY=tskey-auth-REPLACE_WITH_YOUR_KEY
```

### Step 4: Start Stoat

```bash
docker compose -f unraid/docker-compose.tailscale.yml up -d
```

### Step 5: Verify It's Working

1. Check the Tailscale container connected:
   ```bash
   docker logs stoat-tailscale
   ```

2. Go to [Tailscale Admin → Machines](https://login.tailscale.com/admin/machines)
   - You should see a new node called `stoat`

3. Access Stoat at:
   ```
   https://stoat.your-tailnet.ts.net
   ```

---

## Sharing Stoat with Others

### Option 1: Share with Tailscale Users

If the person has Tailscale:

1. Go to [Tailscale Admin → Machines](https://login.tailscale.com/admin/machines)
2. Find `stoat` in your machine list
3. Click the **⋮** menu → **Share...**
4. Enter their email or Tailscale identity
5. They can now access `https://stoat.your-tailnet.ts.net`

### Option 2: Tailscale Funnel (Public Access)

To make Stoat publicly accessible without requiring Tailscale:

1. Enable Funnel in the Tailscale admin console
2. Update `tailscale-serve.json`:

```json
{
  "TCP": {
    "443": {
      "HTTPS": true
    }
  },
  "Web": {
    "${TS_CERT_DOMAIN}:443": {
      "Handlers": {
        "/": {
          "Proxy": "http://127.0.0.1:80"
        }
      }
    }
  },
  "AllowFunnel": {
    "${TS_CERT_DOMAIN}:443": true
  }
}
```

3. Restart the Tailscale container:
   ```bash
   docker compose -f unraid/docker-compose.tailscale.yml restart tailscale
   ```

4. Stoat is now publicly accessible at `https://stoat.your-tailnet.ts.net`

---

## Access Control with ACLs

For fine-grained control, use Tailscale ACLs. Go to [Access Controls](https://login.tailscale.com/admin/acls) and add rules like:

```json
{
  "acls": [
    // Allow specific users to access Stoat
    {
      "action": "accept",
      "src": ["user1@example.com", "user2@example.com"],
      "dst": ["stoat:443"]
    },
    // Allow a group to access Stoat
    {
      "action": "accept",
      "src": ["group:friends"],
      "dst": ["stoat:443"]
    }
  ],
  "groups": {
    "group:friends": ["friend1@example.com", "friend2@example.com"]
  }
}
```

---

## Troubleshooting

### Container won't connect to Tailscale

```bash
# Check logs
docker logs stoat-tailscale

# Common issues:
# - Invalid auth key (expired or wrong)
# - Key already used (if not reusable)
# - Network issues
```

### Can't access Stoat via Tailscale URL

1. Verify the node is online in Tailscale admin
2. Check that Tailscale Serve is running:
   ```bash
   docker exec stoat-tailscale tailscale serve status
   ```
3. Ensure you're connected to Tailscale on your device

### Reset Tailscale Identity

To get a fresh Tailscale identity:

```bash
# Stop containers
docker compose -f unraid/docker-compose.tailscale.yml down

# Remove Tailscale state
rm -rf /mnt/user/appdata/stoat/tailscale/*

# Generate new auth key and update .env
# Then restart
docker compose -f unraid/docker-compose.tailscale.yml up -d
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Your Tailnet                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────────┐         ┌──────────────────────────────────┐ │
│   │   Unraid     │         │  stoat (separate node)           │ │
│   │   Server     │         │  ┌────────────────────────────┐  │ │
│   │              │         │  │ stoat-tailscale container  │  │ │
│   │  (your node) │   ✗     │  │   ↓                        │  │ │
│   │              │ ──────► │  │ stoat-caddy (network_mode) │  │ │
│   │              │ blocked │  │   ↓                        │  │ │
│   │              │         │  │ stoat-api, stoat-web, etc  │  │ │
│   └──────────────┘         │  └────────────────────────────┘  │ │
│                            └──────────────────────────────────┘ │
│                                                                  │
│   Users shared with "stoat" can ONLY access the chat service    │
│   They CANNOT access your Unraid server or other services       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Comparison: Host Tailscale vs Container Tailscale

| Aspect | Tailscale on Unraid Host | Tailscale Container (This Setup) |
|--------|-------------------------|----------------------------------|
| **Identity** | Single node for everything | Stoat gets its own node |
| **Sharing** | Shares access to entire server | Shares access to Stoat only |
| **Security** | Less isolated | Fully isolated |
| **Setup** | Simpler | Slightly more complex |
| **Use Case** | Personal use only | Sharing with others |

