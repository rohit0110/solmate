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
        xp INTEGER NOT NULL DEFAULT 0,
        run_highscore INTEGER NOT NULL DEFAULT 0,
        animal VARCHAR(50) NOT NULL,
        selected_background VARCHAR(255),
        has_poo BOOLEAN NOT NULL DEFAULT 0,
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

    CREATE TABLE IF NOT EXISTS unlocked_assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_pubkey VARCHAR(255) NOT NULL,
        asset_id VARCHAR(255) NOT NULL, -- e.g., 'decoration_chair' or 'background_day'
        purchase_transaction_signature VARCHAR(255),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_pubkey) REFERENCES solmates (pubkey) ON DELETE CASCADE,
        UNIQUE (user_pubkey, asset_id)
    );

    CREATE TABLE IF NOT EXISTS processed_transactions (
        signature VARCHAR(255) PRIMARY KEY,
        processed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
  `);

  // Add columns if they don't exist for existing tables
  const columns = await db.all('PRAGMA table_info(solmates)');
  const columnNames = columns.map((c: any) => c.name);

  if (!columnNames.includes('level')) {
    await db.exec('ALTER TABLE solmates ADD COLUMN level INTEGER NOT NULL DEFAULT 1');
    console.log('Added "level" column to solmates table.');
  }
  if (!columnNames.includes('xp')) {
    await db.exec('ALTER TABLE solmates ADD COLUMN xp INTEGER NOT NULL DEFAULT 0');
    console.log('Added "xp" column to solmates table.');
  }
  if (!columnNames.includes('run_highscore')) {
    await db.exec('ALTER TABLE solmates ADD COLUMN run_highscore INTEGER NOT NULL DEFAULT 0');
    console.log('Added "run_highscore" column to solmates table.');
  }
  if (!columnNames.includes('selected_background')) {
    await db.exec('ALTER TABLE solmates ADD COLUMN selected_background VARCHAR(255)');
    console.log('Added "selected_background" column to solmates table.');
  }

  console.log('Database tables are ready.');

  return db;
}