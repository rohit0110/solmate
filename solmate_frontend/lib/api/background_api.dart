import 'dart:convert';
import 'package:http/http.dart' as http;

class BackgroundApi {
  // For Android emulator, 10.0.2.2 points to the host machine's localhost
  static const String _baseUrl = 'http://10.0.2.2:3000';

  static Future<List<dynamic>> getBackgrounds() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/backgrounds'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load backgrounds: ${response.body}');
    }
  }
}
