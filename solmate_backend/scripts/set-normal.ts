import { openDb } from '../src/db/database.js';

async function setNormal(pubkey: string) {
  const db = await openDb();
  try {
    const solmate = await db.get('SELECT * FROM solmates WHERE pubkey = ?', pubkey);
    if (!solmate) {
      console.error(`Solmate with pubkey "${pubkey}" not found.`);
      return;
    }
    const now = new Date().toISOString();
    await db.run('UPDATE solmates SET last_fed_at = ?, last_pet_at = ? WHERE pubkey = ?', [now, now, pubkey]);
    console.log(`Set low health for solmate ${pubkey}.`);
  } finally {
    await db.close();
  }
}

const pubkey = '7WKaHxMy54Mn5JPpETqiwwkcyJLmkcsrjwfvUnDqPpdN';

setNormal(pubkey).catch(error => {
  console.error('Failed to set Normal:', error);
  process.exit(1);
});
