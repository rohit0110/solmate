import 'package:solmate_frontend/models/decoration_asset.dart'; // Re-using UnlockCondition and PaymentInfo

class BackgroundAsset {
  final String name;
  final String url;
  final UnlockCondition? unlock;
  final bool isUnlocked;
  final PaymentInfo? paymentInfo;

  BackgroundAsset({
    required this.name,
    required this.url,
    this.unlock,
    required this.isUnlocked,
    this.paymentInfo,
  });

  factory BackgroundAsset.fromJson(Map<String, dynamic> json) {
    return BackgroundAsset(
      name: json['name'] as String,
      url: json['url'] as String,
      unlock: json['unlock'] != null
          ? UnlockCondition.fromJson(json['unlock'])
          : null,
      isUnlocked: json['isUnlocked'] as bool,
      paymentInfo: json['paymentInfo'] != null
          ? PaymentInfo.fromJson(json['paymentInfo'])
          : null,
    );
  }
}
