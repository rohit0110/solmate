import 'package:solmate_frontend/models/decoration_asset.dart'; // Re-using UnlockCondition

class BackgroundAsset {
  final String name;
  final String url;
  final UnlockCondition? unlock;

  BackgroundAsset({
    required this.name,
    required this.url,
    this.unlock,
  });

  factory BackgroundAsset.fromJson(Map<String, dynamic> json) {
    return BackgroundAsset(
      name: json['name'] as String,
      url: json['url'] as String,
      unlock: json['unlock'] != null
          ? UnlockCondition.fromJson(json['unlock'])
          : null,
    );
  }
}
