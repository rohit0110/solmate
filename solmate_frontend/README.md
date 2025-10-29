# Solmate Frontend: Your Solana-Powered Digital Pet App

Solmate is an innovative Flutter project that brings a Tamagotchi-like digital pet experience directly to your mobile device, uniquely integrated with the Solana blockchain. This document details the frontend application.

## Idea & Core Features

**Your Wallet, Your Pet:** Each Solmate is intrinsically linked to your mobile wallet address, ensuring a unique digital companion for every user.

**Nurture & Interact:** Engage with your Solmate by feeding it, petting it, and cleaning up after it, fostering its health and happiness.

**Dynamic Customization:** Personalize your Solmate with a wide array of accessories and backgrounds. These can be earned through activity on the Solana network or acquired by purchasing unique skins and items.

**Mini-Game Fun:** Play a simple running game with your Solmate to earn high scores and XP.

**Leaderboards:** Compete with other Solmate owners on global leaderboards for run high scores and survival time.

**Share Your Solmate:** Capture and share images of your unique Solmate with friends.

## Application Screens & Functionality

The Solmate frontend guides users through several key screens:

*   **Home Screen (`HomeScreen`):** The entry point for the application. Facilitates connecting your Solana mobile wallet.
<img width="108" height="240" alt="Screenshot_20251029_163406" src="https://github.com/user-attachments/assets/2dc792fd-0de1-4bc3-8cb5-15aa12cb334a" />

*   **Solmate Selection Screen (`SolmateSelectionScreen`):** If you don't have a Solmate yet, this screen allows you to choose your first digital companion from a selection of animals.
<img width="108" height="240" alt="Screenshot_20251029_163608" src="https://github.com/user-attachments/assets/4903c4d3-57d4-474d-b24a-c12fc4332a98" />

*   **Solmate Hatching Screen (`SolmateHatchingScreen`):** After selecting an animal, you'll name your Solmate and mint its associated NFT (or create its record in the backend).
<img width="108" height="240" alt="Screenshot_20251029_163626" src="https://github.com/user-attachments/assets/93b1c25c-4c96-4420-a75a-cf5f644ca236" />

*   **Solmate Screen (`SolmateScreen`):** The main interaction hub. Here you can:
    *   View your Solmate's health, happiness, level, and XP.
    *   Feed, pet, emote, and clean up after your Solmate. Feeding is a Memo Tx
    *   Access the Marketplace, Run Game, Leaderboards, and Share features.
 <img width="108" height="240" alt="Screenshot_20251029_164037" src="https://github.com/user-attachments/assets/838decf7-62c4-47bc-ab27-f9be2e7dfe2a" />

*   **Marketplace Screen (`MarketplaceScreen`):** Browse and purchase various decorations and backgrounds for your Solmate. Items can be unlocked by level or bought with SOL.
  <img width="108" height="240" alt="Screenshot_20251029_164021" src="https://github.com/user-attachments/assets/c25453d5-b184-4f91-93ac-625450d62d79" />
<img width="108" height="240" alt="Screenshot_20251029_164028" src="https://github.com/user-attachments/assets/a689aca0-770c-4109-8590-423333fc91f3" />

*   **Run Game Screen (`RunGameScreen`):** A simple side-scrolling mini-game where your Solmate jumps over obstacles. Earn XP and high scores.
  <img width="108" height="240" alt="Screenshot_20251029_163701" src="https://github.com/user-attachments/assets/ffe9edd1-6012-492c-b76c-a391e02d64d1" />

*   **Leaderboard Screen (`LeaderboardScreen`):** Displays the global leaderboard based on run high scores.
  <img width="108" height="240" alt="Screenshot_20251029_163919" src="https://github.com/user-attachments/assets/bbe6813a-0c98-4c0d-918d-b8efed72d5a9" />

*   **Survival Leaderboard Screen (`SurvivalLeaderboardScreen`):** Displays a leaderboard based on how long Solmates have survived (stayed fed).
*   **Share Screen (`ShareScreen`):** Allows you to generate and share an image of your Solmate, with or without its background and decorations.
  <img width="108" height="240" alt="Screenshot_20251029_163956" src="https://github.com/user-attachments/assets/d27897f0-e4b6-4222-a6b0-1dbf0b596b76" />
<img width="108" height="240" alt="Screenshot_20251029_163947" src="https://github.com/user-attachments/assets/92b0f471-101a-425c-aab2-9f2f63429be7" />


## Getting Started

This project requires both the Flutter frontend and a running Node.js backend.

### Prerequisites

*   **Flutter SDK:** [Install Flutter](https://flutter.dev/docs/get-started/install)
*   **Mock Wallet (for local development):** If you're developing locally and don't have a physical device with a wallet, you'll need to set up a mock wallet for `solana_mobile_client`. Refer to `solana_mobile_client` documentation for details on setting up a mock wallet.


### Frontend Setup (`solmate_frontend`)

1.  **Navigate to the frontend directory:**
    ```bash
    cd solmate_frontend
    ```
2.  **Get Flutter dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Configure Environment Variables:** Create a `.env` file in the `solmate_frontend` directory:
    ```
    BACKEND_URL="http://10.0.2.2:3000" # Or your deployed backend URL
    APP_IDENTITY_URI="solmate://app"
    APP_IDENTITY_NAME="solmate_frontend"
    SOLANA_CLUSTER="devnet" # Or 'mainnet-beta', 'testnet'
    ```
    *(Ensure `BACKEND_URL` matches where your backend is running.)*
4.  **Run the application:**
    ```bash
    flutter run
    ```
    *(If running on a physical device/emulator, ensure it can access your `BACKEND_URL`.)*

## Android Widget

The project also includes an Android App Widget that displays your Solmate's image and name, providing a quick glance at your digital companion directly from your home screen.

<img width="108" height="240" alt="Screenshot_20251029_114144" src="https://github.com/user-attachments/assets/b92f5b95-03d7-4c89-a3f2-b79079214336" />
