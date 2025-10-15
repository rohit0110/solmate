import 'dart:convert';
import 'package:http/http.dart' as http;

class SolmateBackendApi {
  // Assuming backend runs on localhost:3000
  // For Android emulator, use 10.0.2.2
  // For iOS simulator, use localhost
  static const String _baseUrl = 'http://10.0.2.2:3000/api/solmate';

  Future<Map<String, dynamic>?> getSolmateData(String pubkey) async {
    final response = await http.get(Uri.parse('$_baseUrl?pubkey=$pubkey'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    }
    else {
      throw Exception('Failed to load solmate data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createSolmate(String pubkey, String name, String animal) async {
    final response = await http.post(
      Uri.parse('$_baseUrl'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'pubkey': pubkey, 'name': name, 'animal': animal}),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create solmate: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> feedSolmate(String pubkey) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/feed'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'pubkey': pubkey}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to feed solmate: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> petSolmate(String pubkey) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/pet'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'pubkey': pubkey}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to pet solmate: ${response.statusCode}');
    }
  }
}
