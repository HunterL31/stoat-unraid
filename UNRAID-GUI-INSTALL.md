# Installing Stoat Chat via Unraid GUI

Since Stoat is a multi-container application (13+ Docker containers working together), it requires the **Docker Compose Manager** plugin rather than a traditional single-container template.

---

## Choose Your Setup

| Setup | Best For | Ports Exposed |
|-------|----------|---------------|
| [Standard Setup](#standard-setup) | Public server with domain | 80, 443 |
| [Tailscale Setup](#tailscale-setup) | Sharing with friends securely | None (Tailscale only) |

---

## Standard Setup

### Step 1: Install Docker Compose Manager

1. Open your Unraid web GUI
2. Go to **Apps** (Community Applications)
3. Search for **"Docker Compose Manager"** or **"Compose.Manager"**
4. Click **Install**

---

### Step 2: Clone the Repository (One-time SSH)

```bash
# SSH into your Unraid server
ssh root@YOUR-UNRAID-IP

# Clone directly to the appdata folder
git clone https://github.com/YOUR_USERNAME/stoat-unraid.git /mnt/user/appdata/stoat
cd /mnt/user/appdata/stoat

# Run the setup script (replace with YOUR domain)
chmod +x setup-unraid.sh
./setup-unraid.sh chat.yourdomain.com

# Exit SSH
exit
```

> **Note:** Replace `YOUR_USERNAME` with your GitHub username in the clone URL.

---

### Step 3: Add Stack in Unraid GUI

1. Go to **Docker** tab in Unraid
2. Click the **Compose** sub-tab (added by Docker Compose Manager)
3. Click **Add New Stack**
4. Configure:
   - **Name**: `stoat`
   - **Compose File**: `/mnt/user/appdata/stoat/docker-compose.yml`
5. Click **Save**

---

### Step 4: Start the Stack

1. In the Compose tab, find your `stoat` stack
2. Click the **Play** button to start all containers
3. Wait for all services to become healthy (may take 1-2 minutes)

---

### Step 5: Access Stoat

Open your browser and go to:
```
https://your.domain.com
```

---

## Tailscale Setup

Use this setup to share Stoat with friends/family **without exposing your server**. Stoat gets its own Tailscale identity - when you share it, users can ONLY access the chat, not your Unraid server.

### Step 1: Install Docker Compose Manager

1. Open your Unraid web GUI
2. Go to **Apps** (Community Applications)
3. Search for **"Docker Compose Manager"** or **"Compose.Manager"**
4. Click **Install**

---

### Step 2: Get a Tailscale Auth Key

1. Go to [Tailscale Admin → Keys](https://login.tailscale.com/admin/settings/keys)
2. Click **Generate auth key**
3. Settings:
   - ✅ **Reusable** (so container reconnects after restarts)
   - ✅ **Ephemeral** (optional - auto-removes node when stopped)
4. Copy the key (starts with `tskey-auth-`)

---

### Step 3: Clone and Setup (One-time SSH)

```bash
# SSH into your Unraid server
ssh root@YOUR-UNRAID-IP

# Clone directly to the appdata folder
git clone https://github.com/YOUR_USERNAME/stoat-unraid.git /mnt/user/appdata/stoat
cd /mnt/user/appdata/stoat

# Run setup with Tailscale flag
chmod +x setup-unraid.sh
./setup-unraid.sh stoat --tailscale

# Add your Tailscale auth key
nano .env
# Find TAILSCALE_AUTHKEY= and paste your key

# Exit SSH
exit
```

> **Note:** The hostname `stoat` will become `stoat.your-tailnet.ts.net`

---

### Step 4: Add Stack in Unraid GUI

1. Go to **Docker** tab in Unraid
2. Click the **Compose** sub-tab
3. Click **Add New Stack**
4. Configure:
   - **Name**: `stoat`
   - **Compose File**: `/mnt/user/appdata/stoat/docker-compose.yml`
5. Click **Save**

> ⚠️ **Important:** Use `docker-compose.tailscale.yml` not `docker-compose.yml`

---

### Step 5: Start the Stack

1. In the Compose tab, find your `stoat` stack
2. Click the **Play** button
3. Wait for all services to become healthy

---

### Step 6: Verify Tailscale Connection

1. Go to [Tailscale Admin → Machines](https://login.tailscale.com/admin/machines)
2. You should see a new node called `stoat`
3. Access Stoat at: `https://stoat.your-tailnet.ts.net`

---

### Step 7: Share with Others

1. In [Tailscale Machines](https://login.tailscale.com/admin/machines), find `stoat`
2. Click **⋮** → **Share...**
3. Enter their email address
4. They install Tailscale, accept the share, and access the chat!

**Security:** They can ONLY access Stoat - not your Unraid server or other services.

---

## Managing Stoat from the GUI

Once installed, manage Stoat entirely from the Unraid GUI:

| Action | How to Do It |
|--------|--------------|
| **Start** | Docker → Compose → stoat → ▶️ Play |
| **Stop** | Docker → Compose → stoat → ⏹️ Stop |
| **Restart** | Docker → Compose → stoat → 🔄 Restart |
| **View Logs** | Docker → Compose → stoat → 📋 Logs |
| **Update** | Docker → Compose → stoat → ⬆️ Pull & Recreate |

### Container List

All Stoat containers are prefixed with `stoat-`:

| Container | Purpose |
|-----------|---------|
| stoat-database | MongoDB database |
| stoat-redis | Cache & message broker |
| stoat-rabbitmq | Internal messaging |
| stoat-minio | File storage |
| stoat-caddy | Reverse proxy |
| stoat-api | Main API server |
| stoat-events | WebSocket events |
| stoat-web | Web frontend |
| stoat-autumn | File uploads |
| stoat-january | Link previews |
| stoat-gifbox | GIF search |
| stoat-crond | Scheduled tasks |
| stoat-pushd | Push notifications |
| stoat-tailscale | Tailscale endpoint (Tailscale setup only) |

---

## Updating Stoat

### Via SSH

```bash
ssh root@YOUR-UNRAID-IP
cd /mnt/user/appdata/stoat
git pull
```

### Via GUI

After pulling updates via SSH:
1. Go to **Docker → Compose → stoat**
2. Click **Pull & Recreate**

---

## Switching Between Standard and Tailscale

### From Standard to Tailscale

1. Stop the stack in Compose Manager
2. SSH in and run:
   ```bash
   cd /mnt/user/appdata/stoat
   ./setup-unraid.sh stoat --tailscale
   # Add your TAILSCALE_AUTHKEY to .env
   ```
3. In Compose Manager, edit the stack:
   - Change compose file to: `/mnt/user/appdata/stoat/docker-compose.yml`
4. Start the stack

### From Tailscale to Standard

1. Stop the stack
2. SSH in and run:
   ```bash
   cd /mnt/user/appdata/stoat
   ./setup-unraid.sh your.domain.com
   ```
3. Edit the stack:
   - Change compose file to: `/mnt/user/appdata/stoat/docker-compose.yml`
4. Start the stack

---

## Troubleshooting

### Compose Manager not showing?
- Make sure the plugin is installed from Apps
- Try refreshing the page or restarting the Docker service

### Containers won't start?
- Check the logs in Docker → Compose → stoat → Logs
- For standard setup: Ensure ports 80/443 aren't used by another container
- For Tailscale: Check that your auth key is valid

### Tailscale not connecting?
```bash
# Check Tailscale logs
docker logs stoat-tailscale

# Common issues:
# - Auth key expired or invalid
# - Key already used (if not reusable)
```

### Need to reconfigure?
```bash
ssh root@YOUR-UNRAID-IP
cd /mnt/user/appdata/stoat

# For standard:
./setup-unraid.sh new.domain.com

# For Tailscale:
./setup-unraid.sh new-hostname --tailscale
```

Then restart the stack from the GUI.

---

## Why Can't This Be a Single Template?

Stoat requires 13+ interconnected services that share configuration and communicate with each other. Docker Compose is the right tool for orchestrating this complexity, which is why we use the Compose Manager plugin.
