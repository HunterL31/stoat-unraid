# Unraid Files Service

A lightweight file browsing and linking service for Stoat Chat on Unraid.

## Overview

This Node.js/Express service allows you to:
- Browse files stored on your Unraid array
- Generate shareable links to files
- Serve files to authorized users on your network

## Features

- 🔒 **Read-only access** - Files are never modified
- 🛡️ **Path traversal protection** - Built-in security
- 🎨 **Modern web UI** - Clean, responsive interface
- 📎 **Multiple link formats** - Plain URL, Markdown, or HTML
- 🚀 **Fast and lightweight** - Minimal resource usage

## Tech Stack

- **Runtime**: Node.js 20
- **Framework**: Express.js
- **Container**: Docker (Alpine Linux)

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3030` | Internal service port |
| `UNRAID_MOUNT_PATH` | `/unraid-shares` | Base path for mounted shares |
| `BASE_URL` | `http://localhost:3030` | Public URL for generated links |

## API Endpoints

### `GET /api/browse`
Browse a directory.

**Query Parameters:**
- `path` (optional): Directory path to browse (default: `/`)

**Response:**
```json
{
  "currentPath": "/Media",
  "parentPath": "/",
  "items": [...]
}
```

### `POST /api/link`
Generate a shareable link.

**Request Body:**
```json
{
  "path": "/Media/movie.mkv"
}
```

**Response:**
```json
{
  "url": "https://stoat/unraid/files/Media/movie.mkv",
  "name": "movie.mkv",
  "path": "/Media/movie.mkv"
}
```

### `GET /files/*`
Serve a file.

**Example:** `GET /files/Media/movie.mkv`

Returns the file with appropriate MIME type.

### `GET /health`
Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "mount": "/unraid-shares"
}
```

## Development

### Local Testing

```bash
# Install dependencies
npm install

# Set environment variables
export UNRAID_MOUNT_PATH=/path/to/test/files
export BASE_URL=http://localhost:3030

# Run the server
npm start
```

### Docker Build

```bash
# Build the image
docker build -t stoat-unraid-files .

# Run the container
docker run -d \
  -p 3030:3030 \
  -v /mnt/user:/unraid-shares:ro \
  -e BASE_URL=https://your-domain.com/unraid \
  stoat-unraid-files
```

## Security Notes

1. **Always mount volumes as read-only** (`:ro`)
2. The service validates all paths to prevent directory traversal
3. No authentication is built-in - rely on network security (Tailscale, firewall)
4. Only expose necessary directories

## File Structure

```
unraid-files/
├── server.js          # Main Express server
├── package.json       # Dependencies
├── Dockerfile         # Container definition
├── .dockerignore      # Docker build exclusions
├── public/
│   └── index.html     # Web UI
└── README.md          # This file
```

## License

Same as parent project (Stoat/Revolt).

