import dotenv from 'dotenv';

dotenv.config();

interface Config {
  port: number;
  recipientPublicKey: string;
  solanaRpcUrl: string;
  databaseUrl: string;
}

const config: Config = {
  port: Number(process.env.PORT) || 3000,
  recipientPublicKey: process.env.RECIPIENT_PUBLIC_KEY || '',
  solanaRpcUrl: process.env.SOLANA_RPC_URL || '',
  databaseUrl: process.env.DATABASE_URL || '',
};

if (!config.databaseUrl) {
  console.warn('DATABASE_URL environment variable is not set. Database connection may fail.');
}

export default config;