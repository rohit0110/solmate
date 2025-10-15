
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

class RunGameScreen extends StatefulWidget {
  final Uint8List solmateImageBytes;

  const RunGameScreen({
    super.key, 
    required this.solmateImageBytes,
  });

  @override
  State<RunGameScreen> createState() => _RunGameScreenState();
}

class _RunGameScreenState extends State<RunGameScreen> {
  static const double playerWidth = 50.0;
  static const double playerHeight = 50.0;
  static const double obstacleWidth = 30.0;
  static const double obstacleHeight = 60.0;
  static const double groundHeight = 0.0;
  static const double gameSpeed = 200.0; // pixels per second

  double playerY = 0;
  double playerVelocityY = 0;
  final double gravity = 980.0; // pixels per second^2
  final double jumpVelocity = -500.0; // pixels per second

  List<double> obstacleX = [400.0, 700.0];
  int score = 0;
  bool isGameOver = false;
  Timer? gameLoopTimer;
  double gameAreaHeight = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    gameAreaHeight = MediaQuery.of(context).size.height * 0.6;
  }

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    playerY = 0;
    playerVelocityY = 0;
    obstacleX = [400.0, 700.0];
    score = 0;
    isGameOver = false;
    gameLoopTimer?.cancel();
    gameLoopTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!isGameOver) {
        updateGame(16 / 1000.0);
      }
    });
  }

  void updateGame(double deltaTime) {
    setState(() {
      // Update player position
      playerVelocityY += gravity * deltaTime;
      playerY += playerVelocityY * deltaTime;

      if (playerY > 0) {
        playerY = 0;
        playerVelocityY = 0;
      }

      // Update obstacle positions
      for (int i = 0; i < obstacleX.length; i++) {
        obstacleX[i] -= gameSpeed * deltaTime;
        if (obstacleX[i] < -obstacleWidth) {
          obstacleX[i] = 800.0; // Reset obstacle position
          score++;
        }
      }

      // Check for collision (use a constrained game area so visuals sit near middle)
  final double screenW = MediaQuery.of(context).size.width;

      final playerRect = Rect.fromLTWH(
        50,
        gameAreaHeight - groundHeight - playerHeight + playerY,
        playerWidth,
        playerHeight,
      );

      for (int i = 0; i < obstacleX.length; i++) {
        final x = obstacleX[i];
        final obstacleRect = Rect.fromLTWH(
          x,
          gameAreaHeight - groundHeight - obstacleHeight,
          obstacleWidth,
          obstacleHeight,
        );
        if (playerRect.overlaps(obstacleRect)) {
          isGameOver = true;
          gameLoopTimer?.cancel();
        }
        if (x < -obstacleWidth) {
          // reset obstacle off the right edge
          obstacleX[i] = screenW + 100.0;
          score++;
        }
      }
    });
  }

  void jump() {
    if (playerY == 0) {
      setState(() {
        playerVelocityY = jumpVelocity;
      });
    }
  }

  @override
  void dispose() {
    gameLoopTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    ImageProvider imageProvider = MemoryImage(widget.solmateImageBytes);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isGameOver ? startGame : jump,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 60.0, left: 20.0, right: 20.0),
            child: SizedBox(
              height: gameAreaHeight,
              width: double.infinity,
              child: NesContainer(
                padding: const EdgeInsets.all(12.0),
                backgroundColor: colorScheme.surface,
                child: Stack(
                  children: [
                    // Player
                    Positioned(
                      left: 50,
                      bottom: groundHeight - playerY,
                      child: Image(
                        image: imageProvider,
                        width: playerWidth,
                        height: playerHeight,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                    // Obstacles
                    ...obstacleX.map((x) => Positioned(
                          left: x,
                          bottom: groundHeight,
                          child: NesContainer(
                            width: obstacleWidth,
                            height: obstacleHeight,
                            backgroundColor: Colors.green,
                          ),
                        )),
                    // Ground
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: groundHeight,
                        color: colorScheme.surface,
                      ),
                    ),
                    // Score
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Text(
                        'SCORE: $score',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                      ),
                    ),
                    // Game Over Message
                    if (isGameOver)
                      Center(
                        child: NesContainer(
                          padding: const EdgeInsets.all(16.0),
                          backgroundColor: colorScheme.surface,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'GAME OVER',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Your Score: $score',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 20),
                              NesButton(
                                type: NesButtonType.primary,
                                onPressed: startGame,
                                child: const Text('Restart'),
                              ),
                              const SizedBox(height: 10),
                              NesButton(
                                type: NesButtonType.normal,
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Back to Solmate'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
