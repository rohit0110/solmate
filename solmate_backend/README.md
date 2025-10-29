# Solmate Backend: Node.js/Express API

This is the backend API for the Solmate digital pet application. It is built with Node.js and Express, using PostgreSQL as its database. It handles all application logic, including Solmate data management, interactions (feed, pet, clean), marketplace operations, leaderboard calculations, and Solana transaction verification.

## Technologies Used

*   **Node.js:** JavaScript runtime environment.
*   **Express.js:** Web application framework for Node.js.
*   **TypeScript:** Superset of JavaScript that adds static typing.
*   **PostgreSQL:** Relational database (hosted on Supabase).
*   **`node-cron`:** For scheduled tasks (e.g., Solmate pooing, XP distribution).
*   **`sharp`:** For image processing (generating unique Solmate sprites).
*   **`@solana/web3.js`:** Solana blockchain interaction.
*   **`pg`:** PostgreSQL client for Node.js.
*   **`dotenv`:** For managing environment variables.

## API Endpoints

The backend exposes the following main API endpoints:

*   **`/api/solmate`**:
    *   `GET /api/solmate?pubkey=<pubkey>`: Get a Solmate's data and calculated stats.
    *   `POST /api/solmate`: Create a new Solmate.
    *   `POST /api/solmate/feed`: Feed a Solmate.
    *   `POST /api/solmate/pet`: Pet a Solmate.
    *   `POST /api/solmate/clean`: Clean a Solmate's poo.
    *   `POST /api/solmate/run`: Submit a run game score.
    *   `POST /api/solmate/decorations`: Save selected decorations.
    *   `POST /api/solmate/background`: Save selected background.
*   **`/api/sprite/:animal/:pubkey`**: `GET`: Generate unique sprites for a Solmate based on its animal type and owner's public key.
*   **`/api/decor`**: `GET /api/decor?pubkey=<pubkey>`: Get available decorations for the marketplace.
*   **`/api/backgrounds`**: `GET /api/backgrounds?pubkey=<pubkey>`: Get available backgrounds for the marketplace.
*   **`/api/leaderboard`**:
    *   `GET /api/leaderboard?pubkey=<pubkey>`: Get the run highscore leaderboard.
    *   `GET /api/leaderboard/survival?pubkey=<pubkey>`: Get the survival time leaderboard.
*   **`/api/purchase/verify`**: `POST`: Verify Solana transactions for asset purchases.

## Getting Started

### Prerequisites

*   **Node.js & npm:** [Install Node.js](https://nodejs.org/en/download/)
*   **PostgreSQL Database:** A running PostgreSQL instance (e.g., from [Supabase](https://supabase.com/)).

### Installation & Running Locally

1.  **Navigate to the backend directory:**
    ```bash
    cd solmate_backend
    ```
2.  **Install dependencies:**
    ```bash
    npm install
    ```
3.  **Configure Environment Variables:** Create a `.env` file in the `solmate_backend` directory with your PostgreSQL connection string:
    ```
    DATABASE_URL="postgresql://postgres:[YOUR-PASSWORD]@db.xxxxxxxx.supabase.co:5432/postgres"
    ```
    *(Remember to URL-encode your password if it contains special characters.)*
4.  **Build the backend:**
    ```bash
    npm run build
    ```
5.  **Start the backend server:**
    ```bash
    npm start
    ```
    The backend should now be running, typically on `http://localhost:3000`.


## Deployment

Ensure your `DATABASE_URL` is set as an environment variable in your deployment platform's settings.
