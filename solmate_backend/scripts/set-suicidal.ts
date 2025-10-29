import { query, pool } from '../src/db/database.js';

async function setLowHappiness(pubkey: string) {
  try {
    const { rows: solmateRows } = await query('SELECT * FROM solmates WHERE pubkey = $1', [pubkey]);
    const solmate = solmateRows[0];
    if (!solmate) {
      console.error(`Solmate with pubkey "${pubkey}" not found.`);
      return;
    }

    const happiness = 0; // Low happiness (suicidal)
    const hoursToSubtract = (100 - happiness) / 2;
    const now = new Date();
    const petDate = new Date(now.getTime() - hoursToSubtract * 60 * 60 * 1000);
    const lastPetAt = petDate.toISOString();

    await query('UPDATE solmates SET last_pet_at = $1 WHERE pubkey = $2', [lastPetAt, pubkey]);
    console.log(`Set suicidal happiness for solmate ${pubkey}.`);
  } finally {
    await pool.end();
  }
}

const pubkey = '79kPbM2CchFpLt51exnzqyr1gow2ddKExDmtZHz22g7G';

setLowHappiness(pubkey).catch(error => {
  console.error('Failed to set low happiness:', error);
  process.exit(1);
});
