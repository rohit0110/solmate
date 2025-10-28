import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:solmate_frontend/api/sprite_api.dart';
import 'package:solmate_frontend/api/solmate_api.dart';
import 'package:solmate_frontend/models/solmate_data.dart';
import 'package:solmate_frontend/screens/solmate_screen.dart';

class SolmateHatchingScreen extends StatefulWidget {
  final SolmateAnimal solmateAnimal;
  final String publicKey;
  final String authToken;

  const SolmateHatchingScreen({
    super.key,
    required this.solmateAnimal,
    required this.publicKey,
    required this.authToken,
  });

  @override
  State<SolmateHatchingScreen> createState() => _SolmateHatchingScreenState();
}

class _SolmateHatchingScreenState extends State<SolmateHatchingScreen> with SingleTickerProviderStateMixin {
  final SolmateBackendApi _api = SolmateBackendApi();
  final TextEditingController _nameController = TextEditingController();
  bool _isHatched = false;
  bool _isMinting = false;
  late final AnimationController _mintController;
  double _mintProgress = 0.0;
  Map<String, String>? _spriteData;
  Uint8List? _normalSpriteBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    SolmateApi.getSprites(widget.solmateAnimal.name, widget.publicKey).then((data) {
      if (mounted) {
        setState(() {
          _spriteData = data;
          _normalSpriteBytes = base64Decode(data['normal']!);
          _isLoading = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Optionally show an error message
      }
    });
    // Trigger the hatching animation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isHatched = true;
        });
      }
    });
    _mintController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), //CHANGE
    )..addListener(() {
        setState(() {
          _mintProgress = _mintController.value;
        });
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => SolmateScreen(
              animalName: widget.solmateAnimal.name,
              publicKey: widget.publicKey,
              solmateName: _nameController.text.trim(),
              solmateSprites: _spriteData,
              authToken: widget.authToken,
            ),
          ));
        }
      });
  }

  @override
  void dispose() {
    _mintController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _confirmName() async {
    final String solmateName = _nameController.text.trim();
    if (solmateName.isNotEmpty) {
      setState(() {
        _isMinting = true;
      });

      try {
        await _api.createSolmate(widget.publicKey, solmateName, widget.solmateAnimal.name);
        // If successful, start the animation.
        _mintController.forward(from: 0.0);
      } catch (e) {
        // Handle error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create Solmate: $e')),
          );
          setState(() {
            _isMinting = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please Give your Solmate a name!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget imageWidget;
    if (_isLoading) {
      imageWidget = const NesProgressBar(value: 0.75,);
    } else if (_normalSpriteBytes != null)
      imageWidget = Image.memory(
        _normalSpriteBytes!,
        width: 150,
        height: 150,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      );
    else if (widget.solmateAnimal.normalSpritePath.startsWith('http')) {
      imageWidget = Image.network(
        widget.solmateAnimal.normalSpritePath,
        width: 150,
        height: 150,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (context, error, stackTrace) =>
            NesContainer(
              width: 150,
              height: 150,
              backgroundColor: colorScheme.background,
              child: Icon(Icons.pets, size: 80, color: colorScheme.onBackground.withOpacity(0.5)),
            ),
      );
    } else {
      imageWidget = Image.asset(
        widget.solmateAnimal.normalSpritePath,
        width: 150,
        height: 150,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (context, error, stackTrace) =>
            NesContainer(
              width: 150,
              height: 150,
              backgroundColor: colorScheme.background,
              child: Icon(Icons.pets, size: 80, color: colorScheme.onBackground.withOpacity(0.5)),
            ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background, // Use background color from theme
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
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
                      child: imageWidget,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (_isHatched)
                  _isMinting
                      ? Column(
                          children: [
                            Text(
                              'Minting your Solmate NFT...',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onBackground,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            NesProgressBar(
                              style: NesProgressBarStyle.pixel,
                              label: "Minting progress",
                              value: _mintProgress,
                            )
                          ],
                        )
                      : Column(
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
                                maxLength: 10,
                                showCursor: true,
                              ),
                            ),
                            const SizedBox(height: 20),
                            NesButton(
                              type: NesButtonType.primary,
                              onPressed: _confirmName,
                              child: Text('Confirm Name',
                                  style: TextStyle(
                                      color: colorScheme.onPrimary)),
                            ),
                          ],
                        ),
              ],
            ),
          ),
        )),
      ),
    ));
  }
}
