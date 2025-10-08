import 'package:flutter/material.dart';
import 'package:solmate_frontend/home_screen.dart';
import 'package:solmate_frontend/solmate_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solmate App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/solmate': (context) => const SolmateScreen(),
      },
    );
  }
}
