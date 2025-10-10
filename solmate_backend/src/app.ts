import express from 'express';
import cors from 'cors';
import spriteRouter from './routes/sprite.js';
import solmateRoutes from './routes/solmate.js';

const app = express();

app.use(cors());
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  res.send('Hello, Solmate!');
});

app.use('/api/sprite', spriteRouter);
app.use('/api/solmate', solmateRoutes);

export default app;