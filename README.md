# Poopy — Your Solana-Powered Digital Pet

Poopy is a Tamagotchi-inspired mobile app built on Solana. Each pet is uniquely tied to your wallet address — your on-chain activity keeps your pet alive, leveled up, and dressed for success.

Built for the Colosseum Hackathon.

**[Pitch Deck](https://www.canva.com/design/DAG3PBc0K8k/m2KTZoHJRRSo3wqxOZEJrw/edit?utm_content=DAG3PBc0K8k&utm_campaign=designshare&utm_medium=link2&utm_source=sharebutton) · [Pitch Video](https://www.loom.com/share/7516be207254476b8f774dbaa020987a) · [Tech Video](https://www.loom.com/share/3e5f1d49226e4f3fa9be7ec5fae8aada)**

---

## What It Does

When you connect your Solana wallet, Solmate generates a pixel-art pet unique to your public key. From there, you keep it alive by feeding it, petting it, and cleaning up after it — just like a classic Tamagotchi. But unlike a Tamagotchi, your on-chain activity on Solana earns your pet XP and unlocks cosmetics.

**Core loop:**
- Feed your pet → restores health (costs a small memo transaction on-chain to prevent spam)
- Pet your pet → boosts happiness
- Clean poo → keeps things tidy (poo generated on a CRON schedule)
- Play the run game → earn highscore entries on the survival leaderboard
- Buy decorations and backgrounds → personalize your pet's environment
- Share your pet card → post to Twitter/X to flex

**Stats:**
| Stat | Effect |
|---|---|
| Health | Decays over time. Reaches 0 → pet dies |
| Happiness | Decays over time. Falls below 50 → pet refuses to eat or be petted |
| Level / XP | Earned by on-chain Solana activity, tracked by a backend CRON |

---

## Architecture

```
solmate/
├── solmate_frontend/     # Flutter mobile app (Android)
└── solmate_backend/      # Node.js / Express API + CRON jobs
```

### Frontend — Flutter

- **Wallet auth** via Solana Mobile Wallet Adapter (MWA)
- **Procedural sprites** — pixel art generated server-side from your public key
- **Screens:** home, pet selection, hatching, main pet interaction, marketplace, leaderboard, run game, share card
- **Android home screen widget** — displays your pet's sprite and name
- Retro NES-styled UI with dark theme

**Key packages:** `solana_mobile_client`, `solana`, `home_widget`, `share_plus`

### Backend — Node.js / Express + PostgreSQL

- REST API powering all pet data, decorations, backgrounds, leaderboard, and purchases
- **PostgreSQL** for persistence
- **CRON jobs:**
  - XP distribution — scans Solana transaction history and rewards on-chain activity
  - Poo generation — randomly creates poo events for pets over time
- **`@solana/web3.js`** for reading on-chain data

**API routes:**
| Route | Purpose |
|---|---|
| `/api/solmate` | Pet CRUD, feeding, petting, death logic |
| `/api/sprite` | Sprite generation from pubkey |
| `/api/decor` | Decoration management |
| `/api/backgrounds` | Background assets |
| `/api/leaderboard` | Run game and survival leaderboards |
| `/api/purchase` | Marketplace transactions |

**Database tables:** `solmates`, `selected_decorations`, `unlocked_assets`, `processed_transactions`

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter (Dart) |
| Wallet | Solana Mobile Wallet Adapter |
| Backend | Node.js, Express v5, TypeScript |
| Database | PostgreSQL |
| Blockchain | Solana (`@solana/web3.js`) |
| Scheduling | node-cron |
| Image processing | sharp |

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.9.2
- Node.js ≥ 18
- A PostgreSQL database (e.g. Supabase)
- A Solana-compatible Android wallet (e.g. Phantom, Solflare)

### Backend

```bash
cd solmate_backend
npm install
cp .env.example .env   # set DATABASE_URL, SOLANA_RPC_URL, PORT
npm run dev
```

### Frontend

```bash
cd solmate_frontend
flutter pub get
# set your backend URL in .env or lib/config
flutter run
```

---

## Features Shipped

- [x] Wallet-linked procedurally generated pixel pets
- [x] Health / happiness stat system with decay and death
- [x] On-chain memo transactions for anti-spam feeding
- [x] XP from Solana on-chain activity (CRON)
- [x] Marketplace with level-locked cosmetics (decorations + backgrounds)
- [x] Run mini-game with survival leaderboard
- [x] Shareable pet card (Twitter / X)
- [x] Android home screen widget
- [x] PostgreSQL backend

## Roadmap

- [ ] NFT minting via Metaplex
- [ ] Rate limiting on API endpoints
- [ ] NES-styled UI components throughout

---

## Team

Built at the Colosseum Hackathon — [View project submission](https://arena.colosseum.org/hackathon/project)
