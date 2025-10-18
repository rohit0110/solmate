
import crypto from 'crypto';
import sharp from 'sharp';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

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
  const colorFilePath = path.join(__dirname, '..', 'assets', 'sprites','manifest.json');
  const colorFile = await fs.readFile(colorFilePath, 'utf-8');
  const allColors = JSON.parse(colorFile);

  const animalColors = allColors[animal.toUpperCase()];
  if (!animalColors) {
    return [];
  }

  const featureColors: FeatureColor[] = [];
  for (const feature in animalColors) {
    const hex = animalColors[feature];
    const rgb = hexToRgb(hex);
    if (rgb) {
      featureColors.push({ feature, originalColor: rgb });
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
      if (newColor) {
        data[i] = newColor.r;
        data[i+1] = newColor.g;
        data[i+2] = newColor.b;
      }
    }
  }
  
  return sharp(data, { raw: info }).png().toBuffer();
}

// --- Exportable Service Function ---

export async function generateNormalSprite(animal: string, pubkey: string): Promise<string> {
    // 1. Get original feature colors
    const originalFeatureColors = await getOriginalColors(animal);
    if (originalFeatureColors.length === 0) {
      // Return a placeholder or throw an error if colors aren't found
      throw new Error(`Could not parse feature colors for ${animal}.`);
    }

    // 2. Deterministically generate new colors
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

    // 3. Generate normal sprite
    const normalSpritePath = path.join(__dirname, '..', 'assets/sprites', `${animal}_normal.png`);
    
    try {
        await fs.access(normalSpritePath);
    } catch (e) {
        throw new Error(`Sprite for animal '${animal}' not found.`);
    }

    const normalSpriteBuffer = await generateColoredSprite(normalSpritePath, newFeatureColors, originalFeatureColors);

    // 4. Return as Base64 string
    return normalSpriteBuffer.toString('base64');
}
