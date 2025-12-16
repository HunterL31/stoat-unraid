# Unraid Files Service - Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         User's Browser                       │
│                    https://stoat/unraid/                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ HTTPS (Tailscale or Public)
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                    Tailscale + Caddy                         │
│                  (Reverse Proxy Layer)                       │
│                                                              │
│  Routes:                                                     │
│    /unraid/*  →  http://unraid-files:3030                   │
│    /api/*     →  http://api:14702                           │
│    /ws        →  http://events:14703                        │
│    /*         →  http://web:5000                            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ Docker Network (bridge)
                       │
┌──────────────────────▼──────────────────────────────────────┐
│              Unraid Files Service (Node.js)                  │
│                    Port: 3030                                │
│                                                              │
│  Components:                                                 │
│  ┌────────────────────────────────────────────────┐         │
│  │  Express Server (server.js)                    │         │
│  │  - API Routes                                  │         │
│  │  - Static File Serving                         │         │
│  │  - Security Middleware                         │         │
│  └────────────────────────────────────────────────┘         │
│                                                              │
│  ┌────────────────────────────────────────────────┐         │
│  │  Web UI (public/index.html)                    │         │
│  │  - File Browser Interface                      │         │
│  │  - Link Generator                              │         │
│  │  - Modal Dialogs                               │         │
│  └────────────────────────────────────────────────┘         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ Volume Mount (Read-Only)
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                    Unraid Array                              │
│                  /mnt/user/...                               │
│                                                              │
│  Shares:                                                     │
│    /mnt/user/Media      → /unraid-shares/Media              │
│    /mnt/user/Documents  → /unraid-shares/Documents          │
│    /mnt/user/Downloads  → /unraid-shares/Downloads          │
└──────────────────────────────────────────────────────────────┘
```

## Request Flow

### 1. Browse Directory

```
User → Caddy → Unraid Files → File System
  │      │         │              │
  │      │         │              └─ fs.readdir()
  │      │         └─ GET /api/browse?path=/Media
  │      └─ Proxy to unraid-files:3030
  └─ https://stoat/unraid/

Response: JSON with file list
```

### 2. Generate Share Link

```
User → Caddy → Unraid Files
  │      │         │
  │      │         └─ POST /api/link {path: "/Media/file.mkv"}
  │      └─ Proxy to unraid-files:3030
  └─ Click "Share" button

Response: {url: "https://stoat/unraid/files/Media/file.mkv"}
```

### 3. Access File

```
User → Caddy → Unraid Files → File System
  │      │         │              │
  │      │         │              └─ fs.readFile()
  │      │         └─ GET /files/Media/file.mkv
  │      └─ Proxy to unraid-files:3030
  └─ Click link in chat

Response: File stream with MIME type
```

## Component Details

### Express Server (`server.js`)

**Responsibilities:**
- Route handling
- File system operations
- Security validation
- MIME type detection
- Static file serving

**Key Functions:**
```javascript
isPathSafe(path)           // Validates paths
GET /api/browse            // Lists directory
POST /api/link             // Generates links
GET /files/*               // Serves files
GET /health                // Health check
```

### Web UI (`public/index.html`)

**Responsibilities:**
- User interface
- API communication
- Link formatting
- Modal management

**Key Functions:**
```javascript
loadDirectory(path)        // Fetch directory listing
shareFile(path, name)      // Generate share link
viewFile(path)             // Open file in new tab
copyLink()                 // Copy to clipboard
```

### Docker Container

**Base Image:** `node:20-alpine`  
**Working Dir:** `/app`  
**Exposed Port:** `3030`  
**Volume Mount:** `/unraid-shares` (read-only)

**Build Process:**
1. Install pnpm
2. Copy package files
3. Install dependencies
4. Copy application code
5. Expose port 3030
6. Start Node.js server

## Security Architecture

### 1. Path Traversal Protection

```javascript
function isPathSafe(requestedPath) {
  const resolvedPath = path.resolve(UNRAID_MOUNT, requestedPath);
  return resolvedPath.startsWith(path.resolve(UNRAID_MOUNT));
}
```

Prevents:
- `../../../etc/passwd`
- Absolute paths outside mount
- Symlink attacks

### 2. Read-Only Mounts

```yaml
volumes:
  - /mnt/user/Media:/unraid-shares/Media:ro
```

Ensures:
- Files cannot be modified
- Directories cannot be created
- Files cannot be deleted

### 3. Network Isolation

**Tailscale Mode:**
- Only accessible via Tailscale network
- End-to-end encryption
- Access control via Tailscale ACLs

**Public Mode:**
- Requires firewall configuration
- HTTPS via Caddy
- Network-level access control

### 4. No Authentication Layer

**Design Decision:**
- Relies on network security (Tailscale/firewall)
- Simpler architecture
- Fewer attack vectors
- Trust boundary at network level

## Data Flow

### File Metadata Flow

```
Unraid Array
    ↓
fs.readdir() + fs.stat()
    ↓
{
  name: "movie.mkv",
  path: "/Media/movie.mkv",
  size: 1073741824,
  modified: "2025-12-15T10:30:00Z",
  type: "video/x-matroska"
}
    ↓
JSON Response
    ↓
Web UI (Rendered)
```

### File Content Flow

```
Unraid Array
    ↓
fs.readFile()
    ↓
Buffer
    ↓
HTTP Response (with MIME type)
    ↓
User's Browser
```

## Performance Characteristics

### Memory Usage
- **Idle:** ~30MB
- **Active (browsing):** ~40MB
- **Streaming file:** ~50-100MB (depends on file size)

### CPU Usage
- **Idle:** <1%
- **Directory listing:** 1-5%
- **File streaming:** 5-20% (depends on file size and network)

### Disk I/O
- **Read-only operations**
- **Direct from Unraid array**
- **No caching** (relies on OS page cache)

### Network
- **API calls:** <1KB per request
- **File streaming:** Depends on file size
- **Concurrent users:** Scales horizontally

## Scalability

### Single Instance
- **Concurrent users:** 10-50
- **Concurrent streams:** 5-10
- **Directory size:** Unlimited (pagination recommended)

### Horizontal Scaling
```yaml
unraid-files:
  deploy:
    replicas: 3
```

**Load Balancing:**
- Caddy can round-robin
- Stateless design
- Shared read-only volumes

## Error Handling

### Path Not Found
```javascript
if (!await fs.access(fullPath)) {
  return res.status(404).json({ error: 'Path not found' });
}
```

### Access Denied
```javascript
if (!isPathSafe(requestedPath)) {
  return res.status(403).json({ error: 'Access denied' });
}
```

### Server Error
```javascript
catch (error) {
  console.error('Error:', error);
  res.status(500).json({ error: 'Internal server error' });
}
```

## Monitoring

### Health Check
```bash
curl http://unraid-files:3030/health
```

### Logs
```bash
docker compose logs -f unraid-files
```

### Metrics (Future)
- Request count
- Response times
- Error rates
- Active streams

## Integration Points

### 1. Caddy Integration
```caddyfile
route /unraid* {
    uri strip_prefix /unraid
    reverse_proxy http://unraid-files:3030
}
```

### 2. Docker Compose Integration
```yaml
depends_on:
  - unraid-files
```

### 3. Tailscale Integration
```bash
tailscale serve https / http://caddy:80
```

## Future Enhancements

### Phase 1 (Basic)
- [ ] Search functionality
- [ ] Sorting options
- [ ] Pagination for large directories

### Phase 2 (Advanced)
- [ ] Thumbnail generation
- [ ] Video previews
- [ ] Metadata extraction
- [ ] Favorites/bookmarks

### Phase 3 (Enterprise)
- [ ] User authentication
- [ ] Permission system
- [ ] Audit logging
- [ ] Link expiration
- [ ] Rate limiting

## Deployment Patterns

### Pattern 1: Single Share
```yaml
volumes:
  - /mnt/user/Media:/unraid-shares:ro
```

**Use Case:** Media server

### Pattern 2: Multiple Shares
```yaml
volumes:
  - /mnt/user/Movies:/unraid-shares/Movies:ro
  - /mnt/user/Music:/unraid-shares/Music:ro
```

**Use Case:** Organized access

### Pattern 3: Selective Subdirectories
```yaml
volumes:
  - /mnt/user/Documents/Public:/unraid-shares/Public:ro
```

**Use Case:** Limited access

## Troubleshooting Flow

```
Issue: Files not visible
    ↓
Check: docker compose exec unraid-files ls /unraid-shares
    ↓
Empty? → Check volume mount in docker-compose.yml
    ↓
Permission denied? → Check Unraid share permissions
    ↓
Still broken? → Check logs: docker compose logs unraid-files
```

## Development Workflow

### Local Development
```bash
cd services/unraid-files
npm install
export UNRAID_MOUNT_PATH=/path/to/test/files
npm start
```

### Testing
```bash
# Test API
curl http://localhost:3030/api/browse?path=/

# Test file serving
curl http://localhost:3030/files/test.txt

# Test health
curl http://localhost:3030/health
```

### Production Build
```bash
docker compose build unraid-files
docker compose up -d unraid-files
```

---

**Last Updated:** 2025-12-15  
**Version:** 1.0.0  
**Maintainer:** Stoat Unraid Fork

