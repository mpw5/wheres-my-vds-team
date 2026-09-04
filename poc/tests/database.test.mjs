import test from 'node:test';
import assert from 'node:assert/strict';
import { access } from 'node:fs/promises';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createDisposableDatabase } from '../src/database.mjs';

test('a disposable database can be created and discarded', async (t) => {
  const directory = await mkdtemp(join(tmpdir(), 'wheres-my-vds-team-poc-'));
  const databasePath = join(directory, 'poc.sqlite');
  t.after(() => rm(directory, { recursive: true, force: true }));

  const database = createDisposableDatabase(databasePath);
  database.close();

  await assert.rejects(() => access(databasePath), { code: 'ENOENT' });
});
