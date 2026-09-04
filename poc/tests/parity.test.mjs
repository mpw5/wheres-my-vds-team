import test from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

async function startNextServer() {
  const port = 6100 + Math.floor(Math.random() * 1000);
  const serverProcess = spawn(process.execPath, [fileURLToPath(new URL('../node_modules/next/dist/bin/next', import.meta.url)), 'dev', '-p', String(port)], {
    cwd: new URL('..', import.meta.url),
    env: { ...process.env, POC_DATA_DIR: `.data/test-${port}`, POC_DISABLE_STARTUP_PREFETCH: 'true', SCRAPER_BASE_URL: 'http://127.0.0.1:1' },
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

test('the POC preserves the Rails-visible page contract', async (t) => {
  const server = await startNextServer();
  t.after(() => server.process.kill());

  const response = await fetchPage(`http://127.0.0.1:${server.port}/?team_ds=Team%20Baby%20Turtles`);
  const html = await response.text();

  assert.equal(response.status, 200);
  assert.match(html, /Where(?:'|&#x27;)s my[\s\S]*Podium Cafe v2/);
  assert.match(html, /label for="team_ds">DS name or team name:/);
  assert.match(html, /input id="team_ds" name="team_ds"/);
  assert.match(html, /class="results male"/);
  assert.match(html, /class="race"/);
  assert.match(html, /href="https:\/\/cyclingflash\.com\/race\//);
});
