class LeaderboardEntry {
  final int rank;
  final String pubkey;
  final String name;
  final int score;
  final String? sprite;

  LeaderboardEntry({
    required this.rank,
    required this.pubkey,
    required this.name,
    required this.score,
    this.sprite,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: int.parse(json['rank']),
      pubkey: json['pubkey'],
      name: json['name'],
      score: json['score'] is String ? double.parse(json['score']).toInt() : (json['score'] as num).toInt(), // Handle string (double) or num
      sprite: json['sprite'],
    );
  }
}
