const fs = require('fs');
const path = require('path');
const chokidar = require('chokidar');
const db = require('./database');

const WATCH_DIR = path.join(__dirname, 'watch_folder');
const UPLOADS_DIR = path.join(__dirname, 'uploads');

if (!fs.existsSync(WATCH_DIR)) {
  fs.mkdirSync(WATCH_DIR, { recursive: true });
}
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Allowed extensions
const VIDEO_EXTS = ['.mp4', '.mov', '.mkv', '.avi', '.webm'];
const IMAGE_EXTS = ['.jpg', '.jpeg', '.png', '.webp'];

function initWatcher(ioOrCallback) {
  console.log(`[Watcher] Monitoring folder: ${WATCH_DIR}`);

  const watcher = chokidar.watch(WATCH_DIR, {
    ignored: /(^|[\/\\])\../, // ignore dotfiles
    persistent: true,
    awaitWriteFinish: {
      stabilityThreshold: 2000,
      pollInterval: 200
    },
    ignoreInitial: false
  });

  watcher.on('add', async (filePath) => {
    try {
      const ext = path.extname(filePath).toLowerCase();
      const baseName = path.basename(filePath, ext);
      const dirName = path.dirname(filePath);

      // Only act on video files as the primary trigger
      if (VIDEO_EXTS.includes(ext)) {
        console.log(`[Watcher] New video detected: ${path.basename(filePath)}`);

        // Check for companion cover
        let companionCover = null;
        for (const imgExt of IMAGE_EXTS) {
          const testPath = path.join(dirName, baseName + imgExt);
          if (fs.existsSync(testPath)) {
            companionCover = testPath;
            break;
          }
        }

        // Check for companion caption file (.txt)
        let captionText = '';
        let titleText = baseName.replace(/[-_]/g, ' ');
        const captionPath = path.join(dirName, baseName + '.txt');
        if (fs.existsSync(captionPath)) {
          const content = fs.readFileSync(captionPath, 'utf8').trim();
          const lines = content.split('\n');
          if (lines.length > 0 && lines[0].trim()) {
            titleText = lines[0].trim().replace(/^#+\s*/, '');
          }
          captionText = content;
        }

        // Copy video to uploads directory
        const destVideoName = `watch_${Date.now()}_${path.basename(filePath)}`;
        const destVideoPath = path.join(UPLOADS_DIR, destVideoName);
        fs.copyFileSync(filePath, destVideoPath);

        let destCoverName = null;
        if (companionCover) {
          destCoverName = `watch_${Date.now()}_${path.basename(companionCover)}`;
          const destCoverPath = path.join(UPLOADS_DIR, destCoverName);
          fs.copyFileSync(companionCover, destCoverPath);
        }

        // Check if post with this title already exists in DB to prevent duplicates
        const existing = db.getAll().find(p => p.videoFilename === destVideoName);
        if (!existing) {
          const post = db.create({
            title: titleText,
            caption: captionText,
            videoFilename: destVideoName,
            coverFilename: destCoverName,
            scheduledDate: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // defaults to tomorrow
            source: 'watch_folder',
            notes: `Imported from watch folder: ${path.basename(filePath)}`
          });

          console.log(`[Watcher] Created draft post #${post.id} (${post.title})`);
          if (typeof ioOrCallback === 'function') {
            ioOrCallback(post);
          }
        }
      }
    } catch (err) {
      console.error('[Watcher] Error processing file:', err);
    }
  });

  return watcher;
}

module.exports = { initWatcher, WATCH_DIR, UPLOADS_DIR };
