class DecorationAsset {
  final int row;
  final int col;
  final String name;
  final String url;

  DecorationAsset({
    required this.row,
    required this.col,
    required this.name,
    required this.url,
  });

  factory DecorationAsset.fromJson(Map<String, dynamic> json) {
    return DecorationAsset(
      row: json['row'] as int,
      col: json['col'] as int,
      name: json['name'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'col': col,
      'name': name,
      'url': url,
    };
  }
}