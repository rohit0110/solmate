import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:solmate_frontend/screens/run_game_screen.dart';
import 'package:solmate_frontend/screens/solmate_data.dart';

class SolmateScreen extends StatefulWidget {
  final SolmateAnimal solmateAnimal;
  final String solmateName;
  final String publicKey;
  final Map<String, String>? solmateSprites; // Added this

  const SolmateScreen({
    super.key,
    required this.solmateAnimal,
    required this.publicKey,
    required this.solmateName,
    this.solmateSprites, // Added this
  });

  @override
  State<SolmateScreen> createState() => _SolmateScreenState();
}

class _SolmateScreenState extends State<SolmateScreen> {
  late String _solmateNameDisplay;
  int _health = 100;
  int _happiness = 100;
  bool _isHappy = false;
  String _message = "Welcome to your Solmate!";

  // For unique sprites
  Uint8List? _normalSpriteBytes;
  Uint8List? _happySpriteBytes;

  @override
  void initState() {
    super.initState();
    _solmateNameDisplay = widget.solmateName;

    if (widget.solmateSprites != null) {
      _normalSpriteBytes = base64Decode(widget.solmateSprites!['normal']!);
      _happySpriteBytes = base64Decode(widget.solmateSprites!['happy']!);
    }

    _saveSolmateData();
  }

  Future<void> _saveSolmateData() async {
    await HomeWidget.saveWidgetData<String>('solmateName', _solmateNameDisplay);
    await HomeWidget.saveWidgetData<int>('solmateHealth', _health);
    await HomeWidget.saveWidgetData<int>('solmateHappiness', _happiness);
    
    // TODO: Handle saving generated sprite to home widget. 
    // Base64 strings might be too large for widget data.
    if (widget.solmateAnimal.name != "Dragon") {
       await HomeWidget.saveWidgetData<String>('solmateImageUrl', 
        _isHappy
            ? widget.solmateAnimal.happySpritePath
            : widget.solmateAnimal.normalSpritePath
      );
    }
    await HomeWidget.updateWidget(name: 'SolmateWidget');
  }

  void _feedSolmate() {
    setState(() {
      _health = (_health + 10).clamp(0, 100);
      _happiness = (_happiness + 5).clamp(0, 100);
      _message = "You fed your Solmate!";
    });
    _saveSolmateData();
  }

  void _petSolmate() {
    setState(() {
      _happiness = (_happiness + 15).clamp(0, 100);
      _message = "You pet your Solmate!";
    });
    _saveSolmateData();
  }

  void _emoteSolmate() {
    setState(() {
      _isHappy = !_isHappy;
      _message = _isHappy ? "Your Solmate emotes happily!" : "Your Solmate is back to normal!";
    });
    _saveSolmateData();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background, // Use background color from theme
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: NesContainer(
                  padding: const EdgeInsets.all(16.0),
                  label: "solmate",
                  backgroundColor: colorScheme.surface, // Use surface color for display area
                  painterBuilder: NesContainerSquareCornerPainter.new,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.solmateAnimal.name == "Dragon" && _normalSpriteBytes != null)
                        Image.memory(
                          _isHappy ? _happySpriteBytes! : _normalSpriteBytes!,
                          width: 150,
                          height: 150,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                        )
                      else if (widget.solmateAnimal.normalSpritePath.startsWith('http'))
                        Image.network(
                          widget.solmateAnimal.normalSpritePath,
                          width: 150,
                          height: 150,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none, // For pixelated look
                          errorBuilder: (context, error, stackTrace) => NesContainer(
                            width: 150,
                            height: 150,
                            backgroundColor: colorScheme.background,
                            child: Icon(Icons.pets, size: 80, color: colorScheme.onBackground.withOpacity(0.5)),
                          ),
                        )
                      else // Fallback for original dragon asset if sprites fail to load
                        Image.asset(
                          _isHappy ? widget.solmateAnimal.happySpritePath : widget.solmateAnimal.normalSpritePath,
                          width: 150,
                          height: 150,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                          errorBuilder: (context, error, stackTrace) => NesContainer(
                            width: 150,
                            height: 150,
                            backgroundColor: colorScheme.background,
                            child: Icon(Icons.pets, size: 80, color: colorScheme.onBackground.withOpacity(0.5)),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        _solmateNameDisplay.toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface, // Use onSurface color
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildStatRow('HP', _health, colorScheme.error, Icons.favorite),
                      _buildStatRow('HAP', _happiness, colorScheme.tertiary, Icons.sentiment_satisfied_alt),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20), // Spacing between card and message
            // Message display area
            NesRunningText(text: _message),
            const Spacer(),
            // Hardware-like buttons
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
              color: colorScheme.background, // Use background color for console body
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _HardwareButton(icon: Icons.restaurant, label: 'Feed', onPressed: _feedSolmate),
                  _HardwareButton(icon: Icons.pets, label: 'Pet', onPressed: _petSolmate),
                  _HardwareButton(icon: Icons.tag_faces, label: 'Emote', onPressed: _emoteSolmate),
                  _HardwareButton(
                    icon: Icons.directions_run,
                    label: 'Run',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RunGameScreen(
                            solmateImageBytes: widget.solmateAnimal.name == "Dragon" 
                                ? _normalSpriteBytes 
                                : null,
                            solmateImagePath: widget.solmateAnimal.name != "Dragon" 
                                ? widget.solmateAnimal.normalSpritePath 
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
          color: colorScheme.primary, // Use primary color for button base
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: _isPressed
              ? [] // No shadow when pressed
              : [
                  BoxShadow(
                    color: colorScheme.onSurface.withOpacity(0.3), // Use onSurface for shadow
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
