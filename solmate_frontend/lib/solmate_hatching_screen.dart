import 'package:flutter/material.dart';
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
        const SnackBar(content: Text('Please give your Solmate a name!')),
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
                    fontFamily: 'PressStart2P', // Placeholder for custom 8-bit font
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onBackground, // Use onBackground color
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
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: colorScheme.surface, // Use surface color
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: colorScheme.primary, width: 4.0), // Use primary color for border
                      ),
                      child: Image.network(
                        widget.solmateAnimal.imageUrl,
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 150,
                          height: 150,
                          color: colorScheme.background, // Use background color for error placeholder
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
                          fontFamily: 'PressStart2P',
                          fontSize: 14,
                          color: colorScheme.onBackground, // Use onBackground color
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 200,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary, // Use onPrimary for text field background
                          borderRadius: BorderRadius.circular(5.0),
                          border: Border.all(color: colorScheme.primary, width: 2.0),
                        ),
                        child: TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 16,
                            color: colorScheme.onSurface, // Use onSurface for text color
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter Name',
                            hintStyle: TextStyle(
                              fontFamily: 'PressStart2P',
                              fontSize: 16,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _confirmName(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _confirmName,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary, // Use primary color
                          foregroundColor: colorScheme.onPrimary, // Use onPrimary color
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 16,
                          ),
                        ),
                        child: const Text('Confirm Name'),
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