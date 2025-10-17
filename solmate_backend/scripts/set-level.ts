import { openDb } from '../src/db/database.js';

async function setLevel(pubkey: string) {
  const args = process.argv.slice(2);
  if (args.length !== 1) {
    console.error('Usage: npm run level <level>');
    process.exit(1);
  }

  const [levelStr] = args;
  const level = parseInt(levelStr!, 10);

  if (isNaN(level) || level < 1) {
      console.error('Error: Level must be a positive integer.');
      process.exit(1);
  }

  let db;
  try {
    db = await openDb();
    const result = await db.run(
      'UPDATE solmates SET level = ? WHERE pubkey = ?',
      [level, pubkey]
    );

    if (result.changes === 0) {
      console.log(`No solmate found with pubkey: ${pubkey}`);
    } else {
      console.log(`Successfully set level to ${level} for solmate with pubkey: ${pubkey}`);
    }
  } catch (error) {
    console.error('Failed to set level:', error);
  } finally {
    await db?.close();
  }
}

const pubkey = '7WKaHxMy54Mn5JPpETqiwwkcyJLmkcsrjwfvUnDqPpdN';

setLevel(pubkey).catch(error => {
  console.error('Failed to set low level:', error);
  process.exit(1);
});
