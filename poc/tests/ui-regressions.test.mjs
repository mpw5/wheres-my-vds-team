import test from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

async function startNextServer() {
  const port = 7100 + Math.floor(Math.random() * 1000);
  const serverProcess = spawn(process.execPath, [fileURLToPath(new URL('../node_modules/next/dist/bin/next', import.meta.url)), 'dev', '-p', String(port)], {
    cwd: new URL('..', import.meta.url),
    env: { ...process.env, POC_DATA_DIR: `.data/test-${port}`, SCRAPER_BASE_URL: 'http://127.0.0.1:1' },
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

test('matching teams render unique race identities and load the stylesheet', async (t) => {
  const server = await startNextServer();
  t.after(() => server.process.kill());

  const response = await fetchPage(`http://127.0.0.1:${server.port}/?team_ds=team`);
  const html = await response.text();
  const raceKeys = [...html.matchAll(/data-race-key="([^"]+)"/g)].map((match) => match[1]);

  assert.equal(response.status, 200);
  assert.ok(raceKeys.length > 1);
  assert.equal(new Set(raceKeys).size, raceKeys.length);

  const stylesheet = await fetch(`http://127.0.0.1:${server.port}/styles.css`);
  assert.equal(stylesheet.status, 200);
  assert.match(await stylesheet.text(), /\.results\.male/);
});
