import express from 'express';
import { openDb } from '../db/database.js';
import { Database } from 'sqlite';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import { addXp, getXpForLevel, XP_FOR_FEED, XP_FOR_PET, XP_PER_RUN_SCORE } from '../services/leveling_service.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = express.Router();

interface SolmateData {
  pubkey: string;
  name: string;
  animal: string;
  level: number;
  xp: number;
  run_highscore: number;
  last_fed_at: string;
  last_pet_at: string;
  poos_cleaned: number;
  pets_given: number;
  food_fed: number;
  created_at: string;
  updated_at: string;
}

async function getFullSolmateData(db: Database, pubkey: string): Promise<any | null> {
    const solmate: SolmateData | undefined = await db.get<SolmateData>(
      'SELECT * FROM solmates WHERE pubkey = ?',
      [pubkey]
    );

    if (!solmate) {
      return null;
    }

    const decorationsFromDb = await db.all(
      'SELECT row, col, decoration_name as name, decoration_url as url FROM selected_decorations WHERE solmate_pubkey = ?',
      [pubkey]
    );

    const userLevel = solmate.level;
    const purchased = await db.all('SELECT asset_id FROM unlocked_assets WHERE user_pubkey = ?', pubkey);
    const unlockedAssets = new Set(purchased.map((p: any) => p.asset_id));

    const manifestPath = path.join(__dirname, '..', 'assets', 'decorations', 'manifest.json');
    const manifestContent = await fs.readFile(manifestPath, 'utf-8');
    const manifest = JSON.parse(manifestContent);

    const decorations = decorationsFromDb.map((deco: any) => {
      const manifestItem = manifest.find((item: any) => `/assets/decorations/${item.filename}` === deco.url);

      let isUnlocked = false;
      let unlock = null;

      if (manifestItem) {
        unlock = manifestItem.unlock;
        const assetId = `decoration_${manifestItem.name}`;
        if (!manifestItem.unlock) {
          isUnlocked = true;
        } else if (manifestItem.unlock.type === 'level' && userLevel >= manifestItem.unlock.level) {
          isUnlocked = true;
        } else if (unlockedAssets.has(assetId)) {
          isUnlocked = true;
        }
      } else {
        isUnlocked = true;
      }

      return {
        ...deco,
        unlock: unlock,
        isUnlocked: isUnlocked,
      };
    });

    return {
      ...solmate,
      decorations: decorations,
    };
}


function calculateStats(solmate: SolmateData) {
  const now = new Date();
  const lastFed = new Date(solmate.last_fed_at);
  const lastPet = new Date(solmate.last_pet_at);

  const hoursSinceFed = (now.getTime() - lastFed.getTime()) / (1000 * 60 * 60);
  const health = Math.max(0, Math.min(100, 100 - hoursSinceFed * 4));

  const hoursSincePet = (now.getTime() - lastPet.getTime()) / (1000 * 60 * 60);
  const happiness = Math.max(0, Math.min(100, 100 - hoursSincePet * 2));

  const xpForNextLevel = getXpForLevel(solmate.level + 1);

  return {
    ...solmate,
    health: Math.round(health),
    happiness: Math.round(happiness),
    xp: solmate.xp,
    level: solmate.level,
    xp_for_next_level: xpForNextLevel,
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
    const solmateWithDecorations = await getFullSolmateData(req.db, pubkey);

    if (!solmateWithDecorations) {
      // Return null if not found, so frontend can distinguish between not found and error
      return res.json(null);
    }

    res.json(calculateStats(solmateWithDecorations as SolmateData));
  } catch (error) {
    console.error('Error fetching solmate:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/solmate
router.post('/', async (req, res) => {
  const { pubkey, name, animal } = req.body;
  if (!pubkey || !name) {
    return res.status(400).json({ error: 'pubkey and name are required' });
  }

  try {
    const existingSolmate = await req.db.get('SELECT * FROM solmates WHERE pubkey = ?', [pubkey]);
    if (existingSolmate) {
      return res.status(409).json({ error: 'Solmate already exists for this pubkey' });
    }

    const now = new Date().toISOString();
    const defaultBackground = '/assets/background/background_day.png';
    await req.db.run(
      'INSERT INTO solmates (pubkey, name, level, xp, run_highscore, animal, last_fed_at, last_pet_at, created_at, updated_at, selected_background) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [pubkey, name, 1, 0, 0, animal, now, now, now, now, defaultBackground]
    );

    const newSolmate = await getFullSolmateData(req.db, pubkey);
    if (!newSolmate) {
      return res.status(500).json({ error: 'Failed to retrieve new solmate after creation' });
    }
    res.status(201).json(calculateStats(newSolmate as SolmateData));
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
    let solmate = await req.db.get<SolmateData>('SELECT * FROM solmates WHERE pubkey = ?', [pubkey]);
    if (!solmate) {
      return res.status(404).json({ error: 'Solmate not found' });
    }

    const now = new Date();
    const lastFed = new Date(solmate.last_fed_at);
    const hoursSinceFed = (now.getTime() - lastFed.getTime()) / (1000 * 60 * 60);
    const currentHealth = Math.max(0, 100 - hoursSinceFed * 4);
    const newHealth = Math.min(100, currentHealth + 10);
    const newHoursSinceFed = (100 - newHealth) / 4;
    const newLastFedDate = new Date(now.getTime() - newHoursSinceFed * 60 * 60 * 1000);
    const newLastFedAt = newLastFedDate.toISOString();

    await req.db.run(
      'UPDATE solmates SET last_fed_at = ?, food_fed = food_fed + 1, updated_at = ? WHERE pubkey = ?',
      [newLastFedAt, now.toISOString(), pubkey]
    );

    // Add XP for feeding
    await addXp(req.db, pubkey, XP_FOR_FEED);

    const updatedSolmate = await getFullSolmateData(req.db, pubkey);
    if (!updatedSolmate) {
        return res.status(404).json({ error: 'Solmate not found after update' });
    }
    res.json(calculateStats(updatedSolmate as SolmateData));
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
    const solmate = await req.db.get<SolmateData>('SELECT * FROM solmates WHERE pubkey = ?', [pubkey]);
    if (!solmate) {
      return res.status(404).json({ error: 'Solmate not found' });
    }

    const now = new Date();
    const lastPet = new Date(solmate.last_pet_at);
    const hoursSincePet = (now.getTime() - lastPet.getTime()) / (1000 * 60 * 60);
    const currentHappiness = Math.max(0, 100 - hoursSincePet * 2);
    const newHappiness = Math.min(100, currentHappiness + 10);
    const newHoursSincePet = (100 - newHappiness) / 2;
    const newLastPetDate = new Date(now.getTime() - newHoursSincePet * 60 * 60 * 1000);
    const newLastPetAt = newLastPetDate.toISOString();

    await req.db.run(
      'UPDATE solmates SET last_pet_at = ?, pets_given = pets_given + 1, updated_at = ? WHERE pubkey = ?',
      [newLastPetAt, now.toISOString(), pubkey]
    );

    // Add XP for petting
    await addXp(req.db, pubkey, XP_FOR_PET);

    const updatedSolmate = await getFullSolmateData(req.db, pubkey);
    if (!updatedSolmate) {
        return res.status(404).json({ error: 'Solmate not found after update' });
    }
    res.json(calculateStats(updatedSolmate as SolmateData));
  } catch (error) {
    console.error('Error petting solmate:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/solmate/clean
router.post('/clean', async (req, res) => {
  const { pubkey } = req.body;
  if (!pubkey) {
    return res.status(400).json({ error: 'pubkey is required' });
  }

  try {
    const solmate = await req.db.get<SolmateData>('SELECT * FROM solmates WHERE pubkey = ?', [pubkey]);
    if (!solmate) {
      return res.status(404).json({ error: 'Solmate not found' });
    }

    await req.db.run('UPDATE solmates SET has_poo = 0, poos_cleaned = poos_cleaned + 1, updated_at = ? WHERE pubkey = ?', [new Date().toISOString(), pubkey]);

    // Add a small amount of XP for cleaning
    await addXp(req.db, pubkey, 5);

    const updatedSolmate = await getFullSolmateData(req.db, pubkey);
    if (!updatedSolmate) {
        return res.status(404).json({ error: 'Solmate not found after update' });
    }
    res.json(calculateStats(updatedSolmate as SolmateData));
  } catch (error) {
    console.error('Error cleaning solmate poo:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/solmate/run
router.post('/run', async (req, res) => {
    const { pubkey, score } = req.body;
    if (!pubkey || score === undefined) {
        return res.status(400).json({ error: 'pubkey and score are required' });
    }

    if (typeof score !== 'number' || score < 0) {
        return res.status(400).json({ error: 'score must be a non-negative number' });
    }

    try {
        const solmate = await req.db.get<SolmateData>('SELECT * FROM solmates WHERE pubkey = ?', [pubkey]);
        if (!solmate) {
            return res.status(404).json({ error: 'Solmate not found' });
        }

        const xpGained = Math.floor(score * XP_PER_RUN_SCORE);
        if (xpGained > 0) {
            await addXp(req.db, pubkey, xpGained);
        }

        // New logic for high score
        if (score > solmate.run_highscore) {
            await req.db.run('UPDATE solmates SET run_highscore = ? WHERE pubkey = ?', [score, pubkey]);
        }

        const updatedSolmate = await getFullSolmateData(req.db, pubkey);
        if (!updatedSolmate) {
            return res.status(404).json({ error: 'Solmate not found after update' });
        }
        res.json(calculateStats(updatedSolmate as SolmateData));

    } catch (error) {
        console.error('Error during /run:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

router.post('/decorations', async (req, res) => {
  const { pubkey, decorations } = req.body;

  if (!pubkey || !Array.isArray(decorations)) {
    return res.status(400).json({ error: 'pubkey and decorations array are required' });
  }

  const db = req.db;

  try {
    // --- Security Validation Step ---
    const solmate = await db.get('SELECT * FROM solmates WHERE pubkey = ?', [pubkey]);
    if (!solmate) {
      return res.status(404).json({ error: 'User not found' });
    }
    const userLevel = solmate.level;

    const manifestPath = path.join(__dirname, '..', 'assets', 'decorations', 'manifest.json');
    const manifestContent = await fs.readFile(manifestPath, 'utf-8');
    const manifest = JSON.parse(manifestContent);

    for (const row of decorations) {
      for (const asset of row) {
        if (!asset) continue;

        const manifestItem = manifest.find((item: any) => item.url === asset.url || `/assets/decorations/${item.filename}` === asset.url);
        
        if (manifestItem && manifestItem.unlock) {
          if (manifestItem.unlock.type === 'level' && userLevel < manifestItem.unlock.level) {
            return res.status(403).json({ error: `Attempted to equip a locked item: ${asset.name}. Required level: ${manifestItem.unlock.level}` });
          }
          // TODO: Add validation for 'paid' items once payment tracking is implemented
        }
      }
    }
    // --- End Security Validation ---


    // Use a transaction to ensure atomicity
    await db.exec('BEGIN TRANSACTION');

    // Clear old decorations for this user
    await db.run('DELETE FROM selected_decorations WHERE solmate_pubkey = ?', [pubkey]);

    // Insert new decorations
    const insertStmt = await db.prepare(
      'INSERT INTO selected_decorations (solmate_pubkey, row, col, decoration_name, decoration_url) VALUES (?, ?, ?, ?, ?)'
    );

    for (let r = 0; r < decorations.length; r++) {
        const row = decorations[r];
        for (let c = 0; c < row.length; c++) {
            const asset = row[c];
            if (asset) {
                await insertStmt.run(pubkey, r, c, asset.name, asset.url);
            }
        }
    }

    await insertStmt.finalize();
    await db.exec('COMMIT');

    res.status(200).json({ message: 'Decorations saved successfully' });
  } catch (error) {
    await db.exec('ROLLBACK');
    console.error('Error saving decorations:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/background', async (req, res) => {
  const { pubkey, backgroundUrl } = req.body;

  if (!pubkey || !backgroundUrl) {
    return res.status(400).json({ error: 'pubkey and backgroundUrl are required' });
  }

  const db = req.db;

  try {
    // --- Security Validation Step ---
    const solmate = await db.get('SELECT * FROM solmates WHERE pubkey = ?', [pubkey]);
    if (!solmate) {
      return res.status(404).json({ error: 'User not found' });
    }
    const userLevel = solmate.level;

    const manifestPath = path.join(__dirname, '..', 'assets', 'background', 'manifest.json');
    const manifestContent = await fs.readFile(manifestPath, 'utf-8');
    const manifest = JSON.parse(manifestContent);

    const bgManifestItem = manifest.find((item: any) => `/assets/background/${item.filename}` === backgroundUrl);

    if (!bgManifestItem) {
        return res.status(404).json({ error: 'Selected background not found in manifest.' });
    }

    if (bgManifestItem.unlock) {
        if (bgManifestItem.unlock.type === 'level' && userLevel < bgManifestItem.unlock.level) {
            return res.status(403).json({ error: `Attempted to equip a locked background. Required level: ${bgManifestItem.unlock.level}` });
        }
        // TODO: Add validation for 'paid' items
    }
    // --- End Security Validation ---

    await db.run('UPDATE solmates SET selected_background = ? WHERE pubkey = ?', [backgroundUrl, pubkey]);

    res.status(200).json({ message: 'Background saved successfully' });
  } catch (error) {
    console.error('Error saving background:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
