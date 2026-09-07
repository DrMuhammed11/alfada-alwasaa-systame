import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../models/correspondence_model.dart';
import '../../constants/api_constants.dart';
import '../http_client.dart';

/// عميل استدعاءات الإحالات
class ReferralsApi {
  final AppHttpClient _http = AppHttpClient();

  Future<List<ReferralItem>> getMyReferrals() async {
    try {
      final response = await _http.get(
        Uri.parse('${ApiConstants.referrals}?limit=100'),
        timeout: const Duration(seconds: 5),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = (body is Map && body.containsKey('data')) ? body['data'] : (body is List ? body : []);
        return list.map((j) => ReferralItem.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('getMyReferrals exception: $e');
    }
    return [];
  }
}
