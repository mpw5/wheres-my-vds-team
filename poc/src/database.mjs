import { unlinkSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';

export function createDisposableDatabase(databasePath) {
  const database = new DatabaseSync(databasePath);

  return {
    database,
    close() {
      database.close();
      unlinkSync(databasePath);
    },
  };
}
