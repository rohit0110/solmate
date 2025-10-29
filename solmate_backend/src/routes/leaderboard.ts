import { Router } from 'express';
import { query } from '../db/database.js';
import { generateNormalSprite } from '../services/sprite_service.js';

const router = Router();

router.get('/', async (req, res) => {
  const userPubkey = req.query.pubkey as string | undefined;

  try {
    // Use DENSE_RANK for fair ranking with a timestamp tie-breaker.
    // This query gets all players ranked 20 or less.
    const { rows: topPlayers } = await query(
      `SELECT * FROM (
        SELECT
          pubkey, name, run_highscore, animal, updated_at,
          DENSE_RANK() OVER (ORDER BY run_highscore DESC, updated_at ASC) as rank
        FROM solmates
        WHERE run_highscore > 0
      )
      WHERE rank <= 20
      ORDER BY rank ASC, updated_at ASC`
    );

    const leaderboard = await Promise.all(
      topPlayers.map(async (player) => {
        try {
          const sprite = await generateNormalSprite(player.animal, player.pubkey);
          return {
            rank: player.rank,
            pubkey: player.pubkey,
            name: player.name,
            score: player.run_highscore,
            sprite: sprite,
          };
        } catch (error) {
          console.error(`Failed to generate sprite for ${player.pubkey}:`, error);
          return {
            rank: player.rank,
            pubkey: player.pubkey,
            name: player.name,
            score: player.run_highscore,
            sprite: null,
          };
        }
      })
    );

    let user = null;
    if (userPubkey) {
      const userInTopList = leaderboard.some(p => p.pubkey === userPubkey);
      if (!userInTopList) {
        // If user is not in the top list, get their specific rank.
        const { rows: userRowRows } = await query(
          `SELECT * FROM (
            SELECT
              pubkey, name, run_highscore, animal,
              DENSE_RANK() OVER (ORDER BY run_highscore DESC, updated_at ASC) as rank
            FROM solmates
            WHERE run_highscore > 0
          )
          WHERE pubkey = $1`,
          [userPubkey]
        );
        const userRow = userRowRows[0];

        if (userRow) {
          try {
            const sprite = await generateNormalSprite(userRow.animal, userRow.pubkey);
            user = {
              rank: userRow.rank,
              pubkey: userRow.pubkey,
              name: userRow.name,
              score: userRow.run_highscore,
              sprite: sprite,
            };
          } catch (error) {
            console.error(`Failed to generate sprite for ${userRow.pubkey}:`, error);
            user = {
              rank: userRow.rank,
              pubkey: userRow.pubkey,
              name: userRow.name,
              score: userRow.run_highscore,
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

router.get('/survival', async (req, res) => {
    const userPubkey = req.query.pubkey as string | undefined;
    console.log("HERE");
    try {
      const { rows: topPlayers } = await query(
        `SELECT *,
           (EXTRACT(EPOCH FROM NOW()) - EXTRACT(EPOCH FROM created_at)) as survival_time
         FROM (
          SELECT
            pubkey, name, created_at, animal,
            DENSE_RANK() OVER (ORDER BY created_at ASC) as rank
          FROM solmates
          WHERE created_at IS NOT NULL AND (EXTRACT(EPOCH FROM NOW()) - EXTRACT(EPOCH FROM last_fed_at)) < 90000
        )
        WHERE rank <= 20
        ORDER BY rank ASC`
      );
      const leaderboard = await Promise.all(
        topPlayers.map(async (player) => {
          try {
            const sprite = await generateNormalSprite(player.animal, player.pubkey);
            return {
              rank: player.rank,
              pubkey: player.pubkey,
              name: player.name,
              score: player.survival_time,
              sprite: sprite,
            };
          } catch (error) {
            console.error(`Failed to generate sprite for ${player.pubkey}:`, error);
            return {
              rank: player.rank,
              pubkey: player.pubkey,
              name: player.name,
              score: player.survival_time,
              sprite: null,
            };
          }
        })
      );
  
      let user = null;
      if (userPubkey) {
        const userInTopList = leaderboard.some(p => p.pubkey === userPubkey);
        if (!userInTopList) {
          const { rows: userRowRows } = await query(
            `SELECT *,
               (EXTRACT(EPOCH FROM NOW()) - EXTRACT(EPOCH FROM created_at)) as survival_time
             FROM (
              SELECT
                pubkey, name, created_at, animal,
                DENSE_RANK() OVER (ORDER BY created_at ASC) as rank
              FROM solmates
              WHERE created_at IS NOT NULL AND (EXTRACT(EPOCH FROM NOW()) - EXTRACT(EPOCH FROM last_fed_at)) < 90000
            )
            WHERE pubkey = $1`,
            [userPubkey]
          );
          const userRow = userRowRows[0];
  
          if (userRow) {
            try {
              const sprite = await generateNormalSprite(userRow.animal, userRow.pubkey);
              user = {
                rank: userRow.rank,
                pubkey: userRow.pubkey,
                name: userRow.name,
                score: userRow.survival_time,
                sprite: sprite,
              };
            } catch (error) {
              console.error(`Failed to generate sprite for ${userRow.pubkey}:`, error);
              user = {
                rank: userRow.rank,
                pubkey: userRow.pubkey,
                name: userRow.name,
                score: userRow.survival_time,
                sprite: null,
              };
            }
          }
        }
      }
  
      res.json({ leaderboard, user });
  
    } catch (error) {
      console.error('Failed to fetch survival leaderboard:', error);
      res.status(500).json({ message: 'Failed to fetch survival leaderboard' });
    }
  });

export default router;


