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
  // To store all available decorations fetched from the API, grouped by position
  Map<String, List<DecorationAsset>> _availableDecorationsByPos = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Deep copy the initial list
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

  void _showAssetSelectionDialog(int row, int col) {
    if (row == 2 && col == 1) return; // Cannot toggle solmate's spot

    final key = '${row}_${col}';
    final assetsForSlot = _availableDecorationsByPos[key] ?? [];

    // Find the currently selected asset for this slot, if any
    DecorationAsset? currentAssetInSlot;
    try {
      currentAssetInSlot = _selectedDecorations.firstWhere((asset) => asset.row == row && asset.col == col);
    } catch (e) {
      currentAssetInSlot = null; // Not found
    }

    showDialog(
      context: context,
      builder: (context) {
        DecorationAsset? selectedAssetInDialog = currentAssetInSlot;

        return AlertDialog(
          title: const Text('Select Decoration'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: assetsForSlot.length + 1, // +1 for 'None' option
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return RadioListTile<DecorationAsset?>(
                        title: const Text('None'),
                        value: null,
                        groupValue: selectedAssetInDialog,
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedAssetInDialog = value;
                          });
                        },
                      );
                    }

                    final asset = assetsForSlot[index - 1];
                    return RadioListTile<DecorationAsset?>(
                      title: Text(asset.name),
                      secondary: Image.network(
                        'http://10.0.2.2:3000${asset.url}',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, st) => const Icon(Icons.error),
                      ),
                      value: asset,
                      groupValue: selectedAssetInDialog,
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedAssetInDialog = value;
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // Remove any existing decoration at this position
                  _selectedDecorations.removeWhere((asset) => asset.row == row && asset.col == col);
                  // Add the new one if one was selected
                  if (selectedAssetInDialog != null) {
                    _selectedDecorations.add(selectedAssetInDialog!);
                  }
                });
                Navigator.of(context).pop();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Create a map of selected decorations for quick lookup
    final selectedMap = HashMap<String, DecorationAsset>();
    for (var asset in _selectedDecorations) {
      selectedMap['${asset.row}_${asset.col}'] = asset;
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Text("Loading..."),
              )
            : Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
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
                                children: List.generate(3, (row) {
                                  return Row(
                                    children: List.generate(3, (col) {
                                      final selectedAsset = selectedMap['${row}_${col}'];
                                      return GestureDetector(
                                        onTap: () => _showAssetSelectionDialog(row, col),
                                        child: Container(
                                          width: cellSize,
                                          height: cellSize,
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceVariant,
                                            border: Border.all(color: Colors.black, width: 1),
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
                    ),
                  ),
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
