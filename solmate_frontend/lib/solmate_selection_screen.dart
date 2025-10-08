import 'package:flutter/material.dart';
import 'dart:math';
import 'package:nes_ui/nes_ui.dart'; // Added nes_ui import
import 'package:solmate_frontend/solmate_data.dart';
import 'package:solmate_frontend/solmate_hatching_screen.dart';

class SolmateSelectionScreen extends StatefulWidget {
  const SolmateSelectionScreen({super.key});

  @override
  State<SolmateSelectionScreen> createState() => _SolmateSelectionScreenState();
}

class _SolmateSelectionScreenState extends State<SolmateSelectionScreen> {
  List<SolmateAnimal> _availableChoices = [];
  String? _selectedPublicKey;

  final List<String> _mockPublicKeys = [
    "0x1A2b3C4d5E6f7A8b9C0d1E2f3A4b5C6d7E8f9A0b",
    "0x9F8e7D6c5B4a3F2e1D0c9B8a7F6e5D4c3B2a1F0e",
    "0xABCDEF1234567890ABCDEF1234567890ABCDEF12",
  ];

  @override
  void initState() {
    super.initState();
    _generateRandomChoices();
    _selectRandomPublicKey();
  }

  void _generateRandomChoices() {
    final random = Random();
    final List<SolmateAnimal> allAnimals = List.from(solmateAnimals);
    allAnimals.shuffle(random);
    _availableChoices = allAnimals.take(3).toList();
  }

  void _selectRandomPublicKey() {
    final random = Random();
    _selectedPublicKey = _mockPublicKeys[random.nextInt(_mockPublicKeys.length)];
  }

  Future<void> _onSolmateSelected(SolmateAnimal selectedSolmate) async {
    if (_selectedPublicKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Public key not selected.',
          style: TextStyle(color: Theme.of(context).colorScheme.onError))),
      );
      return;
    }

    // Show the NES confirm dialog
    final confirmed = await NesConfirmDialog.show(context: context);

    if (confirmed != true) return;

    // Proceed only after confirm
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SolmateHatchingScreen(
          solmateAnimal: selectedSolmate,
          publicKey: _selectedPublicKey!,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.background,
                colorScheme.surface,
              ],
            ),
          ),
          child: _availableChoices.isEmpty
              ? Center(child: NesProgressBar(value: 0.5)) // Using NesPixelatedProgressBar
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NesRunningText(
                        text: 'Select your Solmate:',
        
                       
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            childAspectRatio: 1.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _availableChoices.length,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final solmate = _availableChoices[index];
                            return SolmateChoiceCard(
                              solmate: solmate,
                              onTap: () => _onSolmateSelected(solmate),
                            );
                          },
                        ),
                      ),
                      
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class SolmateChoiceCard extends StatelessWidget {
  final SolmateAnimal solmate;
  final VoidCallback onTap;

  const SolmateChoiceCard({super.key, required this.solmate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: NesContainer(
        backgroundColor: colorScheme.surface,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              solmate.imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => NesContainer(
                width: 100,
                height: 100,
                backgroundColor: colorScheme.background, // Use background color for error placeholder
                child: Icon(Icons.pets, size: 50, color: colorScheme.onBackground.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 10),
                        Text(
              solmate.name.toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface, // Use onSurface color for text
              ),
            ),
          ],
        ),
      ),
    );
  }
}