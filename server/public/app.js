// Global State
let posts = [];
let currentFilter = 'all';
let serverUrl = '';

// Shamsi (Jalali) Date Converter Algorithm
function gregorianToJalali(gy, gm, gd) {
  const g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  let jy = (gy <= 1600) ? 0 : 979;
  gy -= (gy <= 1600) ? 621 : 1600;
  let gy2 = (gm > 2) ? (gy + 1) : gy;
  let days = (365 * gy) + parseInt((gy2 + 3) / 4) - parseInt((gy2 + 99) / 100) + parseInt((gy2 + 399) / 400) - 80 + gd + g_d_m[gm - 1];
  jy += 33 * parseInt(days / 12053);
  days %= 12053;
  jy += 4 * parseInt(days / 1461);
  days %= 1461;
  jy += parseInt((days - 1) / 365);
  if (days > 0) days = (days - 1) % 365;
  let jm = (days < 186) ? 1 + parseInt(days / 31) : 7 + parseInt((days - 186) / 30);
  let jd = 1 + ((days < 186) ? (days % 31) : ((days - 186) % 30));
  return [jy, jm, jd];
}

const PERSIAN_MONTHS = [
  'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
  'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
];

const PERSIAN_WEEKDAYS = [
  'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه', 'شنبه'
];

function formatShamsiDate(isoDateStr) {
  if (!isoDateStr) return '';
  const d = new Date(isoDateStr);
  if (isNaN(d.getTime())) return '';

  const [jy, jm, jd] = gregorianToJalali(d.getFullYear(), d.getMonth() + 1, d.getDate());
  const monthName = PERSIAN_MONTHS[jm - 1];
  const weekday = PERSIAN_WEEKDAYS[d.getDay()];
  const hours = String(d.getHours()).padStart(2, '0');
  const minutes = String(d.getMinutes()).padStart(2, '0');

  return `${weekday} ${jd} ${monthName} ${jy} - ساعت ${hours}:${minutes}`;
}

// Initialization
document.addEventListener('DOMContentLoaded', () => {
  fetchServerStatus();
  fetchPosts();
  initDatePickers();
});

// Setup Default Date
function initDatePickers() {
  const dateInput = document.getElementById('form-date');
  const shamsiInput = document.getElementById('form-shamsi-date');

  // Set default to tomorrow at 18:00
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(18, 0, 0, 0);

  const localIso = new Date(tomorrow.getTime() - tomorrow.getTimezoneOffset() * 60000)
    .toISOString()
    .slice(0, 16);
  dateInput.value = localIso;
  shamsiInput.value = formatShamsiDate(tomorrow.toISOString());

  dateInput.addEventListener('change', (e) => {
    if (e.target.value) {
      shamsiInput.value = formatShamsiDate(e.target.value);
    }
  });
}

// Fetch Server Status & QR Info
async function fetchServerStatus() {
  try {
    const res = await fetch('/api/status');
    const data = await res.json();
    serverUrl = data.serverUrl;

    document.getElementById('server-ip-display').textContent = `${data.localIp}:${data.port}`;
    document.getElementById('stat-total').textContent = data.totalPosts;
    document.getElementById('stat-pending').textContent = data.pendingPosts;
    document.getElementById('stat-posted').textContent = data.postedPosts;

    const qrRes = await fetch('/api/qr');
    const qrData = await qrRes.json();
    document.getElementById('qr-image').src = qrData.qrDataUrl;
    document.getElementById('qr-server-url').textContent = qrData.serverUrl;
  } catch (err) {
    console.error('Error fetching server status:', err);
    document.getElementById('server-ip-display').textContent = 'خطا در ارتباط';
  }
}

// Fetch Posts List
async function fetchPosts() {
  try {
    const res = await fetch('/api/posts');
    posts = await res.json();
    renderPosts();
  } catch (err) {
    console.error('Error fetching posts:', err);
  }
}

// Filter Posts
function setFilter(filter) {
  currentFilter = filter;
  document.querySelectorAll('.filter-btn').forEach(btn => {
    btn.classList.remove('bg-pink-600', 'text-white');
    btn.classList.add('text-slate-400');
  });

  const activeBtn = document.getElementById(`filter-${filter}`);
  if (activeBtn) {
    activeBtn.classList.remove('text-slate-400');
    activeBtn.classList.add('bg-pink-600', 'text-white');
  }

  renderPosts();
}

// Render Posts Cards
function renderPosts() {
  const container = document.getElementById('posts-container');
  const emptyState = document.getElementById('empty-state');

  let filtered = posts;
  if (currentFilter === 'pending') {
    filtered = posts.filter(p => !p.isPosted);
  } else if (currentFilter === 'posted') {
    filtered = posts.filter(p => p.isPosted);
  }

  if (filtered.length === 0) {
    container.innerHTML = '';
    emptyState.classList.remove('hidden');
    return;
  }

  emptyState.classList.add('hidden');
  container.innerHTML = filtered.map(post => {
    const shamsi = post.shamsiDate || formatShamsiDate(post.scheduledDate);
    const isPostedClass = post.isPosted ? 'border-emerald-500/40' : 'border-slate-700/60';
    const statusBadge = post.isPosted
      ? `<span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
           <i data-lucide="check" class="w-3.5 h-3.5"></i> منتشر شده
         </span>`
      : `<span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-500/10 text-amber-400 border border-amber-500/20">
           <i data-lucide="clock" class="w-3.5 h-3.5"></i> در انتظار انتشار
         </span>`;

    // Video preview or Cover Image
    let mediaPreview = '';
    if (post.videoUrl) {
      mediaPreview = `
        <div class="relative bg-black rounded-xl overflow-hidden aspect-video group">
          <video controls preload="metadata" poster="${post.coverUrl || ''}" class="w-full h-full object-cover">
            <source src="${post.videoUrl}" type="video/mp4">
            مرورگر شما از پخش ویدیو پشتیبانی نمی‌کند.
          </video>
        </div>
      `;
    } else if (post.coverUrl) {
      mediaPreview = `
        <div class="relative bg-slate-900 rounded-xl overflow-hidden aspect-video">
          <img src="${post.coverUrl}" alt="${post.title}" class="w-full h-full object-cover">
        </div>
      `;
    } else {
      mediaPreview = `
        <div class="bg-slate-900 rounded-xl aspect-video flex items-center justify-center text-slate-500 border border-dashed border-slate-700">
          <div class="text-center">
            <i data-lucide="film" class="w-8 h-8 mx-auto mb-1"></i>
            <span class="text-xs">بدون فایل رسانه</span>
          </div>
        </div>
      `;
    }

    return `
      <div class="bg-slate-800/80 border ${isPostedClass} rounded-2xl p-5 flex flex-col justify-between shadow-lg hover:border-pink-500/30 transition">
        <div>
          <!-- Media Preview -->
          <div class="mb-4">
            ${mediaPreview}
          </div>

          <!-- Header & Status -->
          <div class="flex items-center justify-between gap-2 mb-2">
            <h3 class="font-bold text-white text-base truncate">${escapeHtml(post.title)}</h3>
            ${statusBadge}
          </div>

          <!-- Shamsi Date -->
          <div class="flex items-center gap-1.5 text-xs text-pink-300/90 mb-3 font-mono">
            <i data-lucide="calendar" class="w-3.5 h-3.5"></i>
            <span>${shamsi}</span>
          </div>

          <!-- Caption Preview -->
          <div class="bg-slate-900/60 rounded-xl p-3 border border-slate-700/40 text-xs text-slate-300 leading-relaxed mb-4 max-h-24 overflow-y-auto whitespace-pre-line">
            ${post.caption ? escapeHtml(post.caption) : '<span class="text-slate-500 italic">بدون کپشن</span>'}
          </div>
        </div>

        <!-- Footer Actions -->
        <div class="pt-3 border-t border-slate-700/60 flex items-center justify-between gap-2">
          <!-- Toggle Posted Checkbox -->
          <label class="flex items-center gap-2 text-xs text-slate-300 cursor-pointer select-none">
            <input type="checkbox" ${post.isPosted ? 'checked' : ''} onchange="togglePostStatus('${post.id}')" class="w-4 h-4 rounded text-pink-600 bg-slate-900 border-slate-600 focus:ring-pink-500">
            <span>منتشر شد</span>
          </label>

          <div class="flex items-center gap-1">
            <!-- Copy Caption Button -->
            ${post.caption ? `
              <button onclick="copyCaption('${escapeAttr(post.caption)}')" title="کپی کپشن" class="p-2 text-slate-400 hover:text-white hover:bg-slate-700 rounded-lg transition">
                <i data-lucide="copy" class="w-4 h-4"></i>
              </button>
            ` : ''}

            <!-- Delete Button -->
            <button onclick="deletePost('${post.id}')" title="حذف پست" class="p-2 text-rose-400 hover:text-rose-300 hover:bg-rose-500/10 rounded-lg transition">
              <i data-lucide="trash-2" class="w-4 h-4"></i>
            </button>
          </div>
        </div>
      </div>
    `;
  }).join('');

  lucide.createIcons();
}

// Create New Post Handler
async function handleCreatePost(e) {
  e.preventDefault();
  const submitBtn = document.getElementById('submit-btn');
  submitBtn.disabled = true;
  submitBtn.innerHTML = '<span class="animate-spin inline-block mr-2">⏳</span> در حال ارسال...';

  try {
    const formData = new FormData();
    formData.append('title', document.getElementById('form-title').value);
    formData.append('scheduledDate', document.getElementById('form-date').value);
    formData.append('shamsiDate', document.getElementById('form-shamsi-date').value);
    formData.append('caption', document.getElementById('form-caption').value);
    formData.append('isPosted', document.getElementById('form-is-posted').checked);

    const videoInput = document.getElementById('form-video');
    if (videoInput.files[0]) {
      formData.append('video', videoInput.files[0]);
    }

    const coverInput = document.getElementById('form-cover');
    if (coverInput.files[0]) {
      formData.append('cover', coverInput.files[0]);
    }

    const res = await fetch('/api/posts', {
      method: 'POST',
      body: formData
    });

    if (!res.ok) throw new Error('Failed to create post');

    closeNewPostModal();
    document.getElementById('post-form').reset();
    initDatePickers();
    await fetchServerStatus();
    await fetchPosts();
  } catch (err) {
    alert('خطا در ذخیره پست: ' + err.message);
  } finally {
    submitBtn.disabled = false;
    submitBtn.innerHTML = '<i data-lucide="check" class="w-4 h-4"></i><span>ذخیره پست</span>';
    lucide.createIcons();
  }
}

// Toggle Status
async function togglePostStatus(id) {
  try {
    const res = await fetch(`/api/posts/${id}/toggle`, { method: 'PATCH' });
    if (!res.ok) throw new Error('Failed to toggle status');
    await fetchServerStatus();
    await fetchPosts();
  } catch (err) {
    alert('خطا در تغییر وضعیت: ' + err.message);
  }
}

// Delete Post
async function deletePost(id) {
  if (!confirm('آیا از حذف این پست اطمینان دارید؟')) return;
  try {
    const res = await fetch(`/api/posts/${id}`, { method: 'DELETE' });
    if (!res.ok) throw new Error('Failed to delete');
    await fetchServerStatus();
    await fetchPosts();
  } catch (err) {
    alert('خطا در حذف: ' + err.message);
  }
}

// Modal Handlers
function openNewPostModal() {
  document.getElementById('new-post-modal').classList.remove('hidden');
}

function closeNewPostModal() {
  document.getElementById('new-post-modal').classList.add('hidden');
}

function openQrModal() {
  document.getElementById('qr-modal').classList.remove('hidden');
}

function closeQrModal() {
  document.getElementById('qr-modal').classList.add('hidden');
}

function updateFileName(input, targetId) {
  if (input.files[0]) {
    document.getElementById(targetId).textContent = input.files[0].name;
  }
}

function updateCaptionCount() {
  const text = document.getElementById('form-caption').value;
  document.getElementById('caption-counter').textContent = `${text.length} کاراکتر`;
}

function copyCaption(text) {
  navigator.clipboard.writeText(text).then(() => {
    alert('متن کپشن با موفقیت کپی شد.');
  }).catch(err => {
    console.error('Clipboard error:', err);
  });
}

function copyServerUrl() {
  const url = document.getElementById('qr-server-url').textContent;
  navigator.clipboard.writeText(url).then(() => {
    alert('آدرس سرور کپی شد: ' + url);
  });
}

// Escape HTML for XSS prevention
function escapeHtml(str) {
  if (!str) return '';
  return str.replace(/[&<>'"]/g, 
    tag => ({
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      "'": '&#39;',
      '"': '&quot;'
    }[tag] || tag)
  );
}

function escapeAttr(str) {
  if (!str) return '';
  return str.replace(/'/g, "\\'").replace(/\n/g, '\\n');
}
