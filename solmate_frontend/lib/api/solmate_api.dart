import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:solmate_frontend/models/decoration_asset.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SolmateBackendApi {
  static final String _baseUrl = dotenv.env['BACKEND_URL']!;

  Future<Map<String, dynamic>?> getSolmateData(String pubkey) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/solmate?pubkey=$pubkey'));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body; // Can be null if not found
    } else {
      throw Exception('Failed to load solmate data: ${response.body}');
    }
  }

  Future<void> createSolmate(String pubkey, String name, String animal) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/solmate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pubkey': pubkey, 'name': name, 'animal': animal.toLowerCase()}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create solmate: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> feedSolmate(String pubkey) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/solmate/feed'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pubkey': pubkey}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to feed solmate: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> petSolmate(String pubkey) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/solmate/pet'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pubkey': pubkey}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to pet solmate: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> run(String pubkey, int score) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/solmate/run'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pubkey': pubkey, 'score': score}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit run score: ${response.body}');
    }
  }

  Future<void> saveDecorations(String pubkey, List<DecorationAsset> decorations) async {
    // Convert the flat list of decorations into a 2D grid for the backend.
    final grid = List.generate(3, (_) => List<DecorationAsset?>.generate(3, (_) => null));
    for (final asset in decorations) {
      if (asset.row >= 0 && asset.row < 3 && asset.col >= 0 && asset.col < 3) {
        grid[asset.row][asset.col] = asset;
      }
    }

    final url = Uri.parse('$_baseUrl/api/solmate/decorations');
    final body = jsonEncode({
      'pubkey': pubkey,
      // The backend expects the name and url properties, so we use toJson.
      'decorations': grid.map((row) => row.map((asset) => asset?.toJson()).toList()).toList(),
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save decorations: ${response.body}');
    }
  }

  Future<void> saveSelectedBackground(String pubkey, String backgroundUrl) async {
    final url = Uri.parse('$_baseUrl/api/solmate/background');
    final body = jsonEncode({
      'pubkey': pubkey,
      'backgroundUrl': backgroundUrl,
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save background: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> cleanPoo(String pubkey) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/solmate/clean'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pubkey': pubkey}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to clean poo: ${response.body}');
    }
  }
}