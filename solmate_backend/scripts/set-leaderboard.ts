
import { openDb } from '../src/db/database.js';
import { randomBytes } from 'crypto';

// Function to generate a random public key (for testing purposes)
function generateRandomPubkey(): string {
  return randomBytes(32).toString('hex');
}

// Predefined list of names
const names = [
  "Alex", "Jordan", "Taylor", "Morgan", "Casey", "Riley", "Jamie", "Cameron", "Drew", "Skyler",
  "Quinn", "Peyton", "Avery", "Dakota", "Rowan", "Hayden", "Frankie", "Sidney", "Charlie", "Emerson",
  "Finley", "River", "Phoenix", "Reese", "Kai", "Logan", "Elliot", "Blake", "Harper", "Sawyer"
];

async function seedLeaderboard() {
  let db;
  try {
    db = await openDb();

    // Clear existing data in the solmates table to ensure a fresh start
    await db.run('DELETE FROM solmates');
    console.log('Cleared existing data from solmates table.');

    for (let i = 0; i < 30; i++) {
      const pubkey = generateRandomPubkey();
      const name = names[i % names.length] + (Math.floor(i / names.length) > 0 ? ` ${Math.floor(i / names.length) + 1}` : '');
      const level = Math.floor(Math.random() * 50) + 1; // Random level between 1 and 50
      const run_highscore = Math.floor(Math.random() * 10000) + 100; // Random score between 100 and 10100
      const animal = 'dragon'; // Default animal
      const now = new Date().toISOString();

      await db.run(
        `INSERT INTO solmates (pubkey, name, level, run_highscore, animal, last_fed_at, last_pet_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [pubkey, name, level, run_highscore, animal, now, now]
      );
      console.log(`Inserted ${name} with highscore ${run_highscore}`);
    }

    console.log('Successfully seeded the leaderboard with 30 players.');
  } catch (error) {
    console.error('Failed to seed leaderboard:', error);
  } finally {
    await db?.close();
  }
}

seedLeaderboard().catch(error => {
  console.error('Failed to run leaderboard seeder:', error);
  process.exit(1);
});
