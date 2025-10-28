
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

class ShareScreen extends StatefulWidget {
  final String publicKey;

  const ShareScreen({super.key, required this.publicKey});

  @override
  _ShareScreenState createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final SolmateBackendApi _api = SolmateBackendApi();
  final ScreenshotController _screenshotController = ScreenshotController();
  Map<String, dynamic>? _solmateData;
  Map<String, String>? _solmateSprites;
  String? _animalName;
  bool _isLoading = true;

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
    final image = await _screenshotController.capture();
    if (image == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = await File('${directory.path}/solmate_card.png').create();
    await imagePath.writeAsBytes(image);

    await Share.shareXFiles([XFile(imagePath.path)], text: 'Check out my Solmate!');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Solmate', style: TextStyle(fontSize: 16)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _solmateData == null
              ? const Center(child: Text('Could not load Solmate data.'))
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Screenshot(
                        controller: _screenshotController,
                        child: SolmateCard(
                          solmateData: _solmateData!,
                          solmateSprites: _solmateSprites,
                          animalName: _animalName!,
                        ),
                      ),
                      const SizedBox(height: 20),
                      NesButton(
                        type: NesButtonType.primary,
                        onPressed: _shareCard,
                        child: Text(
                          'Share',
                          style: TextStyle(color: colorScheme.onPrimary, fontSize: 16),
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

  const SolmateCard({super.key, required this.solmateData, this.solmateSprites, required this.animalName});

  @override
  Widget build(BuildContext context) {
    final String solmateName = solmateData['name'] ?? 'Solmate';
    final int level = solmateData['level'] ?? 1;
    final String? backgroundUrl = solmateData['selected_background'];
    final List<DecorationAsset> decorations =
        (solmateData['decorations'] as List<dynamic>?)
                ?.map((item) =>
                    DecorationAsset.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [];
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
                  final gridDisplaySize = min(constraints.maxWidth, constraints.maxHeight);
                  final cellSize = gridDisplaySize / 3;

                  return Stack(
                    children: [
                      // Background Layer
                      if (backgroundUrl != null)
                        Image.network('http://10.0.2.2:3000$backgroundUrl',
                            width: gridDisplaySize,
                            height: gridDisplaySize,
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
                                'http://10.0.2.2:3000${asset.url}',
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
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
