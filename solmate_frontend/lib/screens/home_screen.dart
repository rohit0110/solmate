import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:solana_mobile_client/solana_mobile_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bs58/bs58.dart';
import 'package:solmate_frontend/api/solmate_api.dart';
import 'package:solmate_frontend/api/sprite_api.dart';
import 'package:solmate_frontend/screens/solmate_screen.dart';

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

    LocalAssociationScenario? session;
    try {
      session = await LocalAssociationScenario.create();
      session.startActivityForResult(null).ignore();
      final client = await session.start();
      final result = await client.authorize(
        identityUri: Uri.parse(dotenv.env['APP_IDENTITY_URI']!),
        identityName: dotenv.env['APP_IDENTITY_NAME']!,
        cluster: dotenv.env['SOLANA_CLUSTER']!,
      );

      final pubkeyString = base58.encode(result!.publicKey);
      final solmateData = await _api.getSolmateData(pubkeyString);

      if (solmateData != null) {
        final spriteData = await SolmateApi.getSprites(solmateData['animal'], pubkeyString);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SolmateScreen(
              animalName: solmateData['animal'],
              publicKey: pubkeyString,
              solmateName: solmateData['name'],
              solmateSprites: spriteData,
            ),
          ),
        );
      } else {
        Navigator.pushNamed(context, '/solmateSelection', arguments: pubkeyString);
      }
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error connecting to wallet: $e')),
        );
      }
    } finally {
      if (session != null) {
        await session.close();
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: NesContainer(
          padding: const EdgeInsets.all(24.0),
          backgroundColor: colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const Text("Connecting...")
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

