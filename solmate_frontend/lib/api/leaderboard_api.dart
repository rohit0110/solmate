import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leaderboard_data.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LeaderboardApi {
  static final String _baseUrl = dotenv.env['BACKEND_URL']!;

  static Future<LeaderboardData> getLeaderboard(String pubkey) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/leaderboard?pubkey=$pubkey'));

    if (response.statusCode == 200) {
      return LeaderboardData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load leaderboard');
    }
  }

  static Future<LeaderboardData> getSurvivalLeaderboard(String pubkey) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/leaderboard/survival?pubkey=$pubkey'));

    if (response.statusCode == 200) {
      return LeaderboardData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load survival leaderboard');
    }
  }
}
