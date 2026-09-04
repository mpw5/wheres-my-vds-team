import { mkdir, readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { createDisposableDatabase } from './database.mjs';

const racesCsv = join(process.cwd(), '..', 'db', 'seeds', 'races.csv');
const databasePath = join(process.cwd(), process.env.POC_DATA_DIR ?? '.data', 'races.sqlite');

export type Race = { raceType: string; name: string; pcsName: string; startDate: Date; endDate: Date };

export async function fetchStartlist(race: Race): Promise<string[]> {
  const baseUrl = process.env.SCRAPER_BASE_URL || 'https://cyclingflash.com/race';
  const url = `${baseUrl}/${race.pcsName}-${new Date().getUTCFullYear()}/startlist`;

  try {
    const response = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0 (compatible)' } });
    if (!response.ok) return [];
    const html = await response.text();
    return [...html.matchAll(/<a[^>]+href=["'][^"']*\/profile\/[\w-]+["'][^>]*>([^<]+)<\/a>/gi)]
      .map((match) => match[1].trim());
  } catch {
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
  const rows = database.database.prepare('SELECT race_type AS raceType, name, pcs_name AS pcsName, start_date AS startDate, end_date AS endDate FROM races WHERE race_type = ? AND end_date >= ? ORDER BY start_date ASC LIMIT 10').all(raceType, today.toISOString()) as Array<Omit<Race, 'startDate' | 'endDate'> & { startDate: string; endDate: string }>;
  return rows.map((race) => ({ ...race, startDate: new Date(race.startDate), endDate: new Date(race.endDate) }));
}

export function formatDates(race: Race): string {
  const format = (date: Date) => `${String(date.getUTCDate()).padStart(2, '0')}/${String(date.getUTCMonth() + 1).padStart(2, '0')}/${date.getUTCFullYear()}`;
  return race.startDate.getTime() === race.endDate.getTime() ? format(race.startDate) : `${format(race.startDate)} - ${format(race.endDate)}`;
}
