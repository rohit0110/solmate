import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:home_widget/home_widget.dart';

class SolmateScreen extends StatefulWidget {
  const SolmateScreen({super.key});

  @override
  State<SolmateScreen> createState() => _SolmateScreenState();
}

class _SolmateScreenState extends State<SolmateScreen> {
  String _solmateName = "Solmate";
  int _health = 100;
  int _happiness = 100;
  String? _pokemonImageUrl;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRandomPokemon();
  }

  Future<void> _fetchRandomPokemon() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final random = Random();
      final pokemonId = random.nextInt(898) + 1; // There are 898 Pokémon as of Gen 8
      final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$pokemonId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _pokemonImageUrl = data['sprites']['front_default'];
          _solmateName = data['name'];
          _isLoading = false;
        });
        _saveSolmateData();
      } else {
        setState(() {
          _errorMessage = 'Failed to load Pokémon: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching Pokémon: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSolmateData() async {
    await HomeWidget.saveWidgetData<String>('solmateName', _solmateName);
    await HomeWidget.saveWidgetData<int>('solmateHealth', _health);
    await HomeWidget.saveWidgetData<int>('solmateHappiness', _happiness);
    await HomeWidget.saveWidgetData<String>('solmateImageUrl', _pokemonImageUrl);
    await HomeWidget.updateWidget(name: 'SolmateWidget');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Solmate', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF121212), // Very Dark Grey/Black
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // For back button
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF121212), // Very Dark Grey/Black
              Color(0xFF1E003C), // Dark Purple
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const CircularProgressIndicator(color: Color(0xFFBB86FC)) // Light Purple
                else if (_errorMessage != null)
                  Text(
                    'Error: $_errorMessage',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                  )
                else if (_pokemonImageUrl != null)
                  _buildSolmateCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolmateCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Slightly lighter dark grey for card
        borderRadius: BorderRadius.circular(25.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 3,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: Image.network(
              _pokemonImageUrl!,
              width: 180,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 180,
                height: 180,
                color: const Color(0xFF2C2C2C),
                child: const Icon(Icons.pets, size: 80, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            _solmateName.toUpperCase(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          _buildStatRow('Health', _health, Colors.green.shade400, Icons.favorite),
          _buildStatRow('Happiness', _happiness, Colors.amber.shade400, Icons.sentiment_satisfied_alt),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 19,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
