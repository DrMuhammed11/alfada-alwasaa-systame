const http = require('http');
const fs = require('fs');
const path = require('path');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

function createServer(port, rootDir, appName) {
  const server = http.createServer((req, res) => {
    // API Proxy to local NestJS backend
    if (req.url.startsWith('/api/v1/')) {
      const target = 'http://127.0.0.1:3000' + req.url;
      const chunks = [];
      req.on('data', c => chunks.push(c));
      req.on('end', () => {
        const headers = { ...req.headers };
        delete headers.host;
        const upReq = http.request(target, {
          method: req.method,
          headers,
        }, upRes => {
          res.writeHead(upRes.statusCode, upRes.headers);
          upRes.pipe(res);
        });
        upReq.on('error', err => {
          res.writeHead(502, { 'Content-Type': 'application/json; charset=utf-8' });
          res.end(JSON.stringify({ error: 'Backend gateway error: ' + err.message }));
        });
        if (chunks.length) upReq.write(Buffer.concat(chunks));
        upReq.end();
      });
      return;
    }

    // Static Files
    let filePath = path.join(rootDir, decodeURIComponent(req.url.split('?')[0]));
    if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
      filePath = path.join(filePath, 'index.html');
    }

    // Fallback to index.html for SPA routing
    if (!fs.existsSync(filePath)) {
      filePath = path.join(rootDir, 'index.html');
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('Not Found');
        return;
      }
      res.writeHead(200, {
        'Content-Type': contentType,
        'Cache-Control': ext === '.html' ? 'no-cache' : 'public, max-age=3600',
      });
      res.end(data);
    });
  });

  server.listen(port, '0.0.0.0', () => {
    console.log(`[${appName}] Serving on http://0.0.0.0:${port}`);
  });
}

createServer(3002, path.join(__dirname, 'al_fadaa_frontend', 'build', 'web'), 'Al-Fadaa Frontend');
createServer(3003, path.join(__dirname, 'al_fadaa_admin', 'build', 'web'), 'Al-Fadaa Admin');
