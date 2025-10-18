// src/server.ts
import app from './app.js';
import config from './config/config.js';
import { startXpCronJob } from './cron/xp_cron.js';

app.listen(config.port, () => {
  console.log(`Server running on port ${config.port}`);
});

// Start the CRON job for hourly XP distribution
startXpCronJob();

