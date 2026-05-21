const http = require('http');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..', 'build', 'web');
const docsRoot = path.resolve(__dirname, '..', 'docs');
const port = 3000;
const host = '127.0.0.1';

const contentTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
};

const server = http.createServer((req, res) => {
  const urlPath = decodeURIComponent(req.url.split('?')[0]);
  const isDocsPath = urlPath.startsWith('/docs/');
  const baseRoot = isDocsPath ? docsRoot : root;
  const relativePath = isDocsPath ? urlPath.replace('/docs/', '') : urlPath;
  const requestedPath = path.normalize(path.join(baseRoot, relativePath));
  const safePath = requestedPath.startsWith(baseRoot) ? requestedPath : baseRoot;
  const fallbackPath = isDocsPath
    ? path.join(docsRoot, 'project-plan.html')
    : path.join(root, 'index.html');
  const filePath =
    fs.existsSync(safePath) && fs.statSync(safePath).isFile()
      ? safePath
      : fallbackPath;

  fs.readFile(filePath, (error, data) => {
    if (error) {
      res.writeHead(500);
      res.end('Unable to read web build.');
      return;
    }

    res.writeHead(200, {
      'Content-Type': contentTypes[path.extname(filePath)] || 'application/octet-stream',
    });
    res.end(data);
  });
});

server.listen(port, host, () => {
  console.log(`Serving Flutter web build at http://${host}:${port}`);
});
