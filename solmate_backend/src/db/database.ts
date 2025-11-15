import { Pool } from 'pg';
import config from '../config/config.js';

// Ensure the DATABASE_URL is configured.
if (!config.databaseUrl) {
  throw new Error('DATABASE_URL is not configured in config.ts. Please ensure it\'s set in your .env file.');
}

/**
 * The connection pool for the PostgreSQL database.
 * It uses the DATABASE_URL from the environment variables.
 */
export const pool = new Pool({
  connectionString: config.databaseUrl,
  // Supabase requires SSL. This configuration is common for cloud-hosted databases.
  // In production, you might want to use a more secure setup with a specific CA certificate.
  ssl: {
    rejectUnauthorized: false,
  },
});

/**
 * A convenience function to run queries against the connection pool.
 * @param text The SQL query string.
 * @param params The parameters to pass to the query.
 * @returns The result of the query.
 */
export const query = (text: string, params?: any[]) => pool.query(text, params);

/**
 * Initializes the database by creating tables if they don't already exist.
 * This function should be called once when the application starts.
 */
export async function initializeDatabase() {
  const client = await pool.connect();
  console.log('Connected to the PostgreSQL database.');

  // This query contains the final schema for all tables, adapted for PostgreSQL.
  const createTablesQuery = `
    CREATE TABLE IF NOT EXISTS solmates (
        pubkey VARCHAR(255) PRIMARY KEY,
        name VARCHAR(20) NOT NULL,
        level INTEGER NOT NULL DEFAULT 1,
        xp INTEGER NOT NULL DEFAULT 0,
        run_highscore INTEGER NOT NULL DEFAULT 0,
        animal VARCHAR(50) NOT NULL,
        selected_background VARCHAR(255),
        has_poo BOOLEAN NOT NULL DEFAULT FALSE,
        last_fed_at TIMESTAMPTZ NOT NULL,
        last_pet_at TIMESTAMPTZ NOT NULL,
        poos_cleaned INTEGER NOT NULL DEFAULT 0,
        pets_given INTEGER NOT NULL DEFAULT 0,
        food_fed INTEGER NOT NULL DEFAULT 0,
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS selected_decorations (
        id SERIAL PRIMARY KEY,
        solmate_pubkey VARCHAR(255) NOT NULL,
        row INTEGER NOT NULL,
        col INTEGER NOT NULL,
        decoration_name VARCHAR(255) NOT NULL,
        decoration_url VARCHAR(255) NOT NULL,
        FOREIGN KEY (solmate_pubkey) REFERENCES solmates (pubkey) ON DELETE CASCADE,
        UNIQUE (solmate_pubkey, row, col)
    );

    CREATE TABLE IF NOT EXISTS unlocked_assets (
        id SERIAL PRIMARY KEY,
        user_pubkey VARCHAR(255) NOT NULL,
        asset_id VARCHAR(255) NOT NULL, -- e.g., 'decoration_chair' or 'background_day'
        purchase_transaction_signature VARCHAR(255),
        created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_pubkey) REFERENCES solmates (pubkey) ON DELETE CASCADE,
        UNIQUE (user_pubkey, asset_id)
    );

    CREATE TABLE IF NOT EXISTS processed_transactions (
        signature VARCHAR(255) PRIMARY KEY,
        processed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    );
  `;

  try {
    await client.query(createTablesQuery);
    console.log('Database tables are ready.');
  } catch (err) {
    console.error('Error creating database tables:', err);
    throw err;
  } finally {
    // Release the client back to the pool.
    client.release();
  }
}
