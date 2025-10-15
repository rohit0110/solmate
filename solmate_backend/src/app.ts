import express from 'express';
import cors from 'cors';
import spriteRouter from './routes/sprite.js';
import solmateRoutes from './routes/solmate.js';
import decorRoutes from './routes/decor.js';

const app = express();

app.use(cors());
app.use(express.json());

// Serve static assets from the 'assets/decorations' directory
app.use('/assets/decorations', express.static('src/assets/decorations'));

// Routes
app.get('/', (req, res) => {
  res.send('Hello, Solmate!');
});

app.use('/api/sprite', spriteRouter);
app.use('/api/solmate', solmateRoutes);
app.use('/api/decor', decorRoutes);

export default app;