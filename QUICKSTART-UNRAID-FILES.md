# 🚀 Unraid Files Quick Start

Get up and running with Unraid array file linking in 5 minutes!

## What You'll Get

✅ Browse files from your Unraid array in a web interface  
✅ Generate shareable links to files  
✅ Share files in Stoat chat without uploading  
✅ Secure access via Tailscale or your private network  

## Prerequisites

- Stoat already installed and running
- SSH access to your Unraid server
- Unraid shares you want to access (e.g., `/mnt/user/Media`)

## Quick Setup (3 Commands)

```bash
# 1. SSH into Unraid
ssh root@your-unraid-ip

# 2. Navigate to Stoat directory
cd /mnt/user/appdata/stoat

# 3. Run the setup script
./setup-unraid-files.sh
```

That's it! The script will:
1. Ask which shares you want to access
2. Update your `.env` configuration
3. Build the file browser service
4. Start the service

## Access the File Browser

**Tailscale mode:**
```
https://stoat/unraid/
```

**Public domain:**
```
https://your-domain.com/unraid/
```

## How to Share a File

1. **Open** the file browser (`/unraid/`)
2. **Navigate** to the file you want to share
3. **Click** the "Share" button
4. **Choose** your link format (Plain URL, Markdown, or HTML)
5. **Copy** the link
6. **Paste** in your Stoat chat

## Example Workflow

### Sharing a Movie

1. Browse to `/Media/Movies/`
2. Find `awesome-movie.mkv`
3. Click "Share" → Copy markdown link
4. Paste in Stoat: `[Watch: awesome-movie.mkv](https://stoat/unraid/files/Media/Movies/awesome-movie.mkv)`
5. Your friends click the link and watch! 🎬

### Sharing a Document

1. Browse to `/Documents/Work/`
2. Find `project-plan.pdf`
3. Click "Share" → Copy plain URL
4. Paste in Stoat: `https://stoat/unraid/files/Documents/Work/project-plan.pdf`
5. Team members can view it directly 📄

## Configuration Options

### Share All Your Files
```bash
UNRAID_SHARE_PATH=/mnt/user
```
**Pros:** Convenient, access everything  
**Cons:** Less secure, exposes all shares

### Share Specific Directories (Recommended)
```bash
UNRAID_SHARE_PATH=/mnt/user/Media
```
**Pros:** More secure, controlled access  
**Cons:** Need to add more mounts for other shares

### Share Multiple Directories

Edit `docker-compose.yml`:
```yaml
unraid-files:
  volumes:
    - /mnt/user/Movies:/unraid-shares/Movies:ro
    - /mnt/user/Music:/unraid-shares/Music:ro
    - /mnt/user/Photos:/unraid-shares/Photos:ro
```

Then restart:
```bash
docker compose up -d unraid-files
```

## Troubleshooting

### Can't see files?

**Check mount:**
```bash
docker compose exec unraid-files ls -la /unraid-shares
```

**Check permissions:**
```bash
ls -la /mnt/user/Media
```

### Service won't start?

**Check logs:**
```bash
docker compose logs unraid-files
```

**Rebuild:**
```bash
docker compose build unraid-files
docker compose up -d unraid-files
```

### Links not working?

**Verify BASE_URL:**
```bash
docker compose exec unraid-files env | grep BASE_URL
```

Should match your Tailscale hostname or domain.

## Security Tips

### ✅ DO:
- Use Tailscale mode for maximum security
- Mount shares as read-only (`:ro`)
- Only expose shares you need
- Test links with a trusted friend first

### ❌ DON'T:
- Expose sensitive personal data
- Mount `/mnt/user` unless you trust all users
- Use public domain mode for sensitive files
- Forget to check who has access to your Tailscale network

## Common Use Cases

### 🎬 Media Server
Share movies, TV shows, and music from your library
```bash
UNRAID_SHARE_PATH=/mnt/user/Media
```

### 📁 Team Collaboration
Share documents, spreadsheets, and project files
```bash
UNRAID_SHARE_PATH=/mnt/user/Documents
```

### 📸 Photo Sharing
Share photo albums with friends and family
```bash
UNRAID_SHARE_PATH=/mnt/user/Photos
```

### 💾 Download Distribution
Share downloads with your group
```bash
UNRAID_SHARE_PATH=/mnt/user/Downloads
```

## Next Steps

- 📖 Read the [full feature guide](./UNRAID-FILES-FEATURE.md) for advanced configuration
- 🔒 Review [Tailscale security settings](./TAILSCALE-SETUP.md)
- 🎨 Customize the web interface (coming soon)

## Get Help

- **Documentation:** [UNRAID-FILES-FEATURE.md](./UNRAID-FILES-FEATURE.md)
- **Issues:** GitHub Issues
- **Community:** Revolt/Stoat Discord/Chat

---

**Ready to share?** Run `./setup-unraid-files.sh` now! 🚀

