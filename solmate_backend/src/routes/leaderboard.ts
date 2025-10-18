import { Router } from 'express';
import { openDb } from '../db/database.js';
import { generateNormalSprite } from '../services/sprite_service.js';

const router = Router();

router.get('/', async (req, res) => {
  try {
    const db = await openDb();
    const players = await db.all(
      'SELECT name, run_highscore, pubkey, animal FROM solmates ORDER BY run_highscore DESC LIMIT 20'
    );

    const leaderboard = await Promise.all(
      players.map(async (player) => {
        try {
          const sprite = await generateNormalSprite(player.animal, player.pubkey);
          return {
            name: player.name,
            run_highscore: player.run_highscore,
            sprite: sprite,
          };
        } catch (error) {
          console.error(`Failed to generate sprite for ${player.pubkey}:`, error);
          // Return player data without sprite on failure
          return {
            name: player.name,
            run_highscore: player.run_highscore,
            sprite: null, // Or a placeholder Base64 string
          };
        }
      })
    );

    res.json(leaderboard);
  } catch (error) {
    console.error('Failed to fetch leaderboard:', error);
    res.status(500).json({ message: 'Failed to fetch leaderboard' });
  }
});

export default router;
