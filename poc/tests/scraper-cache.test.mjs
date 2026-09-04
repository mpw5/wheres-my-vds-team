import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import { fetchStartlist } from '../src/races.ts';

test('a fresh startlist is reused instead of fetched on every page render', async () => {
  let requests = 0;
  const source = createServer((request, response) => {
    requests += 1;
    response.writeHead(200, { 'content-type': 'text/html' });
    response.end('<a href="/profile/wout-van-aert">Wout van Aert</a>');
  });
  await new Promise((resolve) => source.listen(0, '127.0.0.1', resolve));
  const originalScraperBaseUrl = process.env.SCRAPER_BASE_URL;
  process.env.SCRAPER_BASE_URL = `http://127.0.0.1:${source.address().port}`;

  try {
    const race = {
      raceType: 'male',
      name: 'Test race',
      pcsName: `test-cache-${Date.now()}`,
      startDate: new Date('2026-09-06T00:00:00Z'),
      endDate: new Date('2026-09-06T00:00:00Z'),
    };

    assert.deepEqual(await fetchStartlist(race), ['Wout van Aert']);
    assert.deepEqual(await fetchStartlist(race), ['Wout van Aert']);
    assert.equal(requests, 1);
  } finally {
    source.close();
    if (originalScraperBaseUrl === undefined) delete process.env.SCRAPER_BASE_URL;
    else process.env.SCRAPER_BASE_URL = originalScraperBaseUrl;
  }
});

test('a fresh Rails startlist cache is used before external scraping', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'wheres-my-vds-team-rails-cache-'));
  const databasePath = join(directory, 'development.sqlite3');
  const originalRailsPath = process.env.RAILS_DATABASE_PATH;
  let requests = 0;
  process.env.RAILS_DATABASE_PATH = databasePath;

  try {
    const { DatabaseSync } = await import('node:sqlite');
    const database = new DatabaseSync(databasePath);
    database.exec('CREATE TABLE races (pcs_name TEXT, scraped_startlist TEXT, updated_at TEXT)');
    database.prepare('INSERT INTO races VALUES (?, ?, ?)').run('rails-cache-race', 'Wout van Aert', new Date().toISOString());
    database.close();

    const race = {
      raceType: 'male',
      name: 'Cached race',
      pcsName: 'rails-cache-race',
      startDate: new Date('2026-09-06T00:00:00Z'),
      endDate: new Date('2026-09-06T00:00:00Z'),
    };

    assert.deepEqual(await fetchStartlist(race), ['Wout van Aert']);
    assert.equal(requests, 0);
  } finally {
    if (originalRailsPath === undefined) delete process.env.RAILS_DATABASE_PATH;
    else process.env.RAILS_DATABASE_PATH = originalRailsPath;
    await rm(directory, { recursive: true, force: true });
  }
});
