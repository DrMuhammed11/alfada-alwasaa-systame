// خادم ثابت بسيط لدليل out/ مع دعم الروابط النظيفة (clean URLs) وضغط gzip للفحص المحلي
const http = require("http");
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

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

const COMPRESSIBLE = new Set([
  ".html",
  ".js",
  ".css",
  ".json",
  ".svg",
  ".xml",
  ".txt",
]);

http
  .createServer((req, res) => {
    let urlPath = decodeURIComponent(req.url.split("?")[0]);
    if (urlPath.endsWith("/")) urlPath += "index.html";

    const candidates = [
      path.join(ROOT, urlPath),
      path.join(ROOT, urlPath + ".html"),
      path.join(ROOT, urlPath, "index.html"),
      path.join(ROOT, urlPath.replace(/\.__PAGE__\.txt$/, "/__PAGE__.txt")),
    ];

    for (const file of candidates) {
      if (fs.existsSync(file) && fs.statSync(file).isFile()) {
        const ext = path.extname(file).toLowerCase();
        const contentType = MIME[ext] || "application/octet-stream";
        const headers = { "Content-Type": contentType };

        const acceptEncoding = req.headers["accept-encoding"] || "";
        const shouldGzip = COMPRESSIBLE.has(ext) && acceptEncoding.includes("gzip");

        if (urlPath.includes("/_next/static/")) {
          headers["Cache-Control"] = "public, max-age=31536000, immutable";
        }

        if (shouldGzip) {
          headers["Content-Encoding"] = "gzip";
          headers["Vary"] = "Accept-Encoding";
          res.writeHead(200, headers);
          fs.createReadStream(file).pipe(zlib.createGzip({ level: 6 })).pipe(res);
        } else {
          res.writeHead(200, headers);
          fs.createReadStream(file).pipe(res);
        }
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
