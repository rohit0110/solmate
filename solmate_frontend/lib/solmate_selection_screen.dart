import 'package:flutter/material.dart';
import 'dart:math';
import 'package:solmate_frontend/solmate_data.dart';
import 'package:solmate_frontend/solmate_hatching_screen.dart'; // Added import
// import 'package:solmate_frontend/solmate_screen.dart'; // No longer directly navigating to SolmateScreen

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

  void _onSolmateSelected(SolmateAnimal selectedSolmate) {
    if (_selectedPublicKey != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SolmateHatchingScreen(
            solmateAnimal: selectedSolmate,
            publicKey: _selectedPublicKey!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Public key not selected.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Your Solmate', style: TextStyle(color: colorScheme.onBackground)),
        backgroundColor: colorScheme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
      ),
      body: Container(
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
            ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Select your Solmate:',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onBackground),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _availableChoices.length,
                        itemBuilder: (context, index) {
                          final solmate = _availableChoices[index];
                          return SolmateChoiceCard(
                            solmate: solmate,
                            onTap: () => _onSolmateSelected(solmate),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '''Simulated Public Key: 
${_selectedPublicKey}''',
                      style: TextStyle(fontSize: 14, color: colorScheme.onBackground.withOpacity(0.7)),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface, // Use surface color for card background
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              solmate.imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 100,
                height: 100,
                color: colorScheme.background, // Use background color for error placeholder
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