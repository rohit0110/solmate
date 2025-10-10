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
        name VARCHAR(255) NOT NULL,
        last_fed_at TIMESTAMP WITH TIME ZONE NOT NULL,
        last_pet_at TIMESTAMP WITH TIME ZONE NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
  `);

  // Add name column if it doesn't exist for existing tables
  const columns = await db.all('PRAGMA table_info(solmates)');
  const hasNameColumn = columns.some((c: any) => c.name === 'name');
  if (!hasNameColumn) {
    // Added NOT NULL and a DEFAULT value to avoid constraint violations on existing rows.
    await db.exec('ALTER TABLE solmates ADD COLUMN name VARCHAR(255) NOT NULL DEFAULT \'My Solmate\'');
    console.log('Added "name" column to solmates table.');
  }

  console.log('Database tables are ready.');
  return db;
}