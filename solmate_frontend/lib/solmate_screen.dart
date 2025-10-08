import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:solmate_frontend/solmate_data.dart';

class SolmateScreen extends StatefulWidget {
  final SolmateAnimal solmateAnimal;
  final String publicKey;
  final String solmateName;

  const SolmateScreen({super.key, required this.solmateAnimal, required this.publicKey, required this.solmateName});

  @override
  State<SolmateScreen> createState() => _SolmateScreenState();
}

class _SolmateScreenState extends State<SolmateScreen> {
  late String _solmateNameDisplay;
  int _health = 100;
  int _happiness = 100;
  late String _pokemonImageUrl;

  @override
  void initState() {
    super.initState();
    _solmateNameDisplay = widget.solmateName;
    _pokemonImageUrl = widget.solmateAnimal.imageUrl;
    _saveSolmateData();
  }

  Future<void> _saveSolmateData() async {
    await HomeWidget.saveWidgetData<String>('solmateName', _solmateNameDisplay);
    await HomeWidget.saveWidgetData<int>('solmateHealth', _health);
    await HomeWidget.saveWidgetData<int>('solmateHappiness', _happiness);
    await HomeWidget.saveWidgetData<String>('solmateImageUrl', _pokemonImageUrl);
    await HomeWidget.updateWidget(name: 'SolmateWidget');
  }

  void _feedSolmate() {
    setState(() {
      _health = (_health + 10).clamp(0, 100);
      _happiness = (_happiness + 5).clamp(0, 100);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You fed your Solmate!')),
    );
    _saveSolmateData();
  }

  void _petSolmate() {
    setState(() {
      _happiness = (_happiness + 15).clamp(0, 100);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You petted your Solmate!')),
    );
    _saveSolmateData();
  }

  void _emoteSolmate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your Solmate emotes happily!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background, // Use background color from theme
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surface, // Use surface color for display area
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: colorScheme.primary, width: 4.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network(
                        _pokemonImageUrl,
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none, // For pixelated look
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 150,
                          height: 150,
                          color: colorScheme.background, // Use background color for error placeholder
                          child: Icon(Icons.pets, size: 80, color: colorScheme.onBackground.withOpacity(0.5)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _solmateNameDisplay.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'PressStart2P', // Placeholder for custom 8-bit font
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface, // Use onSurface color
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildStatRow('HP', _health, colorScheme.error, Icons.favorite),
                      _buildStatRow('HAP', _happiness, colorScheme.tertiary, Icons.sentiment_satisfied_alt),
                      const SizedBox(height: 10),
                      Text(
                        '''Wallet: ${widget.publicKey.substring(0, 6)}...${widget.publicKey.substring(widget.publicKey.length - 4)}''',
                        style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withOpacity(0.7)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Hardware-like buttons
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
              color: colorScheme.surface, // Use surface color for console body
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _HardwareButton(icon: Icons.restaurant, label: 'Feed', onPressed: _feedSolmate),
                  _HardwareButton(icon: Icons.pets, label: 'Pet', onPressed: _petSolmate),
                  _HardwareButton(icon: Icons.tag_faces, label: 'Emote', onPressed: _emoteSolmate),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: 'PressStart2P', // Placeholder for custom 8-bit font
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface, // Use onSurface color
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontFamily: 'PressStart2P', // Placeholder for custom 8-bit font
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HardwareButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _HardwareButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_HardwareButton> createState() => _HardwareButtonState();
}

class _HardwareButtonState extends State<_HardwareButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: colorScheme.primary, // Use primary color for button base
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: _isPressed
              ? [] // No shadow when pressed
              : [
                  BoxShadow(
                    color: colorScheme.onSurface.withOpacity(0.3), // Use onSurface for shadow
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ],
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.5), width: 2.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: colorScheme.onPrimary, size: 30),
            const SizedBox(height: 5),
            Text(
              widget.label,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
