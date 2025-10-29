// src/server.ts
import app from './app.js';
import config from './config/config.js';
import { startXpCronJob } from './cron/xp_cron.js';
import { startPooCronJob } from './cron/poo_cron.js';
import { initializeDatabase } from './db/database.js';

const startServer = async () => {
  try {
    await initializeDatabase(); // Initialize database first

    app.listen(config.port, () => {
      console.log(`Server running on port ${config.port}`);
    });

    // Start the CRON job for hourly XP distribution
    startXpCronJob();

    // Start the CRON job for hourly poo generation
    startPooCronJob();
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1); // Exit if database initialization fails
  }
};

startServer(); // Call the async function to start the server


