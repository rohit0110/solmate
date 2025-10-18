import { Router } from 'express';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = Router();

router.get('/', async (req, res) => {
  try {
    const manifestPath = path.join(__dirname, '..', 'assets', 'decorations', 'manifest.json');
    const manifestContent = await fs.readFile(manifestPath, 'utf-8');
    const manifest = JSON.parse(manifestContent);

    const decorations = manifest.map((asset: any) => ({
      row: asset.row,
      col: asset.col,
      name: asset.name,
      url: `/assets/decorations/${asset.filename}`,
      unlock: asset.unlock, // Include the unlock condition
    }));

    res.json(decorations);
  } catch (error) {
    // If the manifest file doesn't exist, it's not a server error.
    // Just return an empty array.
    if (error instanceof Error && 'code' in error && error.code === 'ENOENT') {
      res.json([]);
    } else {
      console.error('Error fetching decorations:', error);
      res.status(500).send('Error fetching decorations');
    }
  }
});

export default router;

