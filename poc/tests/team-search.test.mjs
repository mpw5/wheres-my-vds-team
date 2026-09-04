import test from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

async function startNextServer() {
  const port = 4100 + Math.floor(Math.random() * 1000);
  const serverProcess = spawn(process.execPath, [fileURLToPath(new URL('../node_modules/next/dist/bin/next', import.meta.url)), 'dev', '-p', String(port)], {
    cwd: new URL('..', import.meta.url),
    env: { ...process.env, POC_DATA_DIR: `.data/test-${port}` },
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

test('a user can find a team by name', async (t) => {
  const server = await startNextServer();
  t.after(() => server.process.kill());

  const response = await fetchPage(`http://127.0.0.1:${server.port}/?team_ds=Team%20Baby%20Turtles`);
  const html = await response.text();

  assert.equal(response.status, 200);
  assert.match(html, /class=["']results male["']/);
  assert.match(html, /Team Baby Turtles[\s\S]*819/);
});

test('a user can find a team by directeur sportif', async (t) => {
  const server = await startNextServer();
  t.after(() => server.process.kill());

  const response = await fetchPage(`http://127.0.0.1:${server.port}/?team_ds=819`);
  const html = await response.text();

  assert.equal(response.status, 200);
  assert.match(html, /Team Baby Turtles[\s\S]*819/);
});

test('team search trims whitespace and ignores case for partial matches', async (t) => {
  const server = await startNextServer();
  t.after(() => server.process.kill());

  const response = await fetchPage(`http://127.0.0.1:${server.port}/?team_ds=%20BABY%20TURT%20`);
  const html = await response.text();

  assert.equal(response.status, 200);
  assert.match(html, /Team Baby Turtles[\s\S]*819/);
});

test('an unknown team search shows the no-teams message', async (t) => {
  const server = await startNextServer();
  t.after(() => server.process.kill());

  const response = await fetchPage(`http://127.0.0.1:${server.port}/?team_ds=not-a-real-team`);
  const html = await response.text();

  assert.equal(response.status, 200);
  assert.match(html, /class="no-teams"[\s\S]*No teams found!/);
  assert.doesNotMatch(html, /class="results/);
});
