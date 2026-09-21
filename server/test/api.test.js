const http = require('http');
const assert = require('assert');
const path = require('path');
const fs = require('fs');

// Ensure clean environment for test
const { app, server } = require('../server');
const PORT = 3001; // test port

function request(options, data = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const json = body ? JSON.parse(body) : null;
          resolve({ status: res.statusCode, headers: res.headers, body: json, raw: body });
        } catch (e) {
          resolve({ status: res.statusCode, headers: res.headers, body: null, raw: body });
        }
      });
    });

    req.on('error', reject);

    if (data) {
      req.write(data);
    }
    req.end();
  });
}

async function runTests() {
  console.log('🧪 Running Server API Tests...\n');

  try {
    // 1. Test /api/status
    console.log('1. Testing GET /api/status...');
    const statusRes = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/api/status',
      method: 'GET'
    });
    assert.strictEqual(statusRes.status, 200);
    assert.strictEqual(statusRes.body.status, 'online');
    assert.ok(statusRes.body.localIp);
    console.log('   ✅ Status endpoint passed:', statusRes.body.serverUrl);

    // 2. Test /api/qr
    console.log('2. Testing GET /api/qr...');
    const qrRes = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/api/qr',
      method: 'GET'
    });
    assert.strictEqual(qrRes.status, 200);
    assert.ok(qrRes.body.qrDataUrl.startsWith('data:image/png;base64,'));
    console.log('   ✅ QR code generation passed');

    // 3. Test POST /api/posts (JSON creation)
    console.log('3. Testing POST /api/posts...');
    const postPayload = JSON.stringify({
      title: 'تست ریلز شماره ۱',
      caption: 'این یک کپشن تستی برای پست آزمایشی است #اینستاگرام #تست',
      scheduledDate: new Date().toISOString(),
      shamsiDate: '۱۴۰۳/۰۷/۰۱ - ۱۸:۰۰',
      isPosted: false
    });

    const createRes = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/api/posts',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postPayload)
      }
    }, postPayload);

    assert.strictEqual(createRes.status, 201);
    assert.ok(createRes.body.id);
    const createdId = createRes.body.id;
    console.log(`   ✅ Post created: ID = ${createdId}`);

    // 4. Test GET /api/posts
    console.log('4. Testing GET /api/posts...');
    const getRes = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/api/posts',
      method: 'GET'
    });
    assert.strictEqual(getRes.status, 200);
    assert.ok(Array.isArray(getRes.body));
    const found = getRes.body.find(p => p.id === createdId);
    assert.ok(found);
    console.log(`   ✅ Posts list returned ${getRes.body.length} posts`);

    // 5. Test PATCH /api/posts/:id/toggle (Toggle isPosted)
    console.log('5. Testing PATCH /api/posts/:id/toggle...');
    const toggleRes = await request({
      hostname: 'localhost',
      port: 3000,
      path: `/api/posts/${createdId}/toggle`,
      method: 'PATCH'
    });
    assert.strictEqual(toggleRes.status, 200);
    assert.strictEqual(toggleRes.body.isPosted, true);
    console.log('   ✅ Toggled isPosted status to true');

    // 6. Test DELETE /api/posts/:id
    console.log('6. Testing DELETE /api/posts/:id...');
    const deleteRes = await request({
      hostname: 'localhost',
      port: 3000,
      path: `/api/posts/${createdId}`,
      method: 'DELETE'
    });
    assert.strictEqual(deleteRes.status, 200);
    console.log('   ✅ Post deleted successfully');

    console.log('\n🎉 All Server API Tests Passed Successfully!\n');
  } catch (err) {
    console.error('❌ Test failed:', err);
    process.exit(1);
  } finally {
    server.close();
    process.exit(0);
  }
}

// Wait briefly for server to be up then run
setTimeout(runTests, 500);
