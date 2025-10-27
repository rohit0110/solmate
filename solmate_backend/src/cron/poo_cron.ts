import cron from 'node-cron';
import { openDb } from '../db/database.js';

/**
 * Starts a CRON job to occasionally make solmates poo.
 */
export function startPooCronJob() {
  // Schedule a job to run every hour
  cron.schedule('* * * * *', async () => {
    console.log('Running hourly poo CRON job...');
    try {
      const db = await openDb();
      // Get all solmates that haven't pooed yet
      const solmates = await db.all('SELECT pubkey FROM solmates WHERE has_poo = 0');

      if (solmates.length === 0) {
        console.log('All solmates have already pooed or there are no solmates, skipping.');
        return;
      }

      console.log(`Found ${solmates.length} clean solmates. Rolling the dice...`);

      const updates = solmates.map(solmate => {
        // 20% chance to poo
        if (Math.random() < 1) {
          console.log(`Solmate ${solmate.pubkey} is pooing.`);
          return db.run('UPDATE solmates SET has_poo = 1 WHERE pubkey = ?', [solmate.pubkey]);
        }
        return Promise.resolve();
      });

      await Promise.all(updates);

      console.log('Hourly poo CRON job complete.');
    } catch (error) {
      console.error('Error during hourly poo CRON job:', error);
    }
  });

  console.log('Hourly poo CRON job scheduled.');
}
