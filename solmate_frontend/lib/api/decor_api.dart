import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DecorApi {
  static final String _baseUrl = dotenv.env['BACKEND_URL']!;

  static Future<List<dynamic>> getDecorations(String pubkey) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/decor?pubkey=$pubkey'));

      if (response.statusCode == 200) {
        // The response body is now a JSON array (List<dynamic>)
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load decorations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch decorations: $e');
    }
  }
}
