import cron from 'node-cron';
import { query } from '../db/database.js';
import { addXp } from '../services/leveling_service.js';
import { Connection, PublicKey } from '@solana/web3.js';
import config from '../config/config.js';

// --- Constants ---
const XP_PER_ONCHAIN_TX = 5;       // XP awarded per on-chain transaction
const MAX_TX_TO_CHECK = 100;       // Max transactions to fetch per user
const CRON_SCHEDULE = '0 0 * * *'; // Every day at midnight (UTC)

/**
 * Starts a CRON job to distribute XP based on daily on-chain activity.
 */
export function startXpCronJob() {
  cron.schedule(CRON_SCHEDULE, async () => {
    console.log('Running daily on-chain XP CRON job...');

    try {
      const solanaConnection = new Connection(config.solanaRpcUrl, 'confirmed');
      const { rows: solmates } = await query('SELECT pubkey FROM solmates');

      if (!solmates.length) {
        console.log('No solmates found. Skipping XP distribution.');
        return;
      }

      console.log(`Found ${solmates.length} solmates. Checking on-chain activity...`);

      // Define start of today (UTC)
      const today = new Date();
      today.setUTCHours(0, 0, 0, 0);
      const startOfToday = today.getTime();
      const endOfToday = startOfToday + 86400000; // +24h in ms

      // Process all solmates in parallel
      await Promise.all(
        solmates.map(async ({ pubkey }) => {
          try {
            const userPubKey = new PublicKey(pubkey);

            // Fetch up to MAX_TX_TO_CHECK recent signatures
            const signatures = await solanaConnection.getSignaturesForAddress(userPubKey, {
              limit: MAX_TX_TO_CHECK,
            });

            if (!signatures?.length) return;

            // Filter today's transactions
            const todaysTx = signatures.filter((sig) => {
              if (!sig.blockTime) return false; // skip if unknown
              const txTime = sig.blockTime * 1000;
              return txTime >= startOfToday && txTime < endOfToday;
            });

            if (todaysTx.length > 0) {
              const xpGained = todaysTx.length * XP_PER_ONCHAIN_TX;
              await addXp(pubkey, xpGained);
              console.log(
                `✅ ${pubkey}: +${xpGained} XP (${todaysTx.length} on-chain tx today)`
              );
            } else {
              console.log(`⚪ ${pubkey}: No new transactions today.`);
            }
          } catch (userErr) {
            console.error(`Error processing ${pubkey}:`, userErr);
          }
        })
      );

      console.log('🎉 Daily on-chain XP CRON job complete.');
    } catch (error) {
      console.error('❌ Error during daily on-chain XP CRON job:', error);
    }
  });

  console.log('🕛 Daily on-chain XP CRON job scheduled (runs every midnight UTC).');
}
