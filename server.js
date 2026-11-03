'use strict';

const path = require('path');
const fs = require('fs/promises');
const express = require('express');

const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0';
const INDEX_PATH = path.join(__dirname, 'public', 'index.html');
const BUILD_TIME_TOKEN = '{{BUILD_TIME}}';

const app = express();
app.disable('x-powered-by');

app.get('/', async (req, res, next) => {
  try {
    const [stats, html] = await Promise.all([
      fs.stat(INDEX_PATH),
      fs.readFile(INDEX_PATH, 'utf8'),
    ]);
    const buildTime = stats.mtime.toISOString();
    res.type('text/html').send(html.split(BUILD_TIME_TOKEN).join(buildTime));
  } catch (err) {
    if (err.code === 'ENOENT') {
      return res.status(404).type('text/plain').send('Not Found');
    }
    return next(err);
  }
});

app.get('/health', (req, res) => {
  res.status(200).type('text/plain').send('ok');
});

app.use((req, res) => {
  res.status(404).type('text/plain').send('Not Found');
});

// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).type('text/plain').send('Internal Server Error');
});

app.listen(PORT, HOST, () => {
  console.log(`Server listening on ${HOST}:${PORT}`);
});
