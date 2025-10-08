import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              NesButton(
                type: NesButtonType.primary,
                onPressed: () {
                  Navigator.pushNamed(context, '/solmateSelection');
                },
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
