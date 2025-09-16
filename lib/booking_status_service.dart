import 'package:http/http.dart' as http;
import 'dart:convert';

class BookingStatusService {
  static Future<String?> checkStatus(String orderTrackingId) async {
    final url = Uri.parse(
      'https://smartconnect-pesapal-api.onrender.com/check-payment-status/$orderTrackingId/',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status']; // "COMPLETED", "PENDING", etc.
      } else {
        print('❌ Status check failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception during status check: $e');
      return null;
    }
  }
}