import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:solmate_frontend/solmate_data.dart';

class SolmateScreen extends StatefulWidget {
  final SolmateAnimal solmateAnimal;
  final String publicKey;

  const SolmateScreen({super.key, required this.solmateAnimal, required this.publicKey});

  @override
  State<SolmateScreen> createState() => _SolmateScreenState();
}

class _SolmateScreenState extends State<SolmateScreen> {
  late String _solmateName;
  int _health = 100;
  int _happiness = 100;
  late String _pokemonImageUrl;

  @override
  void initState() {
    super.initState();
    _solmateName = widget.solmateAnimal.name;
    _pokemonImageUrl = widget.solmateAnimal.imageUrl;
    _saveSolmateData();
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
        title: Text('Your ${_solmateName.toUpperCase()}', style: const TextStyle(color: Colors.white)),
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
                _buildSolmateCard(),
                const SizedBox(height: 20),
                Text(
                  '''Linked Wallet: 
${widget.publicKey}''',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
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
              _pokemonImageUrl,
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
