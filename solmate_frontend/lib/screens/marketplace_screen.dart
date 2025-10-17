import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:solmate_frontend/api/background_api.dart';
import 'package:solmate_frontend/api/decor_api.dart';
import 'package:solmate_frontend/api/solmate_api.dart';
import 'package:solmate_frontend/models/background_asset.dart';
import 'package:solmate_frontend/models/decoration_asset.dart';

class MarketplaceResult {
  final List<DecorationAsset> decorations;
  final String? backgroundUrl;

  MarketplaceResult({required this.decorations, this.backgroundUrl});
}

class MarketplaceScreen extends StatefulWidget {
  final List<DecorationAsset> initialSelectedDecorations;
  final String? initialSelectedBackground;
  final int userLevel;
  final String pubkey;

  const MarketplaceScreen({
    super.key,
    required this.initialSelectedDecorations,
    required this.initialSelectedBackground,
    required this.userLevel,
    required this.pubkey,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final SolmateBackendApi _solmateApi = SolmateBackendApi();

  // Decoration State
  late List<DecorationAsset> _selectedDecorations;
  Map<String, List<DecorationAsset>> _availableDecorationsByPos = {};
  String? _selectedDecorationPositionKey;

  // Background State
  late String? _selectedBackgroundUrl;
  List<BackgroundAsset> _availableBackgrounds = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDecorations = List<DecorationAsset>.from(widget.initialSelectedDecorations);
    _selectedBackgroundUrl = widget.initialSelectedBackground;
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch both decorations and backgrounds in parallel
      final results = await Future.wait([
        DecorApi.getDecorations(),
        BackgroundApi.getBackgrounds(),
      ]);

      // Process Decorations
      final decorationsList = results[0];
      final Map<String, List<DecorationAsset>> processedDecorations = {};
      for (final item in decorationsList) {
        final asset = DecorationAsset.fromJson(item as Map<String, dynamic>);
        final key = '${asset.row}_${asset.col}';
        if (processedDecorations[key] == null) {
          processedDecorations[key] = [];
        }
        processedDecorations[key]!.add(asset);
      }

      // Process Backgrounds
      final backgroundsList = results[1];
      final List<BackgroundAsset> processedBackgrounds = backgroundsList
          .map((item) => BackgroundAsset.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _availableDecorationsByPos = processedDecorations;
        _availableBackgrounds = processedBackgrounds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load marketplace data: $e')),
      );
    }
  }

  void _onDecorationSelected(DecorationAsset? assetToSelect, int row, int col) {
    setState(() {
      _selectedDecorations.removeWhere((asset) => asset.row == row && asset.col == col);
      if (assetToSelect != null) {
        _selectedDecorations.add(assetToSelect);
      }
    });
  }

  void _onBackgroundSelected(BackgroundAsset background) {
    setState(() {
      _selectedBackgroundUrl = background.url;
    });
  }

  Future<void> _saveAndClose() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Save decorations and background in parallel
      await Future.wait([
        _solmateApi.saveDecorations(widget.pubkey, _selectedDecorations),
        if (_selectedBackgroundUrl != null)
          _solmateApi.saveSelectedBackground(widget.pubkey, _selectedBackgroundUrl!),
      ]);

      if (mounted) {
        Navigator.pop(
          context,
          MarketplaceResult(
            decorations: _selectedDecorations,
            backgroundUrl: _selectedBackgroundUrl,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save changes: $e')),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: _isLoading
              ? const Center(child: Text("Loading..."))
              : Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Decorations'),
                        Tab(text: 'Backgrounds'),
                      ],
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          TabBarView(
                            children: [
                              _buildDecorationsTab(),
                              _buildBackgroundsTab(),
                            ],
                          ),
                          if (_isSaving)
                            Container(
                              color: Colors.black.withOpacity(0.5),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Saving...', style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: NesButton(
                        type: NesButtonType.primary,
                        onPressed: _isSaving ? null : _saveAndClose,
                        child: const Text('Save & Close'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _getPositionName(String? key) {
    if (key == null) return "";
    final parts = key.split('_');
    final row = int.parse(parts[0]);
    final col = int.parse(parts[1]);

    const rowNames = ['Top', 'Middle', 'Bottom'];
    const colNames = ['Left', 'Center', 'Right'];

    return "${rowNames[row]} ${colNames[col]}";
  }

  Widget _buildDecorationSelector() {
    if (_selectedDecorationPositionKey == null) {
      return const Spacer();
    }

    final assetsForSlot = _availableDecorationsByPos[_selectedDecorationPositionKey!] ?? [];
    final positionName = _getPositionName(_selectedDecorationPositionKey);

    DecorationAsset? currentAssetInSlot;
    try {
      final parts = _selectedDecorationPositionKey!.split('_');
      final row = int.parse(parts[0]);
      final col = int.parse(parts[1]);
      currentAssetInSlot = _selectedDecorations.firstWhere((asset) => asset.row == row && asset.col == col);
    } catch (e) {
      currentAssetInSlot = null;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: NesContainer(
          width: double.infinity,
          label: '$positionName',
          child: ListView.builder(
            itemCount: assetsForSlot.length + 1,
            itemBuilder: (context, index) {
              // 'None' option
              if (index == 0) {
                final bool isSelected = currentAssetInSlot == null;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: InkWell(
                    onTap: () => _onDecorationSelected(null, int.parse(_selectedDecorationPositionKey!.split('_')[0]), int.parse(_selectedDecorationPositionKey!.split('_')[1])),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      color: isSelected ? Colors.green.withOpacity(0.3) : Colors.transparent,
                      child: const Row(
                        children: [
                          Text('None'),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final asset = assetsForSlot[index - 1];
              final bool isSelected = currentAssetInSlot?.url == asset.url;
              
              bool isLocked = false;
              String lockText = "";
              if (asset.unlock != null) {
                if (asset.unlock!.type == 'level') {
                  if (widget.userLevel < asset.unlock!.value) {
                    isLocked = true;
                    lockText = "Lvl ${asset.unlock!.value}";
                  }
                } else if (asset.unlock!.type == 'paid') {
                  isLocked = true;
                  lockText = "\$${asset.unlock!.value}";
                }
              }

              return Opacity(
                opacity: isLocked ? 0.5 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: InkWell(
                    onTap: isLocked ? null : () => _onDecorationSelected(asset, asset.row, asset.col),
                    child: NesContainer(
                      padding: const EdgeInsets.all(8.0),
                      backgroundColor: isSelected ? Colors.green.withOpacity(0.3) : Colors.transparent,
                      child: Row(
                        children: [
                          Text(asset.name),
                          const Spacer(),
                          if (isLocked) ...[
                            Text(lockText, style: const TextStyle(color: Colors.red)),
                            const SizedBox(width: 8),
                            const Icon(Icons.lock, color: Colors.red, size: 20),
                          ] else
                            Image.network(
                              'http://10.0.2.2:3000${asset.url}',
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, st) => const Icon(Icons.error),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDecorationsTab() {
    final selectedMap = HashMap<String, DecorationAsset>();
    for (var asset in _selectedDecorations) {
      selectedMap['${asset.row}_${asset.col}'] = asset;
    }
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: NesContainer(
            padding: const EdgeInsets.all(16.0),
            label: "ACCESSORIES",
            backgroundColor: colorScheme.surface,
            painterBuilder: NesContainerSquareCornerPainter.new,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellSize = constraints.maxWidth / 3;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (row) {
                    return Row(
                      children: List.generate(3, (col) {
                        final selectedAsset = selectedMap['${row}_${col}'];
                        final isSelectedCell = _selectedDecorationPositionKey == '${row}_${col}';
                        return GestureDetector(
                          onTap: () {
                            if (row == 2 && col == 1) return;
                            setState(() {
                              _selectedDecorationPositionKey = '${row}_${col}';
                            });
                          },
                          child: Container(
                            width: cellSize,
                            height: cellSize,
                            decoration: BoxDecoration(
                              color: isSelectedCell ? colorScheme.primaryContainer : colorScheme.surfaceVariant,
                              border: Border.all(color: Colors.black, width: isSelectedCell ? 3 : 1),
                            ),
                            child: (row == 2 && col == 1)
                                ? Center(child: Text('SOLMATE', style: TextStyle(color: colorScheme.onSurface)))
                                : selectedAsset != null
                                    ? Image.network(
                                        'http://10.0.2.2:3000${selectedAsset.url}',
                                        fit: BoxFit.contain,
                                        errorBuilder: (ctx, err, st) => const Icon(Icons.error, color: Colors.red),
                                      )
                                    : null,
                          ),
                        );
                      }),
                    );
                  }),
                );
              },
            ),
          ),
        ),
        _buildDecorationSelector(),
      ],
    );
  }

  Widget _buildBackgroundsTab() {
    return ListView.builder(
      itemCount: _availableBackgrounds.length,
      itemBuilder: (context, index) {
        final background = _availableBackgrounds[index];
        final isSelected = _selectedBackgroundUrl == background.url;

        bool isLocked = false;
        String lockText = "";
        if (background.unlock != null) {
          if (background.unlock!.type == 'level') {
            if (widget.userLevel < background.unlock!.value) {
              isLocked = true;
              lockText = "Lvl ${background.unlock!.value}";
            }
          }
        }

        return Opacity(
          opacity: isLocked ? 0.5 : 1.0,
          child: InkWell(
            onTap: isLocked ? null : () => _onBackgroundSelected(background),
            child: Container(
              margin: const EdgeInsets.all(8.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green.withOpacity(0.3) : Colors.transparent,
                border: Border.all(color: Colors.black),
              ),
              child: Row(
                children: [
                  Image.network(
                    'http://10.0.2.2:3000${background.url}',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 16),
                  Text(background.name, style: const TextStyle(fontSize: 18)),
                  const Spacer(),
                  if (isLocked)
                    Row(children: [
                      Text(lockText, style: const TextStyle(color: Colors.red)),
                      const SizedBox(width: 8),
                      const Icon(Icons.lock, color: Colors.red, size: 20),
                    ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
