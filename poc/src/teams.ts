import { mkdir, readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { createDisposableDatabase } from './database.mjs';

const teamsCsv = join(process.cwd(), '..', 'db', 'seeds', 'teams.csv');
const databasePath = join(process.cwd(), '.data', 'teams.sqlite');

type Team = {
  teamType: string;
  ds: string;
  name: string;
  riders: string;
};

function parseCsvLine(line: string): string[] {
  const values: string[] = [];
  let value = '';
  let quoted = false;

  for (let index = 0; index < line.length; index += 1) {
    const character = line[index];
    const next = line[index + 1];

    if (character === '"' && quoted && next === '"') {
      value += '"';
      index += 1;
    } else if (character === '"') {
      quoted = !quoted;
    } else if (character === ',' && !quoted) {
      values.push(value);
      value = '';
    } else {
      value += character;
    }
  }

  values.push(value);
  return values;
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
  database.database.exec('CREATE TABLE IF NOT EXISTS teams (team_type TEXT, ds TEXT, name TEXT, riders TEXT)');
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