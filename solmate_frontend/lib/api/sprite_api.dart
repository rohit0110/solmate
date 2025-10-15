import 'dart:convert';
import 'package:http/http.dart' as http;

class SolmateApi {
  // TODO: Make this configurable via environment variables or a config file
  static const String _baseUrl = 'http://10.0.2.2:3000';

  static Future<Map<String, String>> getSprites(String animalName, String publicKey) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/sprite/$animalName/$publicKey'),
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
