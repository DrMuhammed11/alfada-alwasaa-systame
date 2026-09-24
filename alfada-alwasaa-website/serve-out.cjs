// خادم ثابت بسيط لدليل out/ مع دعم الروابط النظيفة (clean URLs) للفحص المحلي فقط
const http = require("http");
const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "out");
const PORT = 4173;

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript",
  ".css": "text/css",
  ".webp": "image/webp",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".xml": "application/xml",
  ".txt": "text/plain",
  ".json": "application/json",
  ".ico": "image/x-icon",
  ".woff2": "font/woff2",
};

http
  .createServer((req, res) => {
    let urlPath = decodeURIComponent(req.url.split("?")[0]);
    if (urlPath.endsWith("/")) urlPath += "index.html";

    const candidates = [
      path.join(ROOT, urlPath),
      path.join(ROOT, urlPath + ".html"),
      path.join(ROOT, urlPath, "index.html"),
    ];

    for (const file of candidates) {
      if (fs.existsSync(file) && fs.statSync(file).isFile()) {
        const ext = path.extname(file).toLowerCase();
        res.writeHead(200, { "Content-Type": MIME[ext] || "application/octet-stream" });
        fs.createReadStream(file).pipe(res);
        return;
      }
    }

    // 404: قدّم صفحة 404.html إن وُجدت
    const nf = path.join(ROOT, "404.html");
    if (fs.existsSync(nf)) {
      res.writeHead(404, { "Content-Type": "text/html; charset=utf-8" });
      fs.createReadStream(nf).pipe(res);
      return;
    }
    res.writeHead(404);
    res.end("Not found");
  })
  .listen(PORT, () => console.log(`Serving out/ at http://localhost:${PORT}`));
