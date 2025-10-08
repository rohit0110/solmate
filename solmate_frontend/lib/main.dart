import 'package:flutter/material.dart';
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
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFF1F6FEB),
      onPrimary: Colors.white,
      secondary: const Color(0xFF6A5BFF),
      onSecondary: Colors.white,
      surface: const Color(0xFF1A1C2C),
      onSurface: Colors.white,
      background: const Color(0xFF0B0D17),
      onBackground: Colors.white,
      error: const Color(0xFFE94B4B),
      onError: Colors.white,
      tertiary: const Color(0xFFFF4D9D), // accent
      onTertiary: Colors.white,
    );
    final theme = ThemeData(colorScheme: colorScheme, useMaterial3: true);

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
