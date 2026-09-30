// Static file server for build/web on port 5010 (test-only helper)
// + same-origin API proxy to the cloud backend (avoids CORS during local testing)
const http = require('http');
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, 'build', 'web');
const PORT = 5010;
const API_PREFIX = '/api/v1/';
const CLOUD_API = 'https://alfada-alwasaa-systame.onrender.com/api/v1/';

function proxyApi(req, res) {
  const target = CLOUD_API + req.url.slice(API_PREFIX.length);
  const chunks = [];
  req.on('data', (c) => chunks.push(c));
  req.on('end', () => {
    const headers = { ...(req.headers || {}) };
    delete headers.host; delete headers.origin; delete headers.referer;
    delete headers['content-length'];
    if (chunks.length) headers['content-length'] = Buffer.byteLength(Buffer.concat(chunks));
    fetch(target, {
      method: req.method,
      headers,
      body: ['GET', 'HEAD'].includes(req.method) ? undefined : Buffer.concat(chunks),
    }).then(async (up) => {
      const buf = Buffer.from(await up.arrayBuffer());
      const outHeaders = {};
      up.headers.forEach((v, k) => { if (!['content-encoding', 'transfer-encoding', 'content-length'].includes(k)) outHeaders[k] = v; });
      outHeaders['content-length'] = buf.length;
      res.writeHead(up.status, outHeaders);
      res.end(buf);
    }).catch((e) => {
      res.writeHead(502, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ message: `proxy error: ${e.message}` }));
    });
  });
}
const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.mjs': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.wasm': 'application/wasm',
  '.map': 'application/json',
};

http.createServer((req, res) => {
  if (req.url.startsWith(API_PREFIX)) { proxyApi(req, res); return; }
  let urlPath = decodeURIComponent(req.url.split('?')[0]);
  if (urlPath.endsWith('/')) urlPath += 'index.html';
  let filePath = path.normalize(path.join(ROOT, urlPath));
  if (!filePath.startsWith(ROOT)) {
    res.writeHead(403); res.end('Forbidden'); return;
  }
  fs.stat(filePath, (err, st) => {
    if (err || !st.isFile()) {
      // SPA fallback to index.html
      filePath = path.join(ROOT, 'index.html');
    }
    fs.readFile(filePath, (err2, data) => {
      if (err2) { res.writeHead(404); res.end('Not found'); return; }
      res.writeHead(200, { 'Content-Type': MIME[path.extname(filePath)] || 'application/octet-stream' });
      res.end(data);
    });
  });
}).listen(PORT, '0.0.0.0', () => console.log(`Serving ${ROOT} at http://localhost:${PORT}`));
