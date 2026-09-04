import test from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';

async function startNextServer() {
  const port = 3100 + Math.floor(Math.random() * 1000);
  const process = spawn('npm', ['run', 'dev', '--', '-p', String(port)], {
    cwd: new URL('..', import.meta.url),
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  await new Promise((resolve, reject) => {
    const output = (chunk) => {
      if (chunk.toString().includes('Ready')) resolve();
    };
    process.stdout.on('data', output);
    process.stderr.on('data', output);
    process.once('error', reject);
  });

  return { process, port };
}

test('the root page shows the current application heading', async (t) => {
  const server = await startNextServer();
  t.after(() => server.process.kill());

  const response = await fetch(`http://127.0.0.1:${server.port}/`);
  const html = await response.text();

  assert.equal(response.status, 200);
  assert.match(html, /Where(?:'|&#x27;)s my[\s\S]*Podium Cafe v2/);
});
