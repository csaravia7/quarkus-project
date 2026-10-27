import express from 'express';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const PORT = process.env.PORT || 3000;
const API_BASE_URL = (process.env.API_BASE_URL || 'http://localhost:8080').replace(/\/$/, '');

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();

app.disable('x-powered-by');
app.use(express.static(path.join(__dirname, '..', 'public')));

app.get('/health', (_req, res) => res.json({ status: 'UP' }));

// Proxy server-side hacia Quarkus: evita CORS y la autenticación de puertos privados de Codespaces
app.use('/api', express.json({ limit: '100kb' }), async (req, res) => {
  const hasBody = !['GET', 'HEAD', 'DELETE'].includes(req.method);
  try {
    const upstream = await fetch(`${API_BASE_URL}${req.originalUrl}`, {
      method: req.method,
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: hasBody ? JSON.stringify(req.body) : undefined,
      signal: AbortSignal.timeout(5000),
    });
    const contentType = upstream.headers.get('content-type');
    if (contentType) res.type(contentType);
    res.status(upstream.status).send(await upstream.text());
  } catch (err) {
    console.error('Error llamando a la API:', err.message);
    res.status(502).json({ error: 'API no disponible' });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Frontend en http://localhost:${PORT} -> API ${API_BASE_URL}`);
});
