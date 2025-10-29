import cron from 'node-cron';
import { query } from '../db/database.js';
import { addXp, HOURLY_XP_CRON } from '../services/leveling_service.js';

/**
 * Starts a CRON job to periodically award XP to all solmates.
 */
export function startXpCronJob() {
  // Schedule a job to run every hour
  cron.schedule('0 * * * *', async () => {
    console.log('Running hourly XP CRON job...');
    try {
      const { rows: solmates } = await query('SELECT pubkey FROM solmates');

      if (solmates.length === 0) {
        console.log('No solmates found, skipping XP distribution.');
        return;
      }

      console.log(`Found ${solmates.length} solmates. Distributing ${HOURLY_XP_CRON} XP to each.`);

      // Use Promise.all to handle all updates concurrently
      await Promise.all(solmates.map(solmate => 
        addXp(solmate.pubkey, HOURLY_XP_CRON)
      ));

      console.log('Hourly XP distribution complete.');
    } catch (error) {
      console.error('Error during hourly XP CRON job:', error);
    }
  });

  console.log('Hourly XP CRON job scheduled.');
}
