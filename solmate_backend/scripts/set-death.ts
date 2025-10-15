import { openDb } from '../src/db/database.js';

async function setLowHealth(pubkey: string) {
  const db = await openDb();
  try {
    const solmate = await db.get('SELECT * FROM solmates WHERE pubkey = ?', pubkey);
    if (!solmate) {
      console.error(`Solmate with pubkey "${pubkey}" not found.`);
      return;
    }

    const health = 0; // Low health
    const hoursToSubtract = (100 - health) / 4;
    const now = new Date();
    const fedDate = new Date(now.getTime() - hoursToSubtract * 60 * 60 * 1000);
    const lastFedAt = fedDate.toISOString();

    await db.run('UPDATE solmates SET last_fed_at = ? WHERE pubkey = ?', [lastFedAt, pubkey]);
    console.log(`Set low health for solmate ${pubkey}.`);
  } finally {
    await db.close();
  }
}

const pubkey = '7WKaHxMy54Mn5JPpETqiwwkcyJLmkcsrjwfvUnDqPpdN';

setLowHealth(pubkey).catch(error => {
  console.error('Failed to set low health:', error);
  process.exit(1);
});
