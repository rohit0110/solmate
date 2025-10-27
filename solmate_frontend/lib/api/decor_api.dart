import 'dart:convert';
import 'package:http/http.dart' as http;

class DecorApi {
  static const String _baseUrl = 'http://10.0.2.2:3000';

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
