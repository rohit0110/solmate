import dotenv from 'dotenv';

dotenv.config();

interface Config {
  port: number;
  recipientPublicKey: string;
  solanaRpcUrl: string;
}

const config: Config = {
  port: Number(process.env.PORT) || 3000,
  recipientPublicKey: process.env.RECIPIENT_PUBLIC_KEY || '',
  solanaRpcUrl: process.env.SOLANA_RPC_URL || '',
};

export default config;