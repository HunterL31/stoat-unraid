import express from 'express';
import cors from 'cors';
import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import mime from 'mime-types';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3030;
const UNRAID_MOUNT = process.env.UNRAID_MOUNT_PATH || '/unraid-shares';
const BASE_URL = process.env.BASE_URL || 'http://localhost:3030';

// Enable CORS for the web client
app.use(cors());
app.use(express.json());

// Serve static files (the web UI)
app.use(express.static(path.join(__dirname, 'public')));

// Utility function to check if path is within allowed directory
function isPathSafe(requestedPath) {
  const resolvedPath = path.resolve(UNRAID_MOUNT, requestedPath);
  return resolvedPath.startsWith(path.resolve(UNRAID_MOUNT));
}

// Get file/folder listing
app.get('/api/browse', async (req, res) => {
  try {
    const requestedPath = req.query.path || '/';
    
    if (!isPathSafe(requestedPath)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const fullPath = path.join(UNRAID_MOUNT, requestedPath);
    
    // Check if path exists
    try {
      await fs.access(fullPath);
    } catch (err) {
      return res.status(404).json({ error: 'Path not found' });
    }

    const stat = await fs.stat(fullPath);
    
    if (!stat.isDirectory()) {
      return res.status(400).json({ error: 'Path is not a directory' });
    }

    const entries = await fs.readdir(fullPath, { withFileTypes: true });
    
    const items = await Promise.all(
      entries.map(async (entry) => {
        const itemPath = path.join(fullPath, entry.name);
        const itemStat = await fs.stat(itemPath);
        const relativePath = path.join(requestedPath, entry.name);
        
        return {
          name: entry.name,
          path: relativePath,
          isDirectory: entry.isDirectory(),
          size: itemStat.size,
          modified: itemStat.mtime,
          type: entry.isFile() ? mime.lookup(entry.name) || 'application/octet-stream' : 'directory'
        };
      })
    );

    // Sort: directories first, then files, both alphabetically
    items.sort((a, b) => {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.localeCompare(b.name);
    });

    res.json({
      currentPath: requestedPath,
      parentPath: requestedPath === '/' ? null : path.dirname(requestedPath),
      items
    });
  } catch (error) {
    console.error('Browse error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Generate a shareable link for a file
app.post('/api/link', async (req, res) => {
  try {
    const { path: filePath } = req.body;
    
    if (!filePath) {
      return res.status(400).json({ error: 'File path is required' });
    }

    if (!isPathSafe(filePath)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const fullPath = path.join(UNRAID_MOUNT, filePath);
    
    // Verify file exists
    try {
      const stat = await fs.stat(fullPath);
      if (!stat.isFile()) {
        return res.status(400).json({ error: 'Path is not a file' });
      }
    } catch (err) {
      return res.status(404).json({ error: 'File not found' });
    }

    // Generate link
    const fileUrl = `${BASE_URL}/files${filePath}`;
    const fileName = path.basename(filePath);
    
    res.json({
      url: fileUrl,
      name: fileName,
      path: filePath
    });
  } catch (error) {
    console.error('Link generation error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Serve actual files
app.get('/files/*', async (req, res) => {
  try {
    const filePath = req.path.replace('/files', '');
    
    if (!isPathSafe(filePath)) {
      return res.status(403).send('Access denied');
    }

    const fullPath = path.join(UNRAID_MOUNT, filePath);
    
    // Check if file exists
    try {
      const stat = await fs.stat(fullPath);
      if (!stat.isFile()) {
        return res.status(400).send('Not a file');
      }
    } catch (err) {
      return res.status(404).send('File not found');
    }

    // Set content type
    const mimeType = mime.lookup(fullPath) || 'application/octet-stream';
    res.setHeader('Content-Type', mimeType);
    
    // Set content disposition for downloads
    const fileName = path.basename(fullPath);
    res.setHeader('Content-Disposition', `inline; filename="${fileName}"`);

    // Stream the file
    const fileStream = await fs.readFile(fullPath);
    res.send(fileStream);
  } catch (error) {
    console.error('File serve error:', error);
    res.status(500).send('Internal server error');
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', mount: UNRAID_MOUNT });
});

app.listen(PORT, () => {
  console.log(`Unraid Files Service running on port ${PORT}`);
  console.log(`Serving files from: ${UNRAID_MOUNT}`);
  console.log(`Base URL: ${BASE_URL}`);
});

