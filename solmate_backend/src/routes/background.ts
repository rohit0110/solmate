import { Router } from 'express';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = Router();

router.get('/', async (req, res) => {
  try {
    const manifestPath = path.join(__dirname, '..', 'assets', 'background', 'manifest.json');
    const manifestContent = await fs.readFile(manifestPath, 'utf-8');
    const manifest = JSON.parse(manifestContent);

    const backgrounds = manifest.map((asset: any) => ({
      name: asset.name,
      url: `/assets/background/${asset.filename}`,
      unlock: asset.unlock,
    }));

    res.json(backgrounds);
  } catch (error) {
    if (error instanceof Error && 'code' in error && error.code === 'ENOENT') {
      res.json([]);
    } else {
      console.error('Error fetching backgrounds:', error);
      res.status(500).send('Error fetching backgrounds');
    }
  }
});

export default router;
