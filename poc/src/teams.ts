import { mkdir, readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { parseCsvLine } from './csv.mjs';
import { createDisposableDatabase } from './database.mjs';

const teamsCsv = join(process.cwd(), '..', 'db', 'seeds', 'teams.csv');
const databasePath = join(process.cwd(), process.env.POC_DATA_DIR ?? '.data', 'teams.sqlite');

type Team = {
  teamType: string;
  ds: string;
  name: string;
  riders: string;
};

export function matchingRiders(team: Team, startlist: string[]): string[] {
  if (!team.riders) return [];

  const normalise = (name: string) => name
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/'/g, '')
    .replace(/-/g, ' ')
    .replace(/[()]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
  const normalisedStartlist = startlist.map((name) => normalise(name).split(' '));

  return team.riders.split(',').sort().filter((rider) => {
    const riderWords = normalise(rider).split(' ');
    return normalisedStartlist.some((startlistWords) => riderWords.every((word) => startlistWords.includes(word)));
  });
}

async function readTeams(): Promise<Team[]> {
  const csv = await readFile(teamsCsv, 'utf8');
  return csv.trim().split('\n').map(parseCsvLine).map(([teamType, ds, name, riders]) => ({
    teamType,
    ds,
    name,
    riders,
  }));
}

let store: ReturnType<typeof createDisposableDatabase> | undefined;

async function getStore() {
  if (store) return store;

  await mkdir(dirname(databasePath), { recursive: true });
  const database = createDisposableDatabase(databasePath);
  database.database.exec('DROP TABLE IF EXISTS teams; CREATE TABLE teams (team_type TEXT, ds TEXT, name TEXT, riders TEXT)');
  const insert = database.database.prepare('INSERT INTO teams VALUES (?, ?, ?, ?)');

  for (const team of await readTeams()) {
    insert.run(team.teamType, team.ds, team.name, team.riders);
  }

  store = database;
  return store;
}

export async function findTeams(query?: string): Promise<Team[]> {
  const teamQuery = query?.trim();
  if (!teamQuery) return [];

  const database = await getStore();
  const term = `%${teamQuery.toLowerCase()}%`;
  return database.database
    .prepare('SELECT team_type AS teamType, ds, name, riders FROM teams WHERE lower(ds) LIKE ? OR lower(name) LIKE ?')
    .all(term, term) as unknown as Team[];
}