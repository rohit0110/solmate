import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leaderboard_data.dart';

class LeaderboardApi {
  static const String _baseUrl = 'http://10.0.2.2:3000/api';

  static Future<LeaderboardData> getLeaderboard(String pubkey) async {
    final response = await http.get(Uri.parse('$_baseUrl/leaderboard?pubkey=$pubkey'));

    if (response.statusCode == 200) {
      return LeaderboardData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load leaderboard');
    }
  }
}
