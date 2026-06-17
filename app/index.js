const http = require('http');

const port = process.env.PORT || 3000;
const version = process.env.APP_VERSION || '2.0.0';
const environment = process.env.NODE_ENV || 'development';

const server = http.createServer((req, res) => {
  res.setHeader('Content-Type', 'application/json');

  if (req.url === '/health') {
    res.writeHead(200);
    res.end(JSON.stringify({
      status: 'healthy',
      uptime: Math.floor(process.uptime()),
      environment
    }));
    return;
  }

  res.writeHead(200);
  res.end(JSON.stringify({
    message: 'DevOps Fase 2 - Aplicação em funcionamento',
    version,
    environment
  }));
});

server.listen(port, () => {
  console.log(`[${new Date().toISOString()}] Servidor rodando na porta ${port} [${environment}]`);
});

module.exports = server;
