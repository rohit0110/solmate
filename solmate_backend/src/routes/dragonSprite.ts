import { Router } from 'express';
import crypto from 'crypto';
import sharp from 'sharp';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = Router();

// --- Helper Functions ---

function hexToRgb(hex: string): { r: number; g: number; b: number } | null {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result ? {
    r: parseInt(result[1]!, 16),
    g: parseInt(result[2]!, 16),
    b: parseInt(result[3]!, 16)
  } : null;
}

interface FeatureColor {
  feature: string;
  originalColor: { r: number; g: number; b: number };
}

async function getOriginalColors(): Promise<FeatureColor[]> {
  const colorFilePath = path.join(__dirname, '..', 'assets', 'colors.md');
  const colorFile = await fs.readFile(colorFilePath, 'utf-8');
  const lines = colorFile.split('\n');
  
  const featureColors: FeatureColor[] = [];
  
  for (const line of lines) {
    if (line.includes('- #')) {
      const parts = line.split('-');
      const feature = parts[0]!.trim();
      const hex = parts[1]!.trim();
      const rgb = hexToRgb(hex);
      if (rgb) {
        featureColors.push({ feature, originalColor: rgb });
      }
    }
  }
  return featureColors;
}

// --- Route ---

router.get('/:pubkey', async (req, res) => {
  try {
    const { pubkey } = req.params;

    // 1. Get original feature colors
    const originalFeatureColors = await getOriginalColors();
    if (originalFeatureColors.length === 0) {
      throw new Error('Could not parse feature colors from colors.md');
    }

    // 2. Deterministically generate new colors for each feature
    const newFeatureColors: { [feature: string]: { r: number; g: number; b: number } } = {};
    let hash = crypto.createHash('sha256').update(pubkey).digest();

    for (const featureColor of originalFeatureColors) {
        // Use parts of the hash to generate a color. Re-hash to get more bytes if needed.
        if (hash.length < 3) {
            hash = crypto.createHash('sha256').update(hash).digest();
        }
        newFeatureColors[featureColor.feature] = {
            r: hash[0]!,
            g: hash[1]!,
            b: hash[2]!,
        };
        hash = hash.subarray(3);
    }

    // 3. Image Manipulation
    const baseSpritePath = path.join(__dirname, '..', 'assets', 'dragon_normal.png');

    const image = sharp(baseSpritePath);
    const { data, info } = await image.raw().toBuffer({ resolveWithObject: true });

    // Create a map of original colors for quick lookup
    const originalColorMap = new Map<string, string>(); // "r,g,b" -> feature name
    for (const fc of originalFeatureColors) {
        originalColorMap.set(`${fc.originalColor.r},${fc.originalColor.g},${fc.originalColor.b}`, fc.feature);
    }

    for (let i = 0; i < data.length; i += info.channels) {
      const r = data[i];
      const g = data[i + 1];
      const b = data[i + 2];
      
      const feature = originalColorMap.get(`${r},${g},${b}`);
      if (feature) {
        const newColor = newFeatureColors[feature];
        data[i] = newColor!.r;
        data[i+1] = newColor!.g;
        data[i+2] = newColor!.b;
      }
    }
    
    const outputImage = await sharp(data, { raw: info }).png().toBuffer();

    res.set('Content-Type', 'image/png');
    res.send(outputImage);

  } catch (error) {
    console.error(error);
    res.status(500).send('Error generating sprite');
  }
});

export default router;
