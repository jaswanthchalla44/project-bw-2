'use strict';

const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const net = require('net');
const path = require('path');
const { spawn } = require('child_process');

const SERVER_PATH = path.join(__dirname, '..', 'server.js');
const BUILD_TIME_TOKEN = '{{BUILD_TIME}}';

let child;
let baseUrl;

function getFreePort() {
  return new Promise((resolve, reject) => {
    const srv = net.createServer();
    srv.unref();
    srv.on('error', reject);
    srv.listen(0, '127.0.0.1', () => {
      const { port } = srv.address();
      srv.close(() => resolve(port));
    });
  });
}

function startServer(port) {
  return new Promise((resolve, reject) => {
    const proc = spawn(process.execPath, [SERVER_PATH], {
      env: { ...process.env, PORT: String(port) },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    let stderr = '';
    proc.stderr.on('data', (d) => { stderr += d; });
    proc.on('error', reject);
    proc.on('exit', (code) => reject(new Error(`server exited early (${code}): ${stderr}`)));
    proc.stdout.on('data', (d) => {
      if (String(d).includes('Server listening')) resolve(proc);
    });
  });
}

before(async () => {
  const port = await getFreePort();
  baseUrl = `http://127.0.0.1:${port}`;
  child = await startServer(port);
});

after(() => {
  if (child && child.exitCode === null) child.kill();
});

test('GET /health returns 200 with body "ok"', async () => {
  const res = await fetch(`${baseUrl}/health`);
  assert.equal(res.status, 200);
  assert.equal(await res.text(), 'ok');
});

test('GET / returns HTML containing "bwtest"', async () => {
  const res = await fetch(`${baseUrl}/`);
  assert.equal(res.status, 200);
  assert.match(res.headers.get('content-type'), /^text\/html/);
  const body = await res.text();
  assert.ok(body.includes('bwtest'), 'expected body to contain "bwtest"');
});

test('GET / does not contain the literal {{BUILD_TIME}} token', async () => {
  const res = await fetch(`${baseUrl}/`);
  const body = await res.text();
  assert.ok(!body.includes(BUILD_TIME_TOKEN), 'token was not substituted');
});

test('unknown path returns 404', async () => {
  const res = await fetch(`${baseUrl}/does-not-exist`);
  assert.equal(res.status, 404);
});
