import express from 'express';
import dragonSpriteRouter from './routes/dragonSprite.js';

const app = express();

app.use(express.json());

// Routes
app.get('/', (req, res) => {
  res.send('Hello, Solmate!');
});

app.use('/api/sprite/dragon', dragonSpriteRouter);

export default app;