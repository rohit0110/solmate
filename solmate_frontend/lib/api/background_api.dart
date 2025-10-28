import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BackgroundApi {
  static final String _baseUrl = dotenv.env['BACKEND_URL']!;

  static Future<List<dynamic>> getBackgrounds(String pubkey) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/backgrounds?pubkey=$pubkey'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load backgrounds: ${response.body}');
    }
  }
}
