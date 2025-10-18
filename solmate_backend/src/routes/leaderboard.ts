import { Router } from 'express';
import { openDb } from '../db/database.js';
import { generateNormalSprite } from '../services/sprite_service.js';

const router = Router();

router.get('/', async (req, res) => {
  const userPubkey = req.query.pubkey as string | undefined;

  try {
    const db = await openDb();
    const topPlayers = await db.all(
      'SELECT pubkey, name, run_highscore, animal FROM solmates ORDER BY run_highscore DESC LIMIT 20'
    );

    const leaderboard = await Promise.all(
      topPlayers.map(async (player, index) => {
        try {
          const sprite = await generateNormalSprite(player.animal, player.pubkey);
          return {
            rank: index + 1,
            pubkey: player.pubkey,
            name: player.name,
            run_highscore: player.run_highscore,
            sprite: sprite,
          };
        } catch (error) {
          console.error(`Failed to generate sprite for ${player.pubkey}:`, error);
          return {
            rank: index + 1,
            pubkey: player.pubkey,
            name: player.name,
            run_highscore: player.run_highscore,
            sprite: null,
          };
        }
      })
    );

    let user = null;
    if (userPubkey) {
      const userInTop20 = leaderboard.some(p => p.pubkey === userPubkey);
      if (!userInTop20) {
        const userRow = await db.get(
          `SELECT pubkey, name, run_highscore, animal,
           (SELECT COUNT(*) + 1 FROM solmates s2 WHERE s2.run_highscore > s1.run_highscore) as rank
           FROM solmates s1 WHERE s1.pubkey = ?`,
          userPubkey
        );

        if (userRow && userRow.run_highscore > 0) {
          try {
            const sprite = await generateNormalSprite(userRow.animal, userRow.pubkey);
            user = {
              rank: userRow.rank,
              pubkey: userRow.pubkey,
              name: userRow.name,
              run_highscore: userRow.run_highscore,
              sprite: sprite,
            };
          } catch (error) {
            console.error(`Failed to generate sprite for ${userRow.pubkey}:`, error);
            user = {
              rank: userRow.rank,
              pubkey: userRow.pubkey,
              name: userRow.name,
              run_highscore: userRow.run_highscore,
              sprite: null,
            };
          }
        }
      }
    }

    res.json({ leaderboard, user });

  } catch (error) {
    console.error('Failed to fetch leaderboard:', error);
    res.status(500).json({ message: 'Failed to fetch leaderboard' });
  }
});

export default router;
