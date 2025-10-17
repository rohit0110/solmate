import sqlite3 from 'sqlite3';
import { open, Database } from 'sqlite';

let db: Database<sqlite3.Database, sqlite3.Statement>;

/**
 * Opens a connection to the SQLite database and creates tables if they don't exist.
 * @returns {Promise<Database>} The database connection object.
 */
export async function openDb(): Promise<Database> {
  if (db) {
    return db;
  }

  db = await open({
    filename: './solmate.db',
    driver: sqlite3.Database,
  });

  console.log('Connected to the SQLite database.');

  // Use serialize to run one statement at a time
  await db.exec(`
    CREATE TABLE IF NOT EXISTS solmates (
        pubkey VARCHAR(255) PRIMARY KEY,
        name VARCHAR(20) NOT NULL,
        level INTEGER NOT NULL,
        animal VARCHAR(50) NOT NULL,
        selected_background VARCHAR(255),
        last_fed_at TIMESTAMP WITH TIME ZONE NOT NULL,
        last_pet_at TIMESTAMP WITH TIME ZONE NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS selected_decorations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        solmate_pubkey VARCHAR(255) NOT NULL,
        row INTEGER NOT NULL,
        col INTEGER NOT NULL,
        decoration_name VARCHAR(255) NOT NULL,
        decoration_url VARCHAR(255) NOT NULL,
        FOREIGN KEY (solmate_pubkey) REFERENCES solmates (pubkey) ON DELETE CASCADE,
        UNIQUE (solmate_pubkey, row, col)
    );
  `);

  // Add level column if it doesn't exist for existing tables
  const columns = await db.all('PRAGMA table_info(solmates)');
  const hasLevelColumn = columns.some((c: any) => c.name === 'level');
  if (!hasLevelColumn) {
    // Added NOT NULL and a DEFAULT value to avoid constraint violations on existing rows.
    await db.exec('ALTER TABLE solmates ADD COLUMN level INTEGER NOT NULL DEFAULT 1');
    console.log('Added "level" column to solmates table.');
  }

  const hasBackgroundColumn = columns.some((c: any) => c.name === 'selected_background');
  if (!hasBackgroundColumn) {
    await db.exec('ALTER TABLE solmates ADD COLUMN selected_background VARCHAR(255)');
    console.log('Added "selected_background" column to solmates table.');
  }

  console.log('Database tables are ready.');
  return db;
}