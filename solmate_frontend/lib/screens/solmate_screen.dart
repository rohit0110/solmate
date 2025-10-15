import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:solmate_frontend/api/solmate_api.dart';
import 'package:solmate_frontend/screens/run_game_screen.dart';
import 'package:solmate_frontend/screens/solmate_data.dart';
import 'package:solmate_frontend/screens/marketplace_screen.dart';

class SolmateScreen extends StatefulWidget {
  final String animalName;
  final String solmateName;
  final String publicKey;
  final Map<String, String>? solmateSprites;

  const SolmateScreen({
    super.key,
    required this.animalName,
    required this.publicKey,
    required this.solmateName,
    this.solmateSprites,
  });

  @override
  State<SolmateScreen> createState() => _SolmateScreenState();
}

class _SolmateScreenState extends State<SolmateScreen> {
  final SolmateBackendApi _api = SolmateBackendApi();
  late String _solmateNameDisplay;
  int _health = 100;
  int _happiness = 100;
  bool _isHappy = false;
  String _message = "Welcome to your Solmate!";
  bool _isLoading = true;

  // For unique sprites
  Uint8List? _normalSpriteBytes;
  Uint8List? _happySpriteBytes;
  Uint8List? _deadSpriteBytes;

  final List<String> _deadMessages = [
    "LEAVE THEM ALONE YOU MONSTER",
    "Oh he DEAD dead already",
    "Too late you emotionless doodoohead",
    "Stay away you Necrophiliac!",
  ];

  String _getRandomDeadMessage() {
    final random = Random();
    return _deadMessages[random.nextInt(_deadMessages.length)];
  }

  // New state for accessories
  List<List<bool>> _accessoryGrid = List.generate(3, (_) => List.generate(3, (_) => false));

  @override
  void initState() {
    super.initState();
    _solmateNameDisplay = widget.solmateName;

    if (widget.solmateSprites != null) {
      _normalSpriteBytes = base64Decode(widget.solmateSprites!['normal']!);
      _happySpriteBytes = base64Decode(widget.solmateSprites!['happy']!);
      _deadSpriteBytes = base64Decode(widget.solmateSprites!['dead']!);
    }

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final data = await _api.getSolmateData(widget.publicKey);
      setState(() {
        _health = data!['health'];
        _happiness = data['happiness'];
        _solmateNameDisplay = data['name'] ?? widget.solmateName;
        if (_health <= 0) {
          _message = "Solmate has perished! RIP $_solmateNameDisplay";
        } else {
          _message = "Your Solmate is ready!";
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = "Error loading data: $e";
        _isLoading = false;
      });
    }
    _saveSolmateData();
  }

  Future<void> _saveSolmateData() async {
    await HomeWidget.saveWidgetData<String>('solmateName', _solmateNameDisplay);
    await HomeWidget.saveWidgetData<int>('solmateHealth', _health);
    await HomeWidget.saveWidgetData<int>('solmateHappiness', _happiness);
    
    if (_normalSpriteBytes != null) {
      final bytes = _health <= 0 && _deadSpriteBytes != null
          ? _deadSpriteBytes!
          : (_isHappy ? _happySpriteBytes! : _normalSpriteBytes!);
      await HomeWidget.saveWidgetData<String>('solmateImageBytes', base64Encode(bytes));
    }
    await HomeWidget.updateWidget(name: 'SolmateWidget');
  }

  void _feedSolmate() async {
    if (_health <= 0) {
      setState(() {
        _message = _getRandomDeadMessage();
      });
      return;
    }
    setState(() {
      _message = "Feeding your Solmate...";
    });
    try {
      final data = await _api.feedSolmate(widget.publicKey);
      setState(() {
        _health = data['health'];
        _happiness = data['happiness'];
        _message = "You fed your Solmate!";
      });
    } catch (e) {
      setState(() {
        _message = "Failed to feed: $e";
      });
    }
    _saveSolmateData();
  }

  void _petSolmate() async {
    if (_health <= 0) {
      setState(() {
        _message = _getRandomDeadMessage();
      });
      return;
    }
    setState(() {
      _message = "Petting your Solmate...";
    });
    try {
      final data = await _api.petSolmate(widget.publicKey);
      setState(() {
        _happiness = data['happiness'];
        _message = "You pet your Solmate!";
      });
    } catch (e) {
      setState(() {
        _message = "Failed to pet: $e";
      });
    }
    _saveSolmateData();
  }

  void _emoteSolmate() {
    if (_health <= 0) {
      setState(() {
        _message = _getRandomDeadMessage();
      });
      return;
    }
    if(_happiness >= 50) {
      setState(() {
        _isHappy = !_isHappy;
        _message = _isHappy ? "Your Solmate emotes happily!" : "Your Solmate is back to normal!";
      });
    } else {
      setState(() {
        _message = "Your Solmate is too unhappy to emote!";
      });
    }
    _saveSolmateData();
  }

  Widget _buildSolmateImage(double size, {bool isHappy = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_health <= 0 && _deadSpriteBytes != null) {
      return Image.memory(
        _deadSpriteBytes!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      );
    }

    if (_normalSpriteBytes != null) {
      return Image.memory(
        isHappy ? _happySpriteBytes! : _normalSpriteBytes!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      );
    } else {
      // Fallback if sprites are not available for some reason.
      return NesContainer(
        width: size,
        height: size,
        backgroundColor: colorScheme.background,
        child: Icon(Icons.error_outline, size: size * 0.5, color: colorScheme.onBackground.withOpacity(0.5)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate available space for the NesContainer after outer padding
    final containerAvailableWidth = screenWidth - (2 * 8.0); // 8.0 is padding from outer Padding
    final containerAvailableHeight = (screenHeight * 0.6) - (2 * 8.0);
    
    // Determine the largest square dimension for the NesContainer
    final nesContainerOuterDimension = min(containerAvailableWidth, containerAvailableHeight);

    return Scaffold(
      backgroundColor: colorScheme.background, // Use background color from theme
      body: SafeArea(
        child: _isLoading
            ? const Center(child: Text("Loading..."))
            : Column(
                children: [
                  SizedBox(
                    height: nesContainerOuterDimension + (2 * 8.0), // Add back the outer padding
                    width: nesContainerOuterDimension + (2 * 8.0), // Add back the outer padding
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: NesContainer(
                        padding: const EdgeInsets.all(16.0), // Reverted padding
                        label: _solmateNameDisplay.toUpperCase(),
                        backgroundColor: colorScheme.surface,
                        painterBuilder: NesContainerSquareCornerPainter.new,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // constraints.maxWidth and constraints.maxHeight will now be nesContainerOuterDimension - (2 * 16.0)
                            final gridDisplaySize = min(constraints.maxWidth, constraints.maxHeight); // Should be equal
                            final cellSize = gridDisplaySize / 3;

                            return Stack( // New Stack for layering
                              children: [
                                // Background Layer (single sprite for the entire grid)
                                Image.asset(
                                  'assets/sprites/background.png', // Path to the new background image
                                  width: gridDisplaySize,
                                  height: gridDisplaySize,
                                  fit: BoxFit.cover, // Cover the entire grid area
                                  filterQuality: FilterQuality.none, // For pixel art style
                                ),

                                // Grid Layer (Column of Rows)
                                Column( // No need for Center or SizedBox here, it will fill LayoutBuilder
                                  children: List.generate(3, (row) {
                                    return Row(
                                      children: List.generate(3, (col) {
                                        return Container(
                                          width: cellSize,
                                          height: cellSize,
                                          decoration: BoxDecoration(
                                            // Removed: color: backgroundColor,
                                            // Individual cells are now transparent to show the single background
                                          ),
                                          child: Stack(
                                            children: [
                                              // Accessories layer
                                              if (_accessoryGrid[row][col] && !(row == 2 && col == 1))
                                                Center(
                                                  child: _buildSolmateImage(cellSize * 0.8), // Accessory
                                                ),

                                              // Solmate layer (only at [2][1])
                                              if (row == 2 && col == 1)
                                                Center(
                                                  child: _buildSolmateImage(cellSize * 0.9, isHappy: _isHappy), // Solmate
                                                ),
                                            ],
                                          ),
                                        );
                                      }),
                                    );
                                  }),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Spacing between card and message
                  // New: Hunger and Happiness display
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Happiness (Heart icon and happiness value)
                        Row(
                          children: [
                            Icon(Icons.sentiment_satisfied_alt, color: colorScheme.tertiary, size: 24), // Changed from NesIcon.heart
                            const SizedBox(width: 8),
                            Text('$_happiness', style: TextStyle(fontSize: 18, color: colorScheme.onBackground)),
                          ],
                        ),
                        // Hunger (Apple icon and health value)
                        Row(
                          children: [
                            NesIcon(iconData: NesIcons.apple),
                            const SizedBox(width: 8),
                            Text('$_health', style: TextStyle(fontSize: 18, color: colorScheme.onBackground)),
                          ],
                        ), 
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Message display area
                  // NesRunningText(text: _message) // TODO: Running Text spills over and looks bad, can try to fix later
                  Center(
                    child: Text(
                      _message,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(),
                  // Hardware-like buttons
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
                    color: colorScheme.background, // Use background color for console body
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _HardwareButton(icon: Icons.restaurant, label: 'Feed', onPressed: _feedSolmate),
                            _HardwareButton(icon: Icons.pets, label: 'Pet', onPressed: _petSolmate),
                            _HardwareButton(icon: Icons.tag_faces, label: 'Emote', onPressed: _emoteSolmate),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _HardwareButton(
                              icon: Icons.shopping_cart,
                              label: 'Shop',
                              onPressed: () async {
                                if (_health <= 0) {
                                  setState(() {
                                    _message = _getRandomDeadMessage();
                                  });
                                  return;
                                }
                                final updatedGrid = await Navigator.push<List<List<bool>>>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MarketplaceScreen(initialAccessoryGrid: _accessoryGrid),
                                  ),
                                );
                                if (updatedGrid != null) {
                                  setState(() {
                                    _accessoryGrid = updatedGrid;
                                  });
                                }
                              },
                            ),
                            _HardwareButton(
                              icon: Icons.directions_run,
                              label: 'Run',
                              onPressed: () {
                                if (_health <= 0) {
                                  setState(() {
                                    _message = _getRandomDeadMessage();
                                  });
                                  return;
                                }
                                if (_normalSpriteBytes != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RunGameScreen(
                                        solmateImageBytes: _normalSpriteBytes!,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}




class _HardwareButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _HardwareButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_HardwareButton> createState() => _HardwareButtonState();
}

class _HardwareButtonState extends State<_HardwareButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: colorScheme.onSurface.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ],
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.5), width: 2.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: colorScheme.onPrimary, size: 30),
            const SizedBox(height: 5),
            Text(
              widget.label,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

