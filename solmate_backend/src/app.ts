import express from 'express';
import cors from 'cors';
import spriteRouter from './routes/sprite.js';

const app = express();

app.use(cors());
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  res.send('Hello, Solmate!');
});

app.use('/api/sprite', spriteRouter);

export default app;