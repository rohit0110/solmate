import { Router } from 'express';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import config from '../config/config.js';
import { openDb } from '../db/database.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = Router();

router.get('/', async (req, res) => {
  const userPubkey = req.query.pubkey as string;

  try {
    const db = await openDb();
    let userLevel = 1;
    let unlockedAssets = new Set();

    if (userPubkey) {
      const user = await db.get('SELECT level FROM solmates WHERE pubkey = ?', userPubkey);
      if (user) {
        userLevel = user.level;
      }

      const purchased = await db.all('SELECT asset_id FROM unlocked_assets WHERE user_pubkey = ?', userPubkey);
      unlockedAssets = new Set(purchased.map(p => p.asset_id));
    }

    const manifestPath = path.join(__dirname, '..', 'assets', 'decorations', 'manifest.json');
    const manifestContent = await fs.readFile(manifestPath, 'utf-8');
    const manifest = JSON.parse(manifestContent);

    const decorations = manifest.map((asset: any) => {
      const assetId = `decoration_${asset.name}`;
      let isUnlocked = false;

      if (!asset.unlock) {
        isUnlocked = true;
      } else if (asset.unlock.type === 'level' && userLevel >= asset.unlock.level) {
        isUnlocked = true;
      } else if (unlockedAssets.has(assetId)) {
        isUnlocked = true;
      }

      const decoration: any = {
        row: asset.row,
        col: asset.col,
        name: asset.name,
        url: `/assets/decorations/${asset.filename}`,
        unlock: asset.unlock,
        isUnlocked: isUnlocked,
      };

      if (asset.unlock?.type === 'paid') {
        decoration.paymentInfo = {
          recipientPublicKey: config.recipientPublicKey,
          amount: asset.unlock.amount,
        };
      }

      return decoration;
    });

    res.json(decorations);
  } catch (error) {
    if (error instanceof Error && 'code' in error && error.code === 'ENOENT') {
      res.json([]);
    } else {
      console.error('Error fetching decorations:', error);
      res.status(500).send('Error fetching decorations');
    }
  }
});

export default router;

