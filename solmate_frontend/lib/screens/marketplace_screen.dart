import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:solmate_frontend/api/decor_api.dart';
import 'package:solmate_frontend/models/decoration_asset.dart';

class MarketplaceScreen extends StatefulWidget {
  final List<DecorationAsset> initialSelectedDecorations;

  const MarketplaceScreen({
    super.key,
    required this.initialSelectedDecorations,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late List<DecorationAsset> _selectedDecorations;
  Map<String, List<DecorationAsset>> _availableDecorationsByPos = {};
  bool _isLoading = true;
  String? _selectedPositionKey;

  @override
  void initState() {
    super.initState();
    _selectedDecorations = List<DecorationAsset>.from(widget.initialSelectedDecorations);
    _fetchDecorations();
  }

  Future<void> _fetchDecorations() async {
    try {
      final decorationsList = await DecorApi.getDecorations();
      final Map<String, List<DecorationAsset>> processedDecorations = {};

      for (final item in decorationsList) {
        final asset = DecorationAsset.fromJson(item as Map<String, dynamic>);
        final key = '${asset.row}_${asset.col}';

        if (processedDecorations[key] == null) {
          processedDecorations[key] = [];
        }
        processedDecorations[key]!.add(asset);
      }

      setState(() {
        _availableDecorationsByPos = processedDecorations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load decorations: $e')),
      );
    }
  }

  void _onDecorationSelected(DecorationAsset? assetToSelect, int row, int col) {
    setState(() {
      // Remove any existing decoration at this position
      _selectedDecorations.removeWhere((asset) => asset.row == row && asset.col == col);
      // Add the new one if one was selected
      if (assetToSelect != null) {
        _selectedDecorations.add(assetToSelect);
      }
    });
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
    if (_selectedPositionKey == null) {
      return const Spacer();
    }

    final assetsForSlot = _availableDecorationsByPos[_selectedPositionKey!] ?? [];
    final positionName = _getPositionName(_selectedPositionKey);

    DecorationAsset? currentAssetInSlot;
    try {
      final parts = _selectedPositionKey!.split('_');
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
              if (index == 0) {
                // 'None' option
                final bool isSelected = currentAssetInSlot == null;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: InkWell(
                    onTap: () => _onDecorationSelected(null, int.parse(_selectedPositionKey!.split('_')[0]), int.parse(_selectedPositionKey!.split('_')[1])),
                    child: NesContainer(
                      padding: const EdgeInsets.all(12.0),
                      backgroundColor: isSelected ? Colors.green.withOpacity(0.3) : Colors.transparent,
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

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: InkWell(
                  onTap: () => _onDecorationSelected(asset, asset.row, asset.col),
                  child: NesContainer(
                    padding: const EdgeInsets.all(8.0),
                    backgroundColor: isSelected ? Colors.green.withOpacity(0.3) : Colors.transparent,
                    child: Row(
                      children: [
                        Text(asset.name),
                        const Spacer(),
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
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final selectedMap = HashMap<String, DecorationAsset>();
    for (var asset in _selectedDecorations) {
      selectedMap['${asset.row}_${asset.col}'] = asset;
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: Text("Loading..."))
            : Column(
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
                                  final isSelectedCell = _selectedPositionKey == '${row}_${col}';
                                  return GestureDetector(
                                    onTap: () {
                                      if (row == 2 && col == 1) return;
                                      setState(() {
                                        _selectedPositionKey = '${row}_${col}';
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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: NesButton(
                      type: NesButtonType.primary,
                      onPressed: () {
                        Navigator.pop(context, _selectedDecorations);
                      },
                      child: const Text('Save & Close'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
