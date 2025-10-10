import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

class MarketplaceScreen extends StatefulWidget {
  final List<List<bool>> initialAccessoryGrid;

  const MarketplaceScreen({
    super.key,
    required this.initialAccessoryGrid,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late List<List<bool>> _accessoryGrid;

  @override
  void initState() {
    super.initState();
    _accessoryGrid = List.generate(
      widget.initialAccessoryGrid.length,
      (i) => List.from(widget.initialAccessoryGrid[i]),
    );
  }

  void _toggleAccessory(int row, int col) {
    if (row == 2 && col == 1) return; // Cannot toggle solmate's spot
    setState(() {
      _accessoryGrid[row][col] = !_accessoryGrid[row][col];
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
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
                                return GestureDetector(
                                  onTap: () => _toggleAccessory(row, col),
                                  child: Container(
                                    width: cellSize,
                                    height: cellSize,
                                    decoration: BoxDecoration(
                                      color: _accessoryGrid[row][col]
                                          ? Colors.blue.withOpacity(0.5) // Highlight if active
                                          : colorScheme.surfaceVariant, // Default cell color
                                      border: Border.all(color: Colors.black, width: 1),
                                    ),
                                    child: (row == 2 && col == 1)
                                        ? Center(child: Text('SOLMATE', style: TextStyle(color: colorScheme.onSurface)))
                                        : (_accessoryGrid[row][col]
                                            ? Center(child: Icon(Icons.star, color: Colors.yellow)) // Placeholder for accessory sprite
                                            : null),
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
