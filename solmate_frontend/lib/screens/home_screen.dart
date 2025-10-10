import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:solmate_frontend/api/solmate_api.dart';
import 'package:solmate_frontend/api/sprite_api.dart';
import 'package:solmate_frontend/screens/solmate_screen.dart';
import 'package:solmate_frontend/screens/solmate_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SolmateBackendApi _api = SolmateBackendApi();
  bool _isLoading = false;

  Future<void> _connectWallet() async {
    setState(() {
      _isLoading = true;
    });

    // MOCK: In a real app, you would use a wallet adapter to get the public key.
    const pubkey = '7WKaHxMy54Mn5JPpETqiwwkcyJLmkcsrjwfvUnDqPpdN'; 
    
    try {
      final solmateData = await _api.getSolmateData(pubkey);

      if (solmateData != null) {
        // User exists, fetch sprites then navigate to SolmateScreen
        // The backend doesn't return the animal type, so we'll need to decide what to do here.
        // For now, let's default to dragon.
        final animal = SolmateAnimal(name: "Dragon", normalSpritePath: "assets/sprites/dragon_normal.png", happySpritePath: "assets/sprites/dragon_happy.png");
        final spriteData = await SolmateApi.getSprites(animal.name, pubkey);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SolmateScreen(
              solmateAnimal: animal,
              publicKey: pubkey,
              solmateName: solmateData['name'],
              solmateSprites: spriteData,
            ),
          ),
        );
      } else {
        // User not found, navigate to the creation flow
        Navigator.pushNamed(context, '/solmateSelection', arguments: pubkey);
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background, // Use theme background
      body: Center(
        child: NesContainer(
          padding: const EdgeInsets.all(24.0),
          backgroundColor: colorScheme.surface, // Use theme surface for container
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const Text("Loading...")
              else
                NesButton(
                  type: NesButtonType.primary,
                  onPressed: _connectWallet,
                  child: Text(
                    'Connect Wallet',
                    style: TextStyle(color: colorScheme.onPrimary, fontSize: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
