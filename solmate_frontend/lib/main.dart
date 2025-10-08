import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:solmate_frontend/home_screen.dart';
import 'package:solmate_frontend/solmate_selection_screen.dart';
// SolmateScreen is now pushed with arguments, no longer a direct named route
// import 'package:solmate_frontend/solmate_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
  
    final theme = flutterNesTheme();

    return MaterialApp(
      title: 'Solmate App',
      theme: theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/solmateSelection': (context) => const SolmateSelectionScreen(),
      },
    );
  }
}
