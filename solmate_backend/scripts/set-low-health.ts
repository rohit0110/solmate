import { query, pool } from '../src/db/database.js';

async function setLowHealth(pubkey: string) {
  try {
    const { rows: solmateRows } = await query('SELECT * FROM solmates WHERE pubkey = $1', [pubkey]);
    const solmate = solmateRows[0];
    if (!solmate) {
      console.error(`Solmate with pubkey "${pubkey}" not found.`);
      return;
    }

    const health = 20; // Low health
    const hoursToSubtract = (100 - health) / 4;
    const now = new Date();
    const fedDate = new Date(now.getTime() - hoursToSubtract * 60 * 60 * 1000);
    const lastFedAt = fedDate.toISOString();

    await query('UPDATE solmates SET last_fed_at = $1 WHERE pubkey = $2', [lastFedAt, pubkey]);
    console.log(`Set low health for solmate ${pubkey}.`);
  } finally {
    await pool.end();
  }
}

const pubkey = '79kPbM2CchFpLt51exnzqyr1gow2ddKExDmtZHz22g7G';

setLowHealth(pubkey).catch(error => {
  console.error('Failed to set low health:', error);
  process.exit(1);
});
