import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leaderboard_entry.dart';

class LeaderboardApi {
  static const String _baseUrl = 'http://10.0.2.2:3000/api';

  static Future<List<LeaderboardEntry>> getLeaderboard() async {
    final response = await http.get(Uri.parse('$_baseUrl/leaderboard'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<LeaderboardEntry> leaderboard = body
          .map((dynamic item) => LeaderboardEntry.fromJson(item))
          .toList();
      return leaderboard;
    } else {
      throw Exception('Failed to load leaderboard');
    }
  }
}
