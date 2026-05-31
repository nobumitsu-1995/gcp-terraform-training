const http = require('http');

const port = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    message: 'Hello from App Runner!',
    hostname: require('os').hostname(),
    timestamp: new Date().toISOString(),
  }));
});

server.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
