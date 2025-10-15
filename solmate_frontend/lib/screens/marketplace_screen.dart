import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:solmate_frontend/api/decor_api.dart';

// Data model for a decoration asset
class DecorationAsset {
  final String name;
  final String url;

  DecorationAsset({required this.name, required this.url});

  // Factory constructor to create an instance from a JSON map
  factory DecorationAsset.fromJson(Map<String, dynamic> json) {
    return DecorationAsset(
      name: json['name'] as String,
      url: json['url'] as String,
    );
  }
}

class MarketplaceScreen extends StatefulWidget {
  final List<List<DecorationAsset?>> initialAccessoryGrid;

  const MarketplaceScreen({
    super.key,
    required this.initialAccessoryGrid,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late List<List<DecorationAsset?>> _accessoryGrid;
  // To store all available decorations fetched from the API
  Map<String, List<DecorationAsset>> _availableDecorations = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Deep copy the initial grid
    _accessoryGrid = widget.initialAccessoryGrid.map((row) => List<DecorationAsset?>.from(row)).toList();
    _fetchDecorations();
  }

  Future<void> _fetchDecorations() async {
    try {
      final decorationsList = await DecorApi.getDecorations();
      final Map<String, List<DecorationAsset>> processedDecorations = {};

      for (final item in decorationsList) {
        final decoration = item as Map<String, dynamic>;
        final row = decoration['row'] as int;
        final col = decoration['col'] as int;
        final key = '${row}_${col}';

        final asset = DecorationAsset.fromJson(decoration);

        if (processedDecorations[key] == null) {
          processedDecorations[key] = [];
        }
        processedDecorations[key]!.add(asset);
      }

      setState(() {
        _availableDecorations = processedDecorations;
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
    final assetsForSlot = _availableDecorations[key] ?? [];

    showDialog(
      context: context,
      builder: (context) {
        DecorationAsset? selectedAssetInDialog = _accessoryGrid[row][col];

        return AlertDialog(
          title: Text('Select Decoration'),
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
                        'http://10.0.2.2:3000${asset.url}', // Assuming base URL
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
                  _accessoryGrid[row][col] = selectedAssetInDialog;
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
                                      final selectedAsset = _accessoryGrid[row][col];
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
                        Navigator.pop(context, _accessoryGrid);
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
