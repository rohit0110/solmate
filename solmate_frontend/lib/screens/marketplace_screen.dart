import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:bs58/bs58.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import 'package:solana_mobile_client/solana_mobile_client.dart';
import 'package:solmate_frontend/api/background_api.dart';
import 'package:solmate_frontend/api/decor_api.dart';
import 'package:solmate_frontend/api/purchase_api.dart';
import 'package:solmate_frontend/api/solmate_api.dart';
import 'package:solmate_frontend/models/background_asset.dart';
import 'package:solmate_frontend/models/decoration_asset.dart';

class MarketplaceResult {
  final List<DecorationAsset> decorations;
  final String? backgroundUrl;

  MarketplaceResult({required this.decorations, this.backgroundUrl});
}

class MarketplaceScreen extends StatefulWidget {
  final List<DecorationAsset> initialSelectedDecorations;
  final String? initialSelectedBackground;
  final int userLevel;
  final String pubkey;
  final String authToken;

  const MarketplaceScreen({
    super.key,
    required this.initialSelectedDecorations,
    required this.initialSelectedBackground,
    required this.userLevel,
    required this.pubkey,
    required this.authToken,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final SolmateBackendApi _solmateApi = SolmateBackendApi();
  late final SolanaClient _solanaClient;

  // Decoration State
  late List<DecorationAsset> _selectedDecorations;
  Map<String, List<DecorationAsset>> _availableDecorationsByPos = {};
  String? _selectedDecorationPositionKey;

  // Background State
  late String? _selectedBackgroundUrl;
  List<BackgroundAsset> _availableBackgrounds = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _selectedDecorations = List<DecorationAsset>.from(widget.initialSelectedDecorations);
    _selectedBackgroundUrl = widget.initialSelectedBackground;
    _solanaClient = SolanaClient(rpcUrl: Uri.parse('https://api.devnet.solana.com'), websocketUrl: Uri.parse('wss://api.devnet.solana.com'));
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Fetch both decorations and backgrounds in parallel
      final results = await Future.wait([
        DecorApi.getDecorations(widget.pubkey),
        BackgroundApi.getBackgrounds(widget.pubkey),
      ]);

      // Process Decorations
      final decorationsList = results[0];
      final Map<String, List<DecorationAsset>> processedDecorations = {};
      for (final item in decorationsList) {
        final asset = DecorationAsset.fromJson(item as Map<String, dynamic>);
        final key = '${asset.row}_${asset.col}';
        if (processedDecorations[key] == null) {
          processedDecorations[key] = [];
        }
        processedDecorations[key]!.add(asset);
      }

      // Process Backgrounds
      final backgroundsList = results[1];
      final List<BackgroundAsset> processedBackgrounds = backgroundsList
          .map((item) => BackgroundAsset.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _availableDecorationsByPos = processedDecorations;
        _availableBackgrounds = processedBackgrounds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load marketplace data: $e')),
      );
    }
  }

  Future<void> _initiatePurchase(dynamic asset) async {
    final paymentInfo = asset.paymentInfo;
    if (paymentInfo == null) return;

    final confirmed = await NesDialog.show<bool>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Buy ${asset.name}?'),
          const SizedBox(height: 16),
          Text('This will cost ${paymentInfo.amount} SOL.'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              NesButton(
                type: NesButtonType.normal,
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              NesButton(
                type: NesButtonType.primary,
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Buy'),
              ),
            ],
          )
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isPurchasing = true;
    });

    LocalAssociationScenario? session;
    try {
      session = await LocalAssociationScenario.create();
      session.startActivityForResult(null).ignore();
      final client = await session.start();

      await client.reauthorize(
        identityUri: Uri.parse(dotenv.env['APP_IDENTITY_URI']!),
        identityName: dotenv.env['APP_IDENTITY_NAME']!,
        authToken: widget.authToken,
      );

      final recipient = Ed25519HDPublicKey.fromBase58(paymentInfo.recipientPublicKey);
      final sender = Ed25519HDPublicKey.fromBase58(widget.pubkey);
      final lamports = (paymentInfo.amount * lamportsPerSol).toInt();

      final instruction = SystemInstruction.transfer(
        fundingAccount: sender,
        recipientAccount: recipient,
        lamports: lamports,
      );

      final message = Message.only(instruction);
      final latestBlockhash = await _solanaClient.rpcClient.getLatestBlockhash();

      final compiled = message.compileV0(
        recentBlockhash: latestBlockhash.value.blockhash,
        feePayer: sender,
      );

      final transaction = SignedTx(
        compiledMessage: compiled,
        signatures: [Signature(Uint8List(64), publicKey: sender)],
      );

      final unsignedTxBytes = base64Decode(transaction.encode());

      final result = await client.signAndSendTransactions(transactions: [unsignedTxBytes]);
      final signatureBytes = result.signatures.first;
      final signature = base58.encode(signatureBytes);
      print(signature);

      await PurchaseApi.verifyPurchase(
        transactionSignature: signature,
        assetId: asset is DecorationAsset ? 'decoration_${asset.name}' : 'background_${asset.name}',
        userPubkey: widget.pubkey,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase successful! Asset unlocked.')),
      );

      // Refresh data to show unlocked asset
      await _fetchData();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: $e')),
      );
    } finally {
      if (session != null) {
        await session.close();
      }
      setState(() {
        _isPurchasing = false;
      });
    }
  }

  void _onDecorationSelected(DecorationAsset? assetToSelect, int row, int col) {
    setState(() {
      _selectedDecorations.removeWhere((asset) => asset.row == row && asset.col == col);
      if (assetToSelect != null) {
        _selectedDecorations.add(assetToSelect);
      }
    });
  }

  void _onBackgroundSelected(BackgroundAsset background) {
    setState(() {
      _selectedBackgroundUrl = background.url;
    });
  }

  Future<void> _saveAndClose() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Save decorations and background in parallel
      await Future.wait([
        _solmateApi.saveDecorations(widget.pubkey, _selectedDecorations),
        if (_selectedBackgroundUrl != null)
          _solmateApi.saveSelectedBackground(widget.pubkey, _selectedBackgroundUrl!),
      ]);

      if (mounted) {
        Navigator.pop(
          context,
          MarketplaceResult(
            decorations: _selectedDecorations,
            backgroundUrl: _selectedBackgroundUrl,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save changes: $e')),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: _isLoading
              ? const Center(child: Text("Loading..."))
              : Stack(
                  children: [
                    Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: 'Decorations'),
                            Tab(text: 'Backgrounds'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildDecorationsTab(),
                              _buildBackgroundsTab(),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: NesButton(
                            type: NesButtonType.primary,
                            onPressed: _isSaving || _isPurchasing ? null : _saveAndClose,
                            child: const Text('Save & Close'),
                          ),
                        ),
                      ],
                    ),
                    if (_isSaving || _isPurchasing)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(_isSaving ? 'Saving...' : 'Purchasing...', style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  String _getPositionName(String? key) {
    if (key == null) return "";
    final parts = key.split('_');
    final row = int.parse(parts[0]);
    final col = int.parse(parts[1]);

    const rowNames = ['Top', 'Middle', 'Bottom'];
    const colNames = ['Left', 'Center', 'Right'];

    return "${rowNames[row]} ${colNames[col]}";
  }

  Widget _buildDecorationSelector() {
    if (_selectedDecorationPositionKey == null) {
      return Container(); // Return an empty container when no position is selected
    }

    final assetsForSlot = _availableDecorationsByPos[_selectedDecorationPositionKey!] ?? [];
    final positionName = _getPositionName(_selectedDecorationPositionKey);

    DecorationAsset? currentAssetInSlot;
    try {
      final parts = _selectedDecorationPositionKey!.split('_');
      final row = int.parse(parts[0]);
      final col = int.parse(parts[1]);
      currentAssetInSlot = _selectedDecorations.firstWhere((asset) => asset.row == row && asset.col == col);
    } catch (e) {
      currentAssetInSlot = null;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
        child: NesContainer(
          width: double.infinity,
          label: '$positionName',
          child: GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 1.0, // Make items square
            ),
            itemCount: assetsForSlot.length + 1,
            itemBuilder: (context, index) {
              // 'None' option
              if (index == 0) {
                final bool isSelected = currentAssetInSlot == null;
                return InkWell(
                  onTap: () => _onDecorationSelected(null, int.parse(_selectedDecorationPositionKey!.split('_')[0]), int.parse(_selectedDecorationPositionKey!.split('_')[1])!),
                  child: NesContainer(
                    padding: const EdgeInsets.all(4.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(child: Text('None', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))), // Use theme color
                        if (isSelected)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green, width: 4),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }

              final asset = assetsForSlot[index - 1];
              final bool isSelected = currentAssetInSlot?.url == asset.url;
              final bool isLocked = !asset.isUnlocked;

              String lockText = "";
              if (isLocked && asset.unlock != null) {
                if (asset.unlock!.type == 'level') {
                    lockText = "Lvl ${asset.unlock!.value}";
                } else if (asset.unlock!.type == 'paid') {
                  lockText = "${asset.unlock!.value} SOL";
                }
              }

              return InkWell(
                onTap: isLocked 
                    ? (asset.unlock?.type == 'paid' ? () => _initiatePurchase(asset) : null)
                    : () => _onDecorationSelected(asset, asset.row, asset.col),
                child: NesContainer(
                  padding: const EdgeInsets.all(4.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Asset Image
                      Image.network(
                        '${dotenv.env['BACKEND_URL']!}${asset.url}',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain, // Use contain for decorations
                        errorBuilder: (ctx, err, st) => const Icon(Icons.error, color: Colors.red),
                      ),

                      // Name at the bottom
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          color: Colors.black.withOpacity(0.5),
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            asset.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      // Locked Overlay
                      if (isLocked)
                        Container(
                          color: Colors.black.withOpacity(0.6),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(asset.unlock?.type == 'paid' ? Icons.shopping_cart : Icons.lock, color: const Color.fromARGB(255, 255, 212, 41), size: 32),
                                const SizedBox(height: 4),
                                Text(
                                  lockText,
                                  style: const TextStyle(color: Color.fromARGB(255, 255, 212, 41), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Selection Border
                      if (isSelected)
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 4),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDecorationsTab() {
    final selectedMap = HashMap<String, DecorationAsset>();
    for (var asset in _selectedDecorations) {
      selectedMap['${asset.row}_${asset.col}'] = asset;
    }
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: NesContainer(
            padding: const EdgeInsets.all(16.0),
            label: "ACCESSORIES",
            backgroundColor: colorScheme.surface,
            painterBuilder: NesContainerSquareCornerPainter.new,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellSize = constraints.maxWidth / 3;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (row) {
                    return Row(
                      children: List.generate(3, (col) {
                        final selectedAsset = selectedMap['${row}_${col}'];
                        final isSelectedCell = _selectedDecorationPositionKey == '${row}_${col}';
                        return GestureDetector(
                          onTap: () {
                            if (row == 2 && col == 1) return;
                            setState(() {
                              _selectedDecorationPositionKey = '${row}_${col}';
                            });
                          },
                          child: Container(
                            width: cellSize,
                            height: cellSize,
                            decoration: BoxDecoration(
                              color: isSelectedCell ? colorScheme.primaryContainer : colorScheme.surfaceVariant,
                              border: Border.all(color: Colors.black, width: isSelectedCell ? 3 : 1),
                            ),
                            child: (row == 2 && col == 1)
                                ? Center(child: Text('SOLMATE', style: TextStyle(color: colorScheme.onSurface)))
                                : selectedAsset != null
                                    ? Image.network(
                                        '${dotenv.env['BACKEND_URL']!}${selectedAsset.url}',
                                        fit: BoxFit.contain,
                                        errorBuilder: (ctx, err, st) => const Icon(Icons.error, color: Colors.red),
                                      )
                                    : null,
                          ),
                        );
                      }),
                    );
                  }),
                );
              },
            ),
          ),
        ),
        _buildDecorationSelector(),
      ],
    );
  }

  Widget _buildBackgroundsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 1.0, // Make items square
      ),
      itemCount: _availableBackgrounds.length,
      itemBuilder: (context, index) {
        final background = _availableBackgrounds[index];
        final isSelected = _selectedBackgroundUrl == background.url;
        final isLocked = !background.isUnlocked;

        String lockText = "";
        if (isLocked && background.unlock != null) {
          if (background.unlock!.type == 'level') {
            lockText = "Lvl ${background.unlock!.value}";
          } else if (background.unlock!.type == 'paid') {
            lockText = "${background.unlock!.value} SOL";
          }
        }

        return InkWell(
          onTap: isLocked 
              ? (background.unlock?.type == 'paid' ? () => _initiatePurchase(background) : null)
              : () => _onBackgroundSelected(background),
          child: NesContainer(
            padding: const EdgeInsets.all(4.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Image
                Image.network(
                  '${dotenv.env['BACKEND_URL']!}${background.url}',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => const Icon(Icons.error, color: Colors.red),
                ),

                // Name at the bottom
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      background.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ), 
                ),

                // Locked Overlay
                if (isLocked)
                  Container(
                    color: Colors.black.withOpacity(0.6),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(background.unlock?.type == 'paid' ? Icons.shopping_cart : Icons.lock, color: const Color.fromARGB(255, 255, 212, 41), size: 32),
                          const SizedBox(height: 4),
                          Text(
                            lockText,
                            style: const TextStyle(color: Color.fromARGB(255, 255, 212, 41), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Selection Border
                if (isSelected)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 4),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
