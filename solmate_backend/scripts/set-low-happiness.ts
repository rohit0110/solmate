import { openDb } from '../src/db/database.js';

async function setLowHappiness(pubkey: string) {
  const db = await openDb();
  try {
    const solmate = await db.get('SELECT * FROM solmates WHERE pubkey = ?', pubkey);
    if (!solmate) {
      console.error(`Solmate with pubkey "${pubkey}" not found.`);
      return;
    }

    const happiness = 20; // Low happiness
    const hoursToSubtract = (100 - happiness) / 2;
    const now = new Date();
    const petDate = new Date(now.getTime() - hoursToSubtract * 60 * 60 * 1000);
    const lastPetAt = petDate.toISOString();

    await db.run('UPDATE solmates SET last_pet_at = ? WHERE pubkey = ?', [lastPetAt, pubkey]);
    console.log(`Set low happiness for solmate ${pubkey}.`);
  } finally {
    await db.close();
  }
}

const pubkey = '7WKaHxMy54Mn5JPpETqiwwkcyJLmkcsrjwfvUnDqPpdN';

setLowHappiness(pubkey).catch(error => {
  console.error('Failed to set low happiness:', error);
  process.exit(1);
});
