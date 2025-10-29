import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:solmate_frontend/screens/home_screen.dart';
import 'package:solmate_frontend/screens/solmate_selection_screen.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
  
    final theme = flutterNesTheme(nesSnackbarTheme: NesSnackbarTheme(normal: Color(0xffe76e55), success: Color(0xff92cc41), warning: Color(0xfff7d51d), error: Color(0xffe76e55)));

    return MaterialApp(
      title: 'Solmate App',
      theme: theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/solmateSelection': (context) => const SolmateSelectionScreen()
      },
    );
  }
}
