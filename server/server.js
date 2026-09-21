const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const os = require('os');
const multer = require('multer');
const QRCode = require('qrcode');
const db = require('./database');
const { initWatcher, UPLOADS_DIR } = require('./watcher');

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS and JSON parsing
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve Web Dashboard
app.use(express.static(path.join(__dirname, 'public')));

// Configure Multer for video and cover uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    if (!fs.existsSync(UPLOADS_DIR)) {
      fs.mkdirSync(UPLOADS_DIR, { recursive: true });
    }
    cb(null, UPLOADS_DIR);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    const safeName = `${Date.now()}_${Math.random().toString(36).substr(2, 6)}${ext}`;
    cb(null, safeName);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 500 * 1024 * 1024 } // 500MB max
});

// Helper: Get Local IPv4 Address
function getLocalIp() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return '127.0.0.1';
}

// -------------------------------------------------------------
// REST API
// -------------------------------------------------------------

// Server Status & Info
app.get('/api/status', (req, res) => {
  const localIp = getLocalIp();
  const allPosts = db.getAll();
  const pendingCount = allPosts.filter(p => !p.isPosted).length;
  const postedCount = allPosts.filter(p => p.isPosted).length;

  res.json({
    status: 'online',
    localIp,
    port: PORT,
    serverUrl: `http://${localIp}:${PORT}`,
    totalPosts: allPosts.length,
    pendingPosts: pendingCount,
    postedPosts: postedCount,
    currentTime: new Date().toISOString()
  });
});

// QR Code for Quick Mobile Connection
app.get('/api/qr', async (req, res) => {
  try {
    const localIp = getLocalIp();
    const serverUrl = `http://${localIp}:${PORT}`;
    const qrDataUrl = await QRCode.toDataURL(serverUrl, {
      width: 320,
      margin: 2,
      color: {
        dark: '#1e293b',
        light: '#ffffff'
      }
    });
    res.json({ serverUrl, qrDataUrl });
  } catch (err) {
    res.status(500).json({ error: 'Failed to generate QR code' });
  }
});

// Get Posts
app.get('/api/posts', (req, res) => {
  const { status } = req.query;
  const posts = db.getAll({ status });
  const localIp = getLocalIp();
  const baseUrl = `http://${localIp}:${PORT}`;

  // Enrich with full media URLs for client convenience
  const enriched = posts.map(p => ({
    ...p,
    videoUrl: p.videoFilename ? `${baseUrl}/media/${p.videoFilename}` : null,
    coverUrl: p.coverFilename ? `${baseUrl}/media/${p.coverFilename}` : null
  }));

  res.json(enriched);
});

// Get Single Post
app.get('/api/posts/:id', (req, res) => {
  const post = db.getById(req.params.id);
  if (!post) {
    return res.status(404).json({ error: 'Post not found' });
  }
  const localIp = getLocalIp();
  const baseUrl = `http://${localIp}:${PORT}`;
  res.json({
    ...post,
    videoUrl: post.videoFilename ? `${baseUrl}/media/${post.videoFilename}` : null,
    coverUrl: post.coverFilename ? `${baseUrl}/media/${post.coverFilename}` : null
  });
});

// Create Post (supports optional file uploads)
app.post('/api/posts', upload.fields([
  { name: 'video', maxCount: 1 },
  { name: 'cover', maxCount: 1 }
]), (req, res) => {
  try {
    const { title, caption, scheduledDate, shamsiDate, notes, isPosted } = req.body;

    const videoFilename = req.files?.video?.[0]?.filename || null;
    const coverFilename = req.files?.cover?.[0]?.filename || null;

    const newPost = db.create({
      title: title || 'پست جدید اینستاگرام',
      caption: caption || '',
      scheduledDate: scheduledDate || new Date().toISOString(),
      shamsiDate: shamsiDate || '',
      notes: notes || '',
      isPosted: isPosted === 'true' || isPosted === true,
      videoFilename,
      coverFilename,
      source: 'dashboard'
    });

    const localIp = getLocalIp();
    const baseUrl = `http://${localIp}:${PORT}`;
    res.status(201).json({
      ...newPost,
      videoUrl: newPost.videoFilename ? `${baseUrl}/media/${newPost.videoFilename}` : null,
      coverUrl: newPost.coverFilename ? `${baseUrl}/media/${newPost.coverFilename}` : null
    });
  } catch (err) {
    console.error('Error creating post:', err);
    res.status(500).json({ error: 'Failed to create post' });
  }
});

// Update Post
app.put('/api/posts/:id', upload.fields([
  { name: 'video', maxCount: 1 },
  { name: 'cover', maxCount: 1 }
]), (req, res) => {
  try {
    const existing = db.getById(req.params.id);
    if (!existing) {
      return res.status(404).json({ error: 'Post not found' });
    }

    const updates = { ...req.body };
    if (updates.isPosted !== undefined) {
      updates.isPosted = updates.isPosted === 'true' || updates.isPosted === true;
    }

    if (req.files?.video?.[0]) {
      updates.videoFilename = req.files.video[0].filename;
    }
    if (req.files?.cover?.[0]) {
      updates.coverFilename = req.files.cover[0].filename;
    }

    const updated = db.update(req.params.id, updates);
    const localIp = getLocalIp();
    const baseUrl = `http://${localIp}:${PORT}`;
    res.json({
      ...updated,
      videoUrl: updated.videoFilename ? `${baseUrl}/media/${updated.videoFilename}` : null,
      coverUrl: updated.coverFilename ? `${baseUrl}/media/${updated.coverFilename}` : null
    });
  } catch (err) {
    res.status(500).json({ error: 'Failed to update post' });
  }
});

// Toggle Posted Status
app.patch('/api/posts/:id/toggle', (req, res) => {
  const updated = db.togglePosted(req.params.id);
  if (!updated) {
    return res.status(404).json({ error: 'Post not found' });
  }
  const localIp = getLocalIp();
  const baseUrl = `http://${localIp}:${PORT}`;
  res.json({
    ...updated,
    videoUrl: updated.videoFilename ? `${baseUrl}/media/${updated.videoFilename}` : null,
    coverUrl: updated.coverFilename ? `${baseUrl}/media/${updated.coverFilename}` : null
  });
});

// Delete Post
app.delete('/api/posts/:id', (req, res) => {
  const deleted = db.delete(req.params.id);
  if (!deleted) {
    return res.status(404).json({ error: 'Post not found' });
  }

  // Attempt to remove media files
  if (deleted.videoFilename) {
    const p = path.join(UPLOADS_DIR, deleted.videoFilename);
    if (fs.existsSync(p)) fs.unlinkSync(p);
  }
  if (deleted.coverFilename) {
    const p = path.join(UPLOADS_DIR, deleted.coverFilename);
    if (fs.existsSync(p)) fs.unlinkSync(p);
  }

  res.json({ message: 'Post deleted successfully', id: req.params.id });
});

// -------------------------------------------------------------
// Media Streaming & Download (with HTTP Range support)
// -------------------------------------------------------------
app.get('/media/:filename', (req, res) => {
  const filename = path.basename(req.params.filename);
  const filePath = path.join(UPLOADS_DIR, filename);

  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'File not found' });
  }

  const stat = fs.statSync(filePath);
  const fileSize = stat.size;
  const ext = path.extname(filename).toLowerCase();

  // Content type mapping
  const mimeTypes = {
    '.mp4': 'video/mp4',
    '.mov': 'video/quicktime',
    '.mkv': 'video/x-matroska',
    '.webm': 'video/webm',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp'
  };
  const contentType = mimeTypes[ext] || 'application/octet-stream';

  // Support HTTP Range Requests for video seeking
  const range = req.headers.range;
  if (range && (ext === '.mp4' || ext === '.mov' || ext === '.webm' || ext === '.mkv')) {
    const parts = range.replace(/bytes=/, '').split('-');
    const start = parseInt(parts[0], 10);
    const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;

    if (start >= fileSize) {
      res.status(416).send(`Requested range not satisfiable\n${start} >= ${fileSize}`);
      return;
    }

    const chunksize = (end - start) + 1;
    const file = fs.createReadStream(filePath, { start, end });
    const head = {
      'Content-Range': `bytes ${start}-${end}/${fileSize}`,
      'Accept-Ranges': 'bytes',
      'Content-Length': chunksize,
      'Content-Type': contentType,
    };

    res.writeHead(206, head);
    file.pipe(res);
  } else {
    // Normal download / streaming
    const head = {
      'Content-Length': fileSize,
      'Content-Type': contentType,
      'Accept-Ranges': 'bytes'
    };
    res.writeHead(200, head);
    fs.createReadStream(filePath).pipe(res);
  }
});

// -------------------------------------------------------------
// Server Initialization
// -------------------------------------------------------------
const server = app.listen(PORT, '0.0.0.0', async () => {
  const localIp = getLocalIp();
  const localUrl = `http://localhost:${PORT}`;
  const lanUrl = `http://${localIp}:${PORT}`;

  console.log('====================================================');
  console.log('  🚀 Instagram Content Manager Server is Running!  ');
  console.log('====================================================');
  console.log(`  💻 PC Web Dashboard: ${localUrl}`);
  console.log(`  📱 Phone LAN Address: ${lanUrl}`);
  console.log(`  📂 Watch Folder:     ${path.join(__dirname, 'watch_folder')}`);
  console.log('----------------------------------------------------');
  console.log('  Scan this QR Code with your phone to connect:');

  try {
    const qrTerminal = await QRCode.toString(lanUrl, { type: 'terminal', small: true });
    console.log(qrTerminal);
  } catch (err) {
    // ignore terminal qr error
  }
  console.log('====================================================');

  // Start folder watcher
  initWatcher();
});

module.exports = { app, server };
