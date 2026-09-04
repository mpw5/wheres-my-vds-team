import test from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { fileURLToPath } from 'node:url';

async function startNextServer(scraperBaseUrl) {
  const port = 5100 + Math.floor(Math.random() * 1000);
  const serverProcess = spawn(process.execPath, [fileURLToPath(new URL('../node_modules/next/dist/bin/next', import.meta.url)), 'dev', '-p', String(port)], {
    cwd: new URL('..', import.meta.url),
    env: { ...process.env, POC_DATA_DIR: `.data/test-${port}`, SCRAPER_BASE_URL: scraperBaseUrl ?? '' },
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  await new Promise((resolve, reject) => {
    const output = (chunk) => {
      if (chunk.toString().includes('Ready')) resolve();
    };
    serverProcess.stdout.on('data', output);
    serverProcess.stderr.on('data', output);
    serverProcess.once('error', reject);
  });

  return { process: serverProcess, port };
}

async function fetchPage(url) {
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const response = await fetch(url);
    if (response.status !== 404) return response;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }

  return fetch(url);
}

async function startScraperSource() {
  const source = createServer((request, response) => {
    response.writeHead(200, { 'content-type': 'text/html' });
    response.end('<table><tr><td><a href="/profile/wout-van-aert">Wout van Aert</a></td></tr></table>');
  });
  await new Promise((resolve) => source.listen(0, '127.0.0.1', resolve));
  return { source, port: source.address().port };
}

async function startFailingScraperSource() {
  const source = createServer((request, response) => {
    response.writeHead(503);
    response.end();
  });
  await new Promise((resolve) => source.listen(0, '127.0.0.1', resolve));
  return { source, port: source.address().port };
}

test('a matching team sees its upcoming races with dates and source links', async (t) => {
  const source = await startScraperSource();
  const server = await startNextServer(`http://127.0.0.1:${source.port}`);
  t.after(() => {
    server.process.kill();
    source.source.close();
  });

  const response = await fetchPage(`http://127.0.0.1:${server.port}/?team_ds=Team%20Baby%20Turtles`);
  const html = await response.text();

  assert.equal(response.status, 200);
  assert.match(html, /GP Industria &amp; Artigianato/);
  assert.match(html, /06\/09\/2026/);
  assert.match(html, /https:\/\/cyclingflash\.com\/race\/gp-industria-artigianato-2026\/startlist/);
});

test('a matching rider from a live startlist is shown', async (t) => {
  const source = await startScraperSource();
  const server = await startNextServer(`http://127.0.0.1:${source.port}`);
  t.after(() => {
    server.process.kill();
    source.source.close();
  });

  const response = await fetchPage(`http://127.0.0.1:${server.port}/?team_ds=Team%20Baby%20Turtles`);
  const html = await response.text();

  assert.equal(response.status, 200);
  assert.match(html, /Wout Van Aert/);
});

test('a failed startlist refresh keeps the page available', async (t) => {
  const source = await startFailingScraperSource();
  const server = await startNextServer(`http://127.0.0.1:${source.port}`);
  t.after(() => {
    server.process.kill();
    source.source.close();
  });

  const response = await fetchPage(`http://127.0.0.1:${server.port}/?team_ds=Team%20Baby%20Turtles`);
  const html = await response.text();

  assert.equal(response.status, 200);
  assert.match(html, /No riders found/);
});
