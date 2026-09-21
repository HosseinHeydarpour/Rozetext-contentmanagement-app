const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, 'data');
const DB_FILE = path.join(DATA_DIR, 'posts.json');

// Ensure data directory and file exist
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

if (!fs.existsSync(DB_FILE)) {
  fs.writeFileSync(DB_FILE, JSON.stringify([], null, 2), 'utf8');
}

class Database {
  constructor() {
    this.filePath = DB_FILE;
  }

  _read() {
    try {
      const content = fs.readFileSync(this.filePath, 'utf8');
      return JSON.parse(content || '[]');
    } catch (err) {
      console.error('Error reading database:', err);
      return [];
    }
  }

  _write(data) {
    try {
      fs.writeFileSync(this.filePath, JSON.stringify(data, null, 2), 'utf8');
      return true;
    } catch (err) {
      console.error('Error writing database:', err);
      return false;
    }
  }

  getAll(options = {}) {
    let posts = this._read();
    
    if (options.status === 'posted') {
      posts = posts.filter(p => p.isPosted);
    } else if (options.status === 'pending') {
      posts = posts.filter(p => !p.isPosted);
    }

    // Sort by scheduledDate ascending by default
    posts.sort((a, b) => {
      const timeA = new Date(a.scheduledDate || a.createdAt).getTime();
      const timeB = new Date(b.scheduledDate || b.createdAt).getTime();
      return timeA - timeB;
    });

    return posts;
  }

  getById(id) {
    const posts = this._read();
    return posts.find(p => p.id === id) || null;
  }

  create(postData) {
    const posts = this._read();
    const newPost = {
      id: postData.id || `post_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`,
      title: postData.title || 'Untitled Post',
      caption: postData.caption || '',
      videoFilename: postData.videoFilename || null,
      coverFilename: postData.coverFilename || null,
      scheduledDate: postData.scheduledDate || new Date().toISOString(),
      shamsiDate: postData.shamsiDate || '',
      isPosted: Boolean(postData.isPosted),
      postedAt: postData.isPosted ? (postData.postedAt || new Date().toISOString()) : null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      source: postData.source || 'dashboard',
      notes: postData.notes || ''
    };

    posts.push(newPost);
    this._write(posts);
    return newPost;
  }

  update(id, updates) {
    const posts = this._read();
    const index = posts.findIndex(p => p.id === id);
    if (index === -1) return null;

    const current = posts[index];
    const updated = {
      ...current,
      ...updates,
      updatedAt: new Date().toISOString()
    };

    // If isPosted changed to true and postedAt not set
    if (updates.isPosted === true && !current.isPosted && !updates.postedAt) {
      updated.postedAt = new Date().toISOString();
    } else if (updates.isPosted === false) {
      updated.postedAt = null;
    }

    posts[index] = updated;
    this._write(posts);
    return updated;
  }

  delete(id) {
    const posts = this._read();
    const postToDelete = posts.find(p => p.id === id);
    if (!postToDelete) return null;

    const filtered = posts.filter(p => p.id !== id);
    this._write(filtered);
    return postToDelete;
  }

  togglePosted(id) {
    const post = this.getById(id);
    if (!post) return null;
    return this.update(id, { isPosted: !post.isPosted });
  }
}

module.exports = new Database();
