import express from 'express';
import cors from 'cors';
import dragonSpriteRouter from './routes/dragonSprite.js';

const app = express();

app.use(cors());
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  res.send('Hello, Solmate!');
});

app.use('/api/sprite/dragon', dragonSpriteRouter);

export default app;