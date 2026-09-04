import { existsSync } from 'node:fs';
import http from 'node:http';
import https from 'node:https';
import { mkdir, readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import { createDisposableDatabase } from './database.mjs';
import { chromium, type Browser } from 'playwright';

const racesCsv = join(process.cwd(), '..', 'db', 'seeds', 'races.csv');
const databasePath = join(process.cwd(), process.env.POC_DATA_DIR ?? '.data', 'races.sqlite');

export type Race = { raceType: string; name: string; pcsName: string; startDate: Date; endDate: Date };

let browser: Browser | undefined;
const startlistCache = new Map<string, { fetchedAt: number; riders: string[] }>();
const STARTLIST_CACHE_MS = 6 * 60 * 60 * 1000;

function readRailsCache(pcsName: string): string[] {
  const railsDatabasePath = process.env.RAILS_DATABASE_PATH ?? join(process.cwd(), '..', 'db', 'development.sqlite3');
  if (!existsSync(railsDatabasePath)) return [];

  const database = new DatabaseSync(railsDatabasePath, { readOnly: true });
  try {
    const row = database.prepare("SELECT scraped_startlist FROM races WHERE pcs_name = ? AND scraped_startlist IS NOT NULL AND updated_at >= datetime('now', '-6 hours') ORDER BY updated_at DESC LIMIT 1").get(pcsName) as { scraped_startlist?: string } | undefined;
    return row?.scraped_startlist?.split(',').filter(Boolean) ?? [];
  } finally {
    database.close();
  }
}

async function fetchWithBrowser(url: string): Promise<string[]> {
  browser ??= await chromium.launch({ headless: true });
  const page = await browser.newPage();
  try {
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30_000 });
    await page.locator('a[href*="/profile/"]').first().waitFor({ timeout: 10_000 }).catch(() => undefined);
    return await page.locator('a[href*="/profile/"]').evaluateAll((links) => links
      .map((link) => link.textContent?.trim() ?? '')
      .filter(Boolean));
  } finally {
    await page.close();
  }
}

async function fetchHtml(url: string): Promise<{ status: number; body: string }> {
  const parsedUrl = new URL(url);
  const client = parsedUrl.protocol === 'https:' ? https : http;

  return new Promise((resolve, reject) => {
    const request = client.get(parsedUrl, {
      headers: {
        Accept: '*/*',
        Connection: 'close',
        'User-Agent': 'Mozilla/5.0 (compatible)',
      },
      servername: parsedUrl.hostname,
    }, (response) => {
      let body = '';
      response.setEncoding('utf8');
      response.on('data', (chunk) => { body += chunk; });
      response.on('end', () => resolve({ status: response.statusCode ?? 0, body }));
    });
    request.on('error', reject);
  });
}

export async function fetchStartlist(race: Race): Promise<string[]> {
  const baseUrl = process.env.SCRAPER_BASE_URL || 'https://cyclingflash.com/race';
  const url = `${baseUrl}/${race.pcsName}-${new Date().getUTCFullYear()}/startlist`;
  const cached = startlistCache.get(url);
  if (cached && Date.now() - cached.fetchedAt < STARTLIST_CACHE_MS) return cached.riders;
  const railsCached = readRailsCache(race.pcsName);
  if (railsCached.length > 0) {
    startlistCache.set(url, { fetchedAt: Date.now(), riders: railsCached });
    return railsCached;
  }

  try {
    const response = await fetchHtml(url);
    if (response.status >= 200 && response.status < 300) {
      const html = response.body;
      const riders = [...html.matchAll(/<a[^>]+href=["'][^"']*\/profile\/[\w-]+["'][^>]*>([^<]+)<\/a>/gi)]
        .map((match) => match[1].trim());
      if (riders.length > 0) {
        startlistCache.set(url, { fetchedAt: Date.now(), riders });
        return riders;
      }
    } else {
      console.warn(`Cyclingflash returned ${response.status} for ${url}; trying browser scrape`);
    }

    const riders = await fetchWithBrowser(url);
    if (riders.length > 0) startlistCache.set(url, { fetchedAt: Date.now(), riders });
    return riders;
  } catch {
    console.warn(`Cyclingflash request failed for ${url}; trying browser scrape`);
    return [];
  }
}

function parseCsvLine(line: string): string[] {
  const values: string[] = [];
  let value = '';
  let quoted = false;
  for (let index = 0; index < line.length; index += 1) {
    const character = line[index];
    const next = line[index + 1];
    if (character === '"' && quoted && next === '"') { value += '"'; index += 1; }
    else if (character === '"') quoted = !quoted;
    else if (character === ',' && !quoted) { values.push(value); value = ''; }
    else value += character;
  }
  values.push(value);
  return values;
}

function parseDate(value: string): Date {
  const [day, month, year] = value.split('/').map(Number);
  return new Date(Date.UTC(year, month - 1, day));
}

async function readRaces(): Promise<Race[]> {
  const csv = await readFile(racesCsv, 'utf8');
  return csv.trim().split('\n').map(parseCsvLine).map(([raceType, name, pcsName, date, length]) => {
    const startDate = parseDate(date);
    const endDate = new Date(startDate);
    endDate.setUTCDate(endDate.getUTCDate() + Math.max(Number(length) || 1, 1) - 1);
    return { raceType, name, pcsName, startDate, endDate };
  });
}

let store: ReturnType<typeof createDisposableDatabase> | undefined;

async function getStore() {
  if (store) return store;
  await mkdir(dirname(databasePath), { recursive: true });
  const database = createDisposableDatabase(databasePath);
  database.database.exec('DROP TABLE IF EXISTS races; CREATE TABLE races (race_type TEXT, name TEXT, pcs_name TEXT, start_date TEXT, end_date TEXT)');
  const insert = database.database.prepare('INSERT INTO races VALUES (?, ?, ?, ?, ?)');
  for (const race of await readRaces()) insert.run(race.raceType, race.name, race.pcsName, race.startDate.toISOString(), race.endDate.toISOString());
  store = database;
  return store;
}

export async function upcomingRaces(raceType: string, today = new Date()): Promise<Race[]> {
  const database = await getStore();
  const rows = database.database.prepare('SELECT race_type AS raceType, name, pcs_name AS pcsName, start_date AS startDate, end_date AS endDate FROM races WHERE race_type = ? AND end_date >= ? GROUP BY race_type, pcs_name ORDER BY start_date ASC LIMIT 10').all(raceType, today.toISOString()) as Array<Omit<Race, 'startDate' | 'endDate'> & { startDate: string; endDate: string }>;
  return rows.map((race) => ({ ...race, startDate: new Date(race.startDate), endDate: new Date(race.endDate) }));
}

export function formatDates(race: Race): string {
  const format = (date: Date) => `${String(date.getUTCDate()).padStart(2, '0')}/${String(date.getUTCMonth() + 1).padStart(2, '0')}/${date.getUTCFullYear()}`;
  return race.startDate.getTime() === race.endDate.getTime() ? format(race.startDate) : `${format(race.startDate)} - ${format(race.endDate)}`;
}
