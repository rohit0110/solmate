import express from 'express';
import { openDb } from '../db/database.js';
import { Database } from 'sqlite';

const router = express.Router();

interface SolmateData {
  pubkey: string;
  name: string;
  last_fed_at: string;
  last_pet_at: string;
  created_at: string;
  updated_at: string;
}

function calculateStats(solmate: SolmateData) {
  const now = new Date();
  const lastFed = new Date(solmate.last_fed_at);
  const lastPet = new Date(solmate.last_pet_at);

  const hoursSinceFed = (now.getTime() - lastFed.getTime()) / (1000 * 60 * 60);
  const health = Math.max(0, Math.min(100, 100 - hoursSinceFed * 4));

  const hoursSincePet = (now.getTime() - lastPet.getTime()) / (1000 * 60 * 60);
  const happiness = Math.max(0, Math.min(100, 100 - hoursSincePet * 2));

  return {
    ...solmate,
    health: Math.round(health),
    happiness: Math.round(happiness),
  };
}

// Middleware to ensure db is open
router.use(async (req, res, next) => {
  try {
    req.db = await openDb(); // Attach db to request object
    next();
  } catch (error) {
    console.error('Failed to open database:', error);
    res.status(500).json({ error: 'Database connection failed' });
  }
});

// Extend Request type to include db
declare global {
  namespace Express {
    interface Request {
      db: Database;
    }
  }
}

// GET /api/solmate?pubkey=<pubkey>
router.get('/', async (req, res) => {
  const pubkey = req.query.pubkey as string;
  if (!pubkey) {
    return res.status(400).json({ error: 'pubkey query parameter is required' });
  }

  try {
    const solmate: SolmateData | undefined = await req.db.get<SolmateData>(
      'SELECT * FROM solmates WHERE pubkey = ?',
      [pubkey]
    );

    if (!solmate) {
      return res.status(404).json({ error: 'Solmate not found' });
    }

    res.json(calculateStats(solmate));
  } catch (error) {
    console.error('Error fetching solmate:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/solmate
router.post('/', async (req, res) => {
  const { pubkey, name } = req.body;
  if (!pubkey || !name) {
    return res.status(400).json({ error: 'pubkey and name are required' });
  }

  try {
    const existingSolmate = await req.db.get('SELECT * FROM solmates WHERE pubkey = ?', [pubkey]);
    if (existingSolmate) {
      return res.status(409).json({ error: 'Solmate already exists for this pubkey' });
    }

    const now = new Date().toISOString();
    await req.db.run(
      'INSERT INTO solmates (pubkey, name, last_fed_at, last_pet_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
      [pubkey, name, now, now, now, now]
    );

    const newSolmate = await req.db.get<SolmateData>('SELECT * FROM solmates WHERE pubkey = ?', [pubkey]);
    if (!newSolmate) {
      return res.status(500).json({ error: 'Failed to retrieve new solmate after creation' });
    }
    res.status(201).json(calculateStats(newSolmate));
  } catch (error) {
    console.error('Error creating solmate:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/solmate/feed
router.post('/feed', async (req, res) => {
  const { pubkey } = req.body;
  if (!pubkey) {
    return res.status(400).json({ error: 'pubkey is required' });
  }

  try {
    const now = new Date().toISOString();
    const result = await req.db.run(
      'UPDATE solmates SET last_fed_at = ?, updated_at = ? WHERE pubkey = ?',
      [now, now, pubkey]
    );

    if (result.changes === 0) {
      return res.status(404).json({ error: 'Solmate not found' });
    }

    const updatedSolmate = await req.db.get<SolmateData>('SELECT * FROM solmates WHERE pubkey = ?', [pubkey]);
    if (!updatedSolmate) {
        return res.status(404).json({ error: 'Solmate not found after update' });
    }
    res.json(calculateStats(updatedSolmate));
  } catch (error) {
    console.error('Error feeding solmate:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/solmate/pet
router.post('/pet', async (req, res) => {
  const { pubkey } = req.body;
  if (!pubkey) {
    return res.status(400).json({ error: 'pubkey is required' });
  }

  try {
    const now = new Date().toISOString();
    const result = await req.db.run(
      'UPDATE solmates SET last_pet_at = ?, updated_at = ? WHERE pubkey = ?',
      [now, now, pubkey]
    );

    if (result.changes === 0) {
      return res.status(404).json({ error: 'Solmate not found' });
    }

    const updatedSolmate = await req.db.get<SolmateData>('SELECT * FROM solmates WHERE pubkey = ?', [pubkey]);
    if (!updatedSolmate) {
        return res.status(404).json({ error: 'Solmate not found after update' });
    }
    res.json(calculateStats(updatedSolmate));
  } catch (error) {
    console.error('Error petting solmate:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
