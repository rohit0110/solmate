import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SolmateApi {
  static final String _baseUrl = dotenv.env['BACKEND_URL']!;

  static Future<Map<String, String>> getSprites(String animalName, String publicKey) async {
    final animalLower = animalName.toLowerCase();
    final response = await http.get(
      Uri.parse('$_baseUrl/api/sprite/$animalLower/$publicKey'),
    );
    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, then parse the JSON.
      final Map<String, dynamic> data = jsonDecode(response.body);
      return {
        'normal': data['normal'] as String,
        'happy': data['happy'] as String,
        'dead': data['dead'] as String,
      };
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load sprites for $animalName');
    }
  }
}
