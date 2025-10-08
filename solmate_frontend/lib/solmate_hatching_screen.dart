import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart'; // Added nes_ui import
import 'package:solmate_frontend/solmate_data.dart';
import 'package:solmate_frontend/solmate_screen.dart';

class SolmateHatchingScreen extends StatefulWidget {
  final SolmateAnimal solmateAnimal;
  final String publicKey;

  const SolmateHatchingScreen({
    super.key,
    required this.solmateAnimal,
    required this.publicKey,
  });

  @override
  State<SolmateHatchingScreen> createState() => _SolmateHatchingScreenState();
}

class _SolmateHatchingScreenState extends State<SolmateHatchingScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isHatched = false;

  @override
  void initState() {
    super.initState();
    // Trigger the hatching animation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isHatched = true;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _confirmName() {
    final String solmateName = _nameController.text.trim();
    if (solmateName.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SolmateScreen(
            solmateAnimal: widget.solmateAnimal,
            publicKey: widget.publicKey,
            solmateName: solmateName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: NesRunningText(text: "Please Give your Solmate a name!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background, // Use background color from theme
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Your Solmate is hatching!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                AnimatedOpacity(
                  opacity: _isHatched ? 1.0 : 0.0,
                  duration: const Duration(seconds: 1),
                  child: AnimatedScale(
                    scale: _isHatched ? 1.0 : 0.5,
                    duration: const Duration(seconds: 1),
                    child: NesContainer(
                      padding: const EdgeInsets.all(16.0),
                      backgroundColor: colorScheme.surface, // Use surface color
                      child: Image.network(
                        widget.solmateAnimal.imageUrl,
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        errorBuilder: (context, error, stackTrace) => NesContainer(
                          width: 150,
                          height: 150,
                          backgroundColor: colorScheme.background, // Use background color for error placeholder
                          child: Icon(Icons.pets, size: 80, color: colorScheme.onBackground.withOpacity(0.5)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (_isHatched)
                  Column(
                    children: [
                      Text(
                        'Give your Solmate a name:',
                        style: TextStyle(
                          fontSize: 14,

                          color: colorScheme.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 200,
                        // child: NesRunningText(text: "Enter Name"),
                        child: TextField( 
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          onSubmitted: (_) => _confirmName(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      NesButton(
                        type: NesButtonType.primary,
                        onPressed: _confirmName,
                        child: Text('Confirm Name', style: TextStyle(color: colorScheme.onPrimary)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}