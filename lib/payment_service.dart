import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentService {
  static Future<String?> initiatePaymentViaBackend({
    required String phone,
    required int amount,
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    final url = Uri.parse('https://smartconnect-pesapal-api.onrender.com/submit-order-request/');

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final body = jsonEncode({
      "phone": phone,
      "amount": amount
      
    });

    print('📦 Sending booking request to backend: $body');

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Backend response: $data');

        if (data.containsKey('redirect_url')) {
          return data['redirect_url'];
        } else {
          print('⚠️ No redirect_url found in response');
          return null;
        }
      } else {
        print('❌ Backend error: ${response.statusCode} → ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception during backend call: $e');
      return null;
    }
  }
}