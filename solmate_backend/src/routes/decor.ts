import { Router } from 'express';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = Router();

// Maps from string names in filenames to numeric indices
const rowNameToIndex: { [key: string]: number } = {
  'top': 0,
  'middle': 1,
  'bottom': 2,
};

const colNameToIndex: { [key: string]: number } = {
  'left': 0,
  'center': 1,
  'right': 2,
};

router.get('/', async (req, res) => {
  try {
    const decorationsPath = path.join(__dirname, '..', 'assets', 'decorations');
    const files = await fs.readdir(decorationsPath);

    const decorations: { row: number; col: number; name: string; url: string }[] = [];

    for (const file of files) {
      // Match filenames like top_left_asset-name.png
      const match = file.match(/^([a-z]+)_([a-z]+)_(.+)\.png$/);

      if (match) {
        const [, rowName, colName, assetName] = match;

        if (rowName && colName && assetName) {
          const rowIndex = rowNameToIndex[rowName];
          const colIndex = colNameToIndex[colName];

          // Ensure the parsed names are valid and exist in our maps
          if (rowIndex !== undefined && colIndex !== undefined) {
            decorations.push({
              row: rowIndex,
              col: colIndex,
              name: assetName.replace(/-/g, ' '), // Replace hyphens with spaces for display
              url: `/assets/decorations/${file}`,
            });
          }
        }
      }
    }

    res.json(decorations);
  } catch (error) {
    // If the directory doesn't exist, it's not a server error.
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
