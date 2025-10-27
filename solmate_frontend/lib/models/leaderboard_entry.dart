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
      rank: json['rank'],
      pubkey: json['pubkey'],
      name: json['name'],
      score: json['score'],
      sprite: json['sprite'],
    );
  }
}
