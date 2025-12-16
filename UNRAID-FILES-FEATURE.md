# 📁 Unraid Array File Linking Feature

Share files from your Unraid array directly in Stoat chat! This feature allows you to browse and link to files stored on your Unraid server without having to upload them to the chat.

## 🎯 What This Does

- **Browse Unraid Shares**: Access files stored on your Unraid array through a web interface
- **Generate Share Links**: Create direct links to files that work within your Tailscale network
- **No Uploads Needed**: Share large files without using up your chat storage
- **Read-Only Access**: Files are mounted read-only for security

## 🚀 Quick Setup

### 1. Configure Your Shares

Edit your `.env` file to specify which Unraid shares to expose:

```bash
# Option 1: Mount entire /mnt/user (access all shares)
UNRAID_SHARE_PATH=/mnt/user
UNRAID_SHARE_MOUNT=/unraid-shares

# Option 2: Mount specific share only (recommended for security)
# UNRAID_SHARE_PATH=/mnt/user/Media
# UNRAID_SHARE_MOUNT=/unraid-shares/Media
```

### 2. Build and Start the Service

```bash
cd /mnt/user/appdata/stoat
docker compose build unraid-files
docker compose up -d unraid-files
```

### 3. Configure Tailscale Serve (if using Tailscale mode)

The service is automatically proxied through Caddy and Tailscale:

```bash
./tailscale-setup.sh
```

### 4. Access the File Browser

Navigate to:
- **Tailscale mode**: `https://stoat/unraid/`
- **Public domain**: `https://your.domain.com/unraid/`

## 📖 Usage Guide

### Browsing Files

1. Open the Unraid Files interface at `/unraid/`
2. Navigate through folders by clicking on them
3. Use the breadcrumb navigation to go back

### Sharing a File

1. Find the file you want to share
2. Click the **"Share"** button
3. Choose your link format:
   - **Plain URL**: Direct link (e.g., `https://stoat/unraid/files/Media/movie.mkv`)
   - **Markdown**: For markdown-compatible chats (e.g., `[movie.mkv](https://://stoat/unraid/files/Media/movie.mkv)`)
   - **HTML**: HTML anchor tag
4. Click **"Copy Link"** to copy to clipboard
5. Paste the link in your Stoat chat

### Viewing Files

Click the **"View"** button to open the file directly in your browser.

## 🔒 Security Considerations

### 1. Read-Only Access
Files are mounted read-only by default:
```yaml
volumes:
  - /mnt/user/Media:/unraid-shares/Media:ro  # :ro = read-only
```

### 2. Tailscale Security
When using Tailscale mode, file links are **only accessible** to:
- Users connected to your Tailscale network
- People you've explicitly shared your Stoat Tailscale node with

### 3. Selective Sharing
**Best Practice**: Only mount specific shares you want to access:

```yaml
# Good: Only share what's needed
volumes:
  - /mnt/user/Media:/unraid-shares/Media:ro
  - /mnt/user/Documents:/unraid-shares/Documents:ro

# Risky: Exposes everything
volumes:
  - /mnt/user:/unraid-shares:ro
```

### 4. Path Traversal Protection
The service includes built-in protection against directory traversal attacks.

## ⚙️ Advanced Configuration

### Custom Mount Points

Edit `docker-compose.yml` to configure specific mounts:

```yaml
unraid-files:
  volumes:
    # Mount specific shares
    - /mnt/user/Movies:/unraid-shares/Movies:ro
    - /mnt/user/TV:/unraid-shares/TV:ro
    - /mnt/user/Music:/unraid-shares/Music:ro
    - /mnt/user/Photos:/unraid-shares/Photos:ro
```

### Environment Variables

Configure the service in `docker-compose.yml`:

```yaml
unraid-files:
  environment:
    - PORT=3030                                      # Internal service port
    - UNRAID_MOUNT_PATH=/unraid-shares               # Base mount path inside container
    - BASE_URL=https://${TAILSCALE_HOSTNAME}/unraid  # Public URL for links
```

### Multiple Share Directories

You can mount multiple directories:

```yaml
volumes:
  # Work files
  - /mnt/user/Documents/Work:/unraid-shares/Work:ro
  # Personal media
  - /mnt/user/Media:/unraid-shares/Media:ro
  # Downloads
  - /mnt/user/Downloads:/unraid-shares/Downloads:ro
```

## 🔧 API Reference

The service exposes a REST API:

### Browse Directory
```http
GET /api/browse?path=/path/to/folder
```

**Response:**
```json
{
  "currentPath": "/Media/Movies",
  "parentPath": "/Media",
  "items": [
    {
      "name": "movie.mkv",
      "path": "/Media/Movies/movie.mkv",
      "isDirectory": false,
      "size": 1073741824,
      "modified": "2025-12-15T10:30:00.000Z",
      "type": "video/x-matroska"
    }
  ]
}
```

### Generate Share Link
```http
POST /api/link
Content-Type: application/json

{
  "path": "/Media/Movies/movie.mkv"
}
```

**Response:**
```json
{
  "url": "https://stoat/unraid/files/Media/Movies/movie.mkv",
  "name": "movie.mkv",
  "path": "/Media/Movies/movie.mkv"
}
```

### Access File
```http
GET /files/path/to/file.ext
```

Returns the file with appropriate `Content-Type` header.

## 🎨 Integrating with Stoat Chat

### Manual Sharing
1. Browse files at `/unraid/`
2. Copy the generated link
3. Paste in Stoat chat

### Custom Bot Integration (Advanced)
You can create a bot that uses the API to share files:

```javascript
// Example: Share a file via bot
const response = await fetch('https://stoat/unraid/api/link', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ path: '/Media/movie.mkv' })
});

const { url, name } = await response.json();
await sendMessageToChat(`Check out this file: [${name}](${url})`);
```

## 🐛 Troubleshooting

### Files Not Loading

**Check mount paths:**
```bash
docker compose exec unraid-files ls -la /unraid-shares
```

**Verify permissions:**
```bash
ls -la /mnt/user/Media
```

Ensure the Docker user can read the files.

### "Access Denied" Errors

Make sure the requested path is within the mounted directory and paths don't contain `..` or other traversal attempts.

### Service Won't Start

**Check logs:**
```bash
docker compose logs unraid-files
```

**Rebuild the service:**
```bash
docker compose build unraid-files
docker compose up -d unraid-files
```

### Links Not Working

**Verify BASE_URL is set correctly:**
```bash
docker compose exec unraid-files env | grep BASE_URL
```

Should match your Tailscale hostname or public domain.

## 📝 Example Use Cases

### 1. Media Sharing
Share movies, music, or photos from your media library without uploading to chat storage.

### 2. Document Collaboration
Link to shared documents in your team chat.

### 3. Download Distribution
Share files from your Downloads folder with friends on your Tailscale network.

### 4. Backup Access
Quickly access and share files from your backup directories.

## 🔄 Updating

To update the Unraid Files service:

```bash
cd /mnt/user/appdata/stoat
git pull
docker compose build unraid-files
docker compose up -d unraid-files
```

## ⚠️ Limitations

1. **No Directory Upload**: This is a read-only file browser
2. **No File Search**: Navigate through folders manually (search feature coming soon)
3. **Network Access Required**: Links only work for users with network access (Tailscale or same LAN)
4. **No Authentication**: Access control is handled at the network level (Tailscale/firewall)

## 🛠️ Future Enhancements

Planned features:
- [ ] File search functionality
- [ ] Thumbnail previews for images/videos
- [ ] Bulk link generation
- [ ] Custom file organization/favorites
- [ ] Integration with Stoat's native file picker
- [ ] Permission system for specific folders
- [ ] Temporary link expiration

## 💡 Tips

- **Use Markdown Format**: When sharing in Stoat, markdown links look cleaner: `[movie.mkv](https://://stoat/unraid/files/Media/movie.mkv)`
- **Organize Your Shares**: Create logical mount points for easier browsing
- **Test Access**: Always test links with a friend before sharing widely
- **Monitor Usage**: Check Docker logs to see what files are being accessed

## 🤝 Contributing

Found a bug or have a feature request? Open an issue on GitHub!

---

**Questions?** Check the main [README](./README.md) or [Tailscale Setup Guide](./TAILSCALE-SETUP.md).

