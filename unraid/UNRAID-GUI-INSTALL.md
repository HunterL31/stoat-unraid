# Installing Stoat Chat via Unraid GUI

Since Stoat is a multi-container application (13 Docker containers working together), it requires the **Docker Compose Manager** plugin rather than a traditional single-container template.

---

## Step-by-Step GUI Installation

### Step 1: Install Docker Compose Manager

1. Open your Unraid web GUI
2. Go to **Apps** (Community Applications)
3. Search for **"Docker Compose Manager"** or **"Compose.Manager"**
4. Click **Install**

---

### Step 2: Clone the Repository (One-time SSH)

The initial setup requires a quick SSH session to clone the repo and generate security keys:

```bash
# SSH into your Unraid server
ssh root@YOUR-UNRAID-IP

# Clone directly to the appdata folder
git clone https://github.com/YOUR_USERNAME/stoat-unraid.git /mnt/user/appdata/stoat
cd /mnt/user/appdata/stoat

# Run the setup script (replace with YOUR domain)
chmod +x unraid/setup-unraid.sh
./unraid/setup-unraid.sh chat.yourdomain.com

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
   - **Compose File**: `/mnt/user/appdata/stoat/unraid/docker-compose.yml`
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

## Managing Stoat from the GUI

Once installed, you can manage Stoat entirely from the Unraid GUI:

| Action | How to Do It |
|--------|--------------|
| **Start** | Docker → Compose → stoat → ▶️ Play |
| **Stop** | Docker → Compose → stoat → ⏹️ Stop |
| **Restart** | Docker → Compose → stoat → 🔄 Restart |
| **View Logs** | Docker → Compose → stoat → 📋 Logs |
| **Update** | Docker → Compose → stoat → ⬆️ Pull & Recreate |

You can also see individual container status in the main Docker tab - all Stoat containers are prefixed with `stoat-`:
- stoat-database
- stoat-redis
- stoat-rabbitmq
- stoat-minio
- stoat-caddy
- stoat-api
- stoat-events
- stoat-web
- stoat-autumn
- stoat-january
- stoat-gifbox
- stoat-crond
- stoat-pushd

---

## Updating Stoat

To pull the latest changes from your repository:

```bash
ssh root@YOUR-UNRAID-IP
cd /mnt/user/appdata/stoat
git pull
```

Then in the Unraid GUI: **Docker → Compose → stoat → Pull & Recreate**

---

## Alternative: Using Behind SWAG/NPM

If you're already using SWAG or Nginx Proxy Manager:

```bash
# During setup, use the --behind-proxy flag:
./unraid/setup-unraid.sh chat.yourdomain.com --behind-proxy --http-port 8080
```

Then configure your existing reverse proxy to forward to `stoat-caddy:80`.

---

## Troubleshooting

### Compose Manager not showing?
- Make sure the plugin is installed from Apps
- Try refreshing the page or restarting the Docker service

### Containers won't start?
- Check the logs in Docker → Compose → stoat → Logs
- Ensure ports 80/443 aren't used by another container
- Verify your domain DNS is pointing to the server

### Need to reconfigure?
```bash
ssh root@YOUR-UNRAID-IP
cd /mnt/user/appdata/stoat
./unraid/setup-unraid.sh new.domain.com
```
Then restart the stack from the GUI.

---

## Why Can't This Be a Single Template?

Stoat requires 13 interconnected services:
- MongoDB (database)
- KeyDB/Redis (cache)
- RabbitMQ (message broker)
- MinIO (file storage)
- Caddy (reverse proxy)
- API server
- WebSocket events
- Web frontend
- File server (Autumn)
- Metadata proxy (January)
- GIF proxy (Gifbox)
- Scheduled tasks (Crond)
- Push notifications (Pushd)

These all need to communicate with each other and share configuration, which is why Docker Compose is the right tool for the job!
