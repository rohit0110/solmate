import { Router } from 'express';
import { openDb } from '../db/database.js';

const router = Router();

router.get('/', async (req, res) => {
  try {
    const db = await openDb();
    const leaderboard = await db.all(
      'SELECT name, run_highscore FROM solmates ORDER BY run_highscore DESC LIMIT 20'
    );
    res.json(leaderboard);
  } catch (error) {
    console.error('Failed to fetch leaderboard:', error);
    res.status(500).json({ message: 'Failed to fetch leaderboard' });
  }
});

export default router;
