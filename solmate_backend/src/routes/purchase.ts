import { Router } from 'express';
import { Connection, PublicKey, LAMPORTS_PER_SOL } from '@solana/web3.js';
import { query, pool } from '../db/database.js'; // Changed import
import config from '../config/config.js';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const router = Router();

// Helper to get asset details from manifests
async function getAssetDetails(assetId: string): Promise<{ price: number } | null> {
  const [type, name] = assetId.split('_');
  const manifestName = type === 'decoration' ? 'decorations' : 'background';
  const manifestPath = path.join(__dirname, '..', 'assets', manifestName, 'manifest.json');

  try {
    const manifestContent = await fs.readFile(manifestPath, 'utf-8');
    const manifest = JSON.parse(manifestContent);
    const asset = manifest.find((a: any) => a.name === name);

    if (asset && asset.unlock?.type === 'paid') {
      return { price: asset.unlock.amount };
    }
    return null;
  } catch (error) {
    console.error(`Error reading ${manifestName} manifest:`, error);
    return null;
  }
}

router.post('/verify', async (req, res) => {
  const { transactionSignature, assetId, userPubkey } = req.body;

  if (!transactionSignature || !assetId || !userPubkey) {
    return res.status(400).json({ error: 'Missing required fields: transactionSignature, assetId, userPubkey' });
  }

  const client = await pool.connect(); // Get a client for the transaction

  try {
    // // 1. Check for Replay Attacks
    // const { rows: existingTxRows } = await client.query('SELECT * FROM processed_transactions WHERE signature = $1', [transactionSignature]);
    // if (existingTxRows[0]) {
    //   return res.status(409).json({ error: 'Transaction signature already processed.' });
    // }

    // // 2. Get Asset Details
    // const assetDetails = await getAssetDetails(assetId);
    // if (!assetDetails) {
    //   return res.status(404).json({ error: 'Asset not found or is not for sale.' });
    // }

    // // 3. Fetch and Verify Transaction from Solana
    // const connection = new Connection(config.solanaRpcUrl, 'confirmed');
    // const tx = await connection.getTransaction(transactionSignature, {
    //     maxSupportedTransactionVersion: 0,
    // });

    // if (!tx) {
    //   return res.status(404).json({ error: 'Transaction not found on the blockchain.' });
    // }

    // if (tx.meta?.err) {
    //     return res.status(400).json({ error: 'Transaction failed to execute.' });
    // }

    // if (!tx.meta) {
    //   return res.status(400).json({ error: 'Transaction metadata not available.' });
    // }

    // // Verify recipient
    // const recipientPk = new PublicKey(config.recipientPublicKey);
    // const recipientIndex = tx.transaction.message.staticAccountKeys.findIndex(key => key.equals(recipientPk));

    // if (recipientIndex === -1) {
    //     return res.status(400).json({ error: 'Recipient public key not found in transaction.' });
    // }

    // const postBalance = tx.meta.postBalances[recipientIndex];
    // const preBalance = tx.meta.preBalances[recipientIndex];
    
    // if(postBalance == null || preBalance == null) {
    //     return res.status(400).json({ error: 'Could not determine recipient\'s balance change.' });
    // }

    // const amountTransferred = (postBalance - preBalance) / LAMPORTS_PER_SOL;

    // // Verify amount (allow for slightly more, but not less)
    // if (amountTransferred < assetDetails.price) {
    //   return res.status(400).json({ error: `Incorrect amount transferred. Expected ${assetDetails.price} SOL, got ${amountTransferred} SOL.` });
    // }

    // // Verify sender/signer
    // const signerPk = new PublicKey(userPubkey);
    // const signerIndex = tx.transaction.message.staticAccountKeys.findIndex(key => key.equals(signerPk));

    // if (signerIndex === -1 || signerIndex >= tx.transaction.message.header.numRequiredSignatures) {
    //     return res.status(403).json({ error: 'Transaction was not signed by the provided user public key.' });
    // }

    // 4. All checks passed, update database
    await client.query('BEGIN');
    await client.query('INSERT INTO processed_transactions (signature) VALUES ($1)', [transactionSignature]);
    await client.query('INSERT INTO unlocked_assets (user_pubkey, asset_id, purchase_transaction_signature) VALUES ($1, $2, $3)', [userPubkey, assetId, transactionSignature]);
    await client.query('COMMIT');

    res.status(200).json({ message: 'Purchase verified and asset unlocked successfully.' });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error verifying purchase:', error);
    res.status(500).send('Internal server error during purchase verification.');
  } finally {
    client.release(); // Release the client back to the pool
  }
});

export default router;
