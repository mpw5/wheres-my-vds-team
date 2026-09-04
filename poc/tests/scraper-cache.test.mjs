import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import { closeScraperBrowser, fetchStartlist, prefetchUpcomingStartlists } from '../src/races.ts';

test('a fresh startlist is reused instead of fetched on every page render', async () => {
  let requests = 0;
  const source = createServer((request, response) => {
    requests += 1;
    response.writeHead(200, { 'content-type': 'text/html' });
    response.end('<a href="/profile/wout-van-aert">Wout van Aert</a>');
  });
  await new Promise((resolve) => source.listen(0, '127.0.0.1', resolve));
  const originalScraperBaseUrl = process.env.SCRAPER_BASE_URL;
  const originalDisableBrowserScraper = process.env.POC_DISABLE_BROWSER_SCRAPER;
  process.env.SCRAPER_BASE_URL = `http://127.0.0.1:${source.address().port}`;
  process.env.POC_DISABLE_BROWSER_SCRAPER = 'true';

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
    if (originalDisableBrowserScraper === undefined) delete process.env.POC_DISABLE_BROWSER_SCRAPER;
    else process.env.POC_DISABLE_BROWSER_SCRAPER = originalDisableBrowserScraper;
  }
});

test('a stale startlist cache is retained when refresh fails', async () => {
  let requests = 0;
  const source = createServer((request, response) => {
    requests += 1;
    if (requests === 1) {
      response.writeHead(200, { 'content-type': 'text/html' });
      response.end('<a href="/profile/wout-van-aert">Wout van Aert</a>');
      return;
    }

    response.destroy();
  });
  await new Promise((resolve) => source.listen(0, '127.0.0.1', resolve));
  const originalScraperBaseUrl = process.env.SCRAPER_BASE_URL;
  const originalDisableBrowserScraper = process.env.POC_DISABLE_BROWSER_SCRAPER;
  process.env.SCRAPER_BASE_URL = `http://127.0.0.1:${source.address().port}`;
  process.env.POC_DISABLE_BROWSER_SCRAPER = 'true';

  const originalDateNow = Date.now;

  try {
    const race = {
      raceType: 'male',
      name: 'Cached race',
      pcsName: `stale-cache-${originalDateNow()}`,
      startDate: new Date('2026-09-06T00:00:00Z'),
      endDate: new Date('2026-09-06T00:00:00Z'),
    };

    assert.deepEqual(await fetchStartlist(race), ['Wout van Aert']);
    Date.now = () => originalDateNow() + 7 * 60 * 60 * 1000;
    assert.deepEqual(await fetchStartlist(race), ['Wout van Aert']);
    assert.equal(requests, 2);
  } finally {
    Date.now = originalDateNow;
    source.close();
    if (originalScraperBaseUrl === undefined) delete process.env.SCRAPER_BASE_URL;
    else process.env.SCRAPER_BASE_URL = originalScraperBaseUrl;
    if (originalDisableBrowserScraper === undefined) delete process.env.POC_DISABLE_BROWSER_SCRAPER;
    else process.env.POC_DISABLE_BROWSER_SCRAPER = originalDisableBrowserScraper;
  }
});

test('startup prefetch is best effort and uses the runtime scraper path', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'wheres-my-vds-team-prefetch-'));
  const originalDataDir = process.env.POC_DATA_DIR;
  const originalScraperBaseUrl = process.env.SCRAPER_BASE_URL;
  const originalDisableBrowserScraper = process.env.POC_DISABLE_BROWSER_SCRAPER;
  process.env.POC_DATA_DIR = directory;
  process.env.POC_DISABLE_BROWSER_SCRAPER = 'true';
  let requests = 0;
  const source = createServer((request, response) => {
    requests += 1;
    response.writeHead(503);
    response.end();
  });
  await new Promise((resolve) => source.listen(0, '127.0.0.1', resolve));
  process.env.SCRAPER_BASE_URL = `http://127.0.0.1:${source.address().port}`;

  try {
    await prefetchUpcomingStartlists();
    assert.ok(requests > 0);
  } finally {
    source.close();
    if (originalDataDir === undefined) delete process.env.POC_DATA_DIR;
    else process.env.POC_DATA_DIR = originalDataDir;
    if (originalScraperBaseUrl === undefined) delete process.env.SCRAPER_BASE_URL;
    else process.env.SCRAPER_BASE_URL = originalScraperBaseUrl;
    if (originalDisableBrowserScraper === undefined) delete process.env.POC_DISABLE_BROWSER_SCRAPER;
    else process.env.POC_DISABLE_BROWSER_SCRAPER = originalDisableBrowserScraper;
    await rm(directory, { recursive: true, force: true });
  }
});

test('the default runtime startlist path requests Cyclingflash', async () => {
  const originalScraperBaseUrl = process.env.SCRAPER_BASE_URL;
  delete process.env.SCRAPER_BASE_URL;
  const originalConnect = process.env.NODE_TLS_REJECT_UNAUTHORIZED;
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

  try {
    const race = {
      raceType: 'male',
      name: 'Live integration probe',
      pcsName: `live-integration-probe-${Date.now()}`,
      startDate: new Date('2026-09-06T00:00:00Z'),
      endDate: new Date('2026-09-06T00:00:00Z'),
    };

    await fetchStartlist(race);
  } finally {
    await closeScraperBrowser();
    if (originalScraperBaseUrl === undefined) delete process.env.SCRAPER_BASE_URL;
    else process.env.SCRAPER_BASE_URL = originalScraperBaseUrl;
    if (originalConnect === undefined) delete process.env.NODE_TLS_REJECT_UNAUTHORIZED;
    else process.env.NODE_TLS_REJECT_UNAUTHORIZED = originalConnect;
  }
});
