import type { DatabaseSync } from 'node:sqlite';

export function createDisposableDatabase(databasePath: string): {
  database: DatabaseSync;
  close: () => void;
};