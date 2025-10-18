class LeaderboardEntry {
  final String name;
  final int score;
  final String? sprite; // Can be null if sprite generation failed

  LeaderboardEntry({required this.name, required this.score, this.sprite});

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      name: json['name'],
      score: json['run_highscore'],
      sprite: json['sprite'],
    );
  }
}
