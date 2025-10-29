import { query, pool } from '../src/db/database.js';

async function setNormal(pubkey: string) {
  try {
    const { rows: solmateRows } = await query('SELECT * FROM solmates WHERE pubkey = $1', [pubkey]);
    const solmate = solmateRows[0];
    if (!solmate) {
      console.error(`Solmate with pubkey "${pubkey}" not found.`);
      return;
    }
    const now = new Date().toISOString();
    await query('UPDATE solmates SET last_fed_at = $1, last_pet_at = $2 WHERE pubkey = $3', [now, now, pubkey]);
    console.log(`Set normal status (fed and pet) for solmate ${pubkey}.`);
  } finally {
    await pool.end();
  }
}

const pubkey = '79kPbM2CchFpLt51exnzqyr1gow2ddKExDmtZHz22g7G';

setNormal(pubkey).catch(error => {
  console.error('Failed to set Normal:', error);
  process.exit(1);
});
