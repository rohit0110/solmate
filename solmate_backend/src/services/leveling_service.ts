import { Database } from 'sqlite';

// --- XP & Leveling Constants ---
export const XP_FOR_PET = 10;
export const XP_FOR_FEED = 10;
export const XP_PER_RUN_SCORE = 0.5; // 0.5 XP per point of score in the run game
export const HOURLY_XP_CRON = 5;

export const LEVEL_FORMULA_BASE = 100;
export const LEVEL_FORMULA_EXPONENT = 1.5;

// --- Helper Functions for Leveling ---

/**
 * Calculates the total XP required to reach a specific level.
 * @param level The target level.
 * @returns The total XP required.
 */
export function getXpForLevel(level: number): number {
  if (level <= 1) return 0;
  return Math.floor(LEVEL_FORMULA_BASE * Math.pow(level - 1, LEVEL_FORMULA_EXPONENT));
}

/**
 * Determines the level based on the total accumulated XP.
 * @param xp The total experience points.
 * @returns The calculated level.
 */
export function getLevelFromXp(xp: number): number {
    if (xp < LEVEL_FORMULA_BASE) return 1;
    // Inverse of getXpForLevel: level = (xp / base)^(1/exp) + 1
    const level = Math.floor(Math.pow(xp / LEVEL_FORMULA_BASE, 1 / LEVEL_FORMULA_EXPONENT)) + 1;
    return level;
}

/**
 * Adds XP to a solmate and handles level-up logic.
 * @param db The database instance.
 * @param pubkey The public key of the solmate's owner.
 * @param amount The amount of XP to add.
 */
export async function addXp(db: Database, pubkey: string, amount: number) {
    const solmate = await db.get('SELECT * FROM solmates WHERE pubkey = ?', [pubkey]);
    if (!solmate) {
        console.warn(`Attempted to add XP to non-existent solmate with pubkey: ${pubkey}`);
        return;
    }

    const newXp = solmate.xp + amount;
    const newLevel = getLevelFromXp(newXp);

    if (newLevel > solmate.level) {
        // Level up!
        await db.run('UPDATE solmates SET xp = ?, level = ?, updated_at = ? WHERE pubkey = ?', [newXp, newLevel, new Date().toISOString(), pubkey]);
        console.log(`Solmate ${solmate.name} (${pubkey}) leveled up to level ${newLevel}!`);
    } else {
        // Just add XP
        await db.run('UPDATE solmates SET xp = ?, updated_at = ? WHERE pubkey = ?', [newXp, new Date().toISOString(), pubkey]);
    }
}
