import 'dart:convert';
import 'package:http/http.dart' as http;

class PurchaseApi {
  static const String _baseUrl = 'http://10.0.2.2:3000';

  static Future<void> verifyPurchase({
    required String transactionSignature,
    required String assetId,
    required String userPubkey,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/purchase/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'transactionSignature': transactionSignature,
        'assetId': assetId,
        'userPubkey': userPubkey,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to verify purchase: ${response.body}');
    }
  }
}
