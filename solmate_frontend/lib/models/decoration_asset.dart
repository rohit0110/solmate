class PaymentInfo {
  final String recipientPublicKey;
  final double amount;

  PaymentInfo({required this.recipientPublicKey, required this.amount});

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      recipientPublicKey: json['recipientPublicKey'],
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class UnlockCondition {
  final String type;
  final dynamic value; // Can be int for level or double for amount

  UnlockCondition({required this.type, required this.value});

  factory UnlockCondition.fromJson(Map<String, dynamic> json) {
    return UnlockCondition(
      type: json['type'],
      value: json['level'] ?? json['amount'],
    );
  }
}

class DecorationAsset {
  final int row;
  final int col;
  final String name;
  final String url;
  final UnlockCondition? unlock;
  final bool isUnlocked;
  final PaymentInfo? paymentInfo;

  DecorationAsset({
    required this.row,
    required this.col,
    required this.name,
    required this.url,
    this.unlock,
    required this.isUnlocked,
    this.paymentInfo,
  });

  factory DecorationAsset.fromJson(Map<String, dynamic> json) {
    return DecorationAsset(
      row: json['row'] as int,
      col: json['col'] as int,
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

  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'col': col,
      'name': name,
      'url': url,
      // We don't need to send unlock info back when saving
    };
  }
}