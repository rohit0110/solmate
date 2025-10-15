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

async function getOriginalColors(animal: string): Promise<FeatureColor[]> {
  const colorFilePath = path.join(__dirname, '..', 'assets', 'colors.md');
  const colorFile = await fs.readFile(colorFilePath, 'utf-8');
  const lines = colorFile.split('\n');
  
  const featureColors: FeatureColor[] = [];
  let inCorrectSection = false;
  const sectionHeader = `### ${animal.toUpperCase()}`;

  for (const line of lines) {
    if (line.startsWith('###')) { // A new animal section starts
        inCorrectSection = line.trim() === sectionHeader;
    }
    
    if (inCorrectSection && line.includes('- #')) {
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

async function generateColoredSprite(
  baseSpritePath: string, 
  newFeatureColors: { [feature: string]: { r: number; g: number; b: number } },
  originalFeatureColors: FeatureColor[]
): Promise<Buffer> {
  const image = sharp(baseSpritePath);
  const { data, info } = await image.raw().toBuffer({ resolveWithObject: true });

  const originalColorMap = new Map<string, string>();
  for (const fc of originalFeatureColors) {
      originalColorMap.set(`${fc.originalColor.r},${fc.originalColor.g},${fc.originalColor.b}`, fc.feature);
  }

  for (let i = 0; i < data.length; i += info.channels) {
    const r = data[i]!;
    const g = data[i + 1]!;
    const b = data[i + 2]!;
    
    const feature = originalColorMap.get(`${r},${g},${b}`);
    if (feature) {
      const newColor = newFeatureColors[feature];
      data[i] = newColor!.r;
      data[i+1] = newColor!.g;
      data[i+2] = newColor!.b;
    }
  }
  
  return sharp(data, { raw: info }).png().toBuffer();
}

// --- Route ---

router.get('/:animal/:pubkey', async (req, res) => {
  try {
    const { animal, pubkey } = req.params;

    // 1. Get original feature colors
    const originalFeatureColors = await getOriginalColors(animal);
    if (originalFeatureColors.length === 0) {
      throw new Error(`Could not parse feature colors for ${animal} from colors.md`);
    }

    // 2. Deterministically generate new colors for each feature
    const newFeatureColors: { [feature: string]: { r: number; g: number; b: number } } = {};
    let hash = crypto.createHash('sha256').update(pubkey).digest();

    for (const featureColor of originalFeatureColors) {
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

    // 3. Generate sprites in parallel
    const normalSpritePath = path.join(__dirname, '..', 'assets', `${animal}_normal.png`);
    const happySpritePath = path.join(__dirname, '..', 'assets', `${animal}_happy.png`);
    const deadSpritePath = path.join(__dirname, '..', 'assets', `${animal}_dead.png`);

    try {
        await fs.access(normalSpritePath);
        await fs.access(happySpritePath);
        await fs.access(deadSpritePath);
    } catch (e) {
        return res.status(404).send(`Sprites for animal '${animal}' not found.`);
    }

    const [normalSpriteBuffer, happySpriteBuffer, deadSpriteBuffer] = await Promise.all([
      generateColoredSprite(normalSpritePath, newFeatureColors, originalFeatureColors),
      generateColoredSprite(happySpritePath, newFeatureColors, originalFeatureColors),
      generateColoredSprite(deadSpritePath, newFeatureColors, originalFeatureColors)
    ]);

    // 4. Send JSON response with Base64 encoded images
    res.json({
      normal: normalSpriteBuffer.toString('base64'),
      happy: happySpriteBuffer.toString('base64'),
      dead: deadSpriteBuffer.toString('base64')
    });

  } catch (error) {
    console.error(error);
    res.status(500).send('Error generating sprite');
  }
});

export default router;
