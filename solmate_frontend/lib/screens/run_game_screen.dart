
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:solmate_frontend/api/solmate_api.dart';
import 'package:solmate_frontend/screens/leaderboard_screen.dart';

class RunGameScreen extends StatefulWidget {
  final Uint8List solmateImageBytes;
  final String pubKey;
  final int highScore;

  const RunGameScreen({
    super.key,
    required this.solmateImageBytes,
    required this.pubKey,
    required this.highScore,
  });

  @override
  State<RunGameScreen> createState() => _RunGameScreenState();
}

class _RunGameScreenState extends State<RunGameScreen> {
  final SolmateBackendApi _api = SolmateBackendApi();
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
  bool _isSubmitting = false;
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
    setState(() {
      playerY = 0;
      playerVelocityY = 0;
      obstacleX = [400.0, 700.0];
      score = 0;
      isGameOver = false;
      _isSubmitting = false;
      gameLoopTimer?.cancel();
      gameLoopTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (!isGameOver) {
          updateGame(16 / 1000.0);
        }
      });
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

  Future<void> _submitScoreAndExit() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _api.run(widget.pubKey, score);
    } catch (e) {
      // Optionally, show an error message to the user
      print("Failed to submit score: $e");
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
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
        onTap: isGameOver ? null : jump, // Disable jump when game is over
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
                    // High Score
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Text(
                        'HI: ${widget.highScore}',
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
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const LeaderboardScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Leaderboard'),
                              ),
                              const SizedBox(height: 10),
                              NesButton(
                                type: NesButtonType.normal,
                                onPressed: _isSubmitting ? null : _submitScoreAndExit,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Back to Solmate'),
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
