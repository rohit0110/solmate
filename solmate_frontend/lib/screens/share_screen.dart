
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:solmate_frontend/api/solmate_api.dart';
import 'package:solmate_frontend/api/sprite_api.dart';
import 'package:solmate_frontend/models/decoration_asset.dart';

enum ShareOption { spriteOnly, withBackground }

class ShareScreen extends StatefulWidget {
  final String publicKey;

  const ShareScreen({super.key, required this.publicKey});

  @override
  _ShareScreenState createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final SolmateBackendApi _api = SolmateBackendApi();
  final ScreenshotController _spriteOnlyScreenshotController = ScreenshotController();
  final ScreenshotController _withBackgroundScreenshotController = ScreenshotController();
  Map<String, dynamic>? _solmateData;
  Map<String, String>? _solmateSprites;
  String? _animalName;
  bool _isLoading = true;
  ShareOption _currentShareOption = ShareOption.withBackground; // Default to with background

  @override
  void initState() {
    super.initState();
    _loadSolmateData();
  }

  Future<void> _loadSolmateData() async {
    try {
      final data = await _api.getSolmateData(widget.publicKey);
      if (data != null) {
        _animalName = data['animal'];
        if (_animalName != null) {
          final sprites = await SolmateApi.getSprites(_animalName!, widget.publicKey);
          setState(() {
            _solmateData = data;
            _solmateSprites = sprites;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  void _shareCard() async {
    ScreenshotController controllerToUse;
    if (_currentShareOption == ShareOption.spriteOnly) {
      controllerToUse = _spriteOnlyScreenshotController;
    } else {
      controllerToUse = _withBackgroundScreenshotController;
    }

    final image = await controllerToUse.capture();
    if (image == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = await File('${directory.path}/solmate_card.png').create();
    await imagePath.writeAsBytes(image);

    await Share.shareXFiles([XFile(imagePath.path)], text: 'Check out my Solmate!');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Share Solmate', style: TextStyle(fontSize: 16)),
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _currentShareOption = index == 0 ? ShareOption.spriteOnly : ShareOption.withBackground;
              });
            },
            tabs: const [
              Tab(text: 'Sprite Only'),
              Tab(text: 'Everything'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _solmateData == null
                ? const Center(child: Text('Could not load Solmate data.'))
                : Column(
                    children: [
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Sprite Only Tab
                            Center(
                              child: Screenshot(
                                controller: _spriteOnlyScreenshotController,
                                child: SolmateSpriteOnlyCard(
                                  solmateData: _solmateData!,
                                  solmateSprites: _solmateSprites,
                                  animalName: _animalName!,
                                ),
                              ),
                            ),
                            // With Background Tab
                            Center(
                              child: Screenshot(
                                controller: _withBackgroundScreenshotController,
                                child: SolmateCard(
                                  solmateData: _solmateData!,
                                  solmateSprites: _solmateSprites,
                                  animalName: _animalName!,
                                  showBackground: true,
                                  showDecorations: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: NesButton(
                          type: NesButtonType.primary,
                          onPressed: _shareCard,
                          child: Text(
                            'Share',
                            style: TextStyle(color: colorScheme.onPrimary, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class SolmateCard extends StatelessWidget {
  final Map<String, dynamic> solmateData;
  final Map<String, String>? solmateSprites;
  final String animalName;
  final bool showBackground;
  final bool showDecorations;

  const SolmateCard({
    super.key,
    required this.solmateData,
    this.solmateSprites,
    required this.animalName,
    this.showBackground = true,
    this.showDecorations = true,
  });

  @override
  Widget build(BuildContext context) {
    final String solmateName = solmateData['name'] ?? 'Solmate';
    final int level = solmateData['level'] ?? 1;
    final int foodFed = solmateData['food_fed'] ?? 0;
    final int petsGiven = solmateData['pets_given'] ?? 0;
    final int poosCleaned = solmateData['poos_cleaned'] ?? 0;
    final int runHighscore = solmateData['run_highscore'] ?? 0;
    final String? backgroundUrl = showBackground ? solmateData['selected_background'] : null;
    final List<DecorationAsset> decorations = showDecorations
        ? (solmateData['decorations'] as List<dynamic>?)
                ?.map((item) =>
                    DecorationAsset.fromJson(item as Map<String, dynamic>))
                .toList() ??
            []
        : [];
    final normalSpriteBytes = solmateSprites?['normal'] != null
        ? base64Decode(solmateSprites!['normal']!)
        : null;

    return Card(
      elevation: 4,
      color: Colors.indigo,
      child: Column(
        children: [
          Text(solmateName,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 10),
          Text('Level: $level',
              style: const TextStyle(fontSize: 18, color: Colors.white70)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double displaySize = min(constraints.maxWidth, constraints.maxHeight);
                  final double effectiveDisplaySize = max(250.0, displaySize); // Ensure a minimum of 250x250
                  final cellSize = effectiveDisplaySize / 3;

                  return SizedBox( // Wrap with SizedBox to enforce size
                    width: effectiveDisplaySize,
                    height: effectiveDisplaySize,
                    child: Stack(
                      children: [
                        // Background Layer
                        if (backgroundUrl != null)
                          Image.network('${dotenv.env['BACKEND_URL']!}$backgroundUrl',
                              width: effectiveDisplaySize,
                              height: effectiveDisplaySize,
                              fit: BoxFit.cover),

                        // Decorations layer
                        ...decorations.map((asset) {
                          if (asset.row == 2 && asset.col == 1) return const SizedBox.shrink();
                          return Positioned(
                            top: asset.row * cellSize,
                            left: asset.col * cellSize,
                            width: cellSize,
                            height: cellSize,
                            child: Center(
                              child: Image.network(
                                  '${dotenv.env['BACKEND_URL']!}${asset.url}',
                                  width: cellSize * 0.8, height: cellSize * 0.8),
                            ),
                          );
                        }).toList(),

                        // Solmate layer (always at [2][1])
                        Positioned(
                          top: 2 * cellSize,
                          left: 1 * cellSize,
                          width: cellSize,
                          height: cellSize,
                          child: Center(
                            child: Image.memory(
                              normalSpriteBytes!,
                              width: animalName == 'toly' ? cellSize * 1.5 : cellSize * 0.9,
                              height: animalName == 'toly' ? cellSize * 1.5 : cellSize * 0.9,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text("Run Highscore: $runHighscore", style: TextStyle(color: Colors.white)),
          Text("Poos Cleaned: $poosCleaned", style: TextStyle(color: Colors.white)),
          Text("Pets Given: $petsGiven", style: TextStyle(color: Colors.white)),
          Text("Food fed: $foodFed", style: TextStyle(color: Colors.white))
        ],
      ),
    );
  }
}

class SolmateSpriteOnlyCard extends StatelessWidget {
  final Map<String, dynamic> solmateData;
  final Map<String, String>? solmateSprites;
  final String animalName;

  const SolmateSpriteOnlyCard({
    super.key,
    required this.solmateData,
    this.solmateSprites,
    required this.animalName,
  });

  @override
  Widget build(BuildContext context) {
    final String solmateName = solmateData['name'] ?? 'Solmate';
    final int level = solmateData['level'] ?? 1;
    final int foodFed = solmateData['food_fed'] ?? 0;
    final int petsGiven = solmateData['pets_given'] ?? 0;
    final int poosCleaned = solmateData['poos_cleaned'] ?? 0;
    final int runHighscore = solmateData['run_highscore'] ?? 0;
    final normalSpriteBytes = solmateSprites?['normal'] != null
        ? base64Decode(solmateSprites!['normal']!)
        : null;

    return Card(
      elevation: 4,
      color: Colors.indigo,
      child: Column(
        children: [
          Text(solmateName,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 10),
          Text('Level: $level',
              style: const TextStyle(fontSize: 18, color: Colors.white70)),
          const SizedBox(height: 20),
          LayoutBuilder(
              builder: (context, constraints) {
                final double displaySize = min(constraints.maxWidth, constraints.maxHeight);
                final double effectiveDisplaySize = max(250.0, displaySize); // Ensure a minimum of 250x250

                return SizedBox(
                  width: effectiveDisplaySize,
                  height: effectiveDisplaySize,
                  child: Stack(
                    alignment: Alignment.center, // Center the sprite within the stack
                    children: [
                      // Solmate layer (much larger and higher)
                      Positioned(
                        top: effectiveDisplaySize * 0.1, // Adjust top position to be higher
                        child: Image.memory(
                          normalSpriteBytes!,
                          width: animalName == 'toly' ? effectiveDisplaySize * 0.8 : effectiveDisplaySize * 0.7, // Larger size
                          height: animalName == 'toly' ? effectiveDisplaySize * 0.8 : effectiveDisplaySize * 0.7, // Larger size
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
          Text("Run Highscore: $runHighscore", style: TextStyle(color: Colors.white),),
          Text("Poos Cleaned: $poosCleaned", style: TextStyle(color: Colors.white)),
          Text("Pets Given: $petsGiven", style: TextStyle(color: Colors.white)),
          Text("Food fed: $foodFed", style: TextStyle(color: Colors.white)),
          const SizedBox(height: 20,)
        ],
      ),
    );
  }
}
