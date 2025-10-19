import './leaderboard_entry.dart';

class LeaderboardData {
  final List<LeaderboardEntry> leaderboard;
  final LeaderboardEntry? user;

  LeaderboardData({required this.leaderboard, this.user});

  factory LeaderboardData.fromJson(Map<String, dynamic> json) {
    var leaderboardList = json['leaderboard'] as List;
    List<LeaderboardEntry> leaderboard = leaderboardList.map((i) => LeaderboardEntry.fromJson(i)).toList();
    
    LeaderboardEntry? user;
    if (json['user'] != null) {
      user = LeaderboardEntry.fromJson(json['user']);
    }

    return LeaderboardData(
      leaderboard: leaderboard,
      user: user,
    );
  }
}
