import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentService {
  // 🔗 Backend URL hosted on Render
  static const String baseUrl = "https://smartconnect-pesapal-api.onrender.com/api/zenopay";

  /// 🧾 Step 1: Initiate Zenopay payment via Django backend
  static Future<String?> initiateZenopayPayment({
    required String phone,
    required int amount,
    required String network,
    required String package,
    required String paymentMethod, // ✅ Added
    String buyerName = "SmartConnect User",
    String buyerEmail = "user@smartconnect.tz",
    String? customerId,
  }) async {
    final url = Uri.parse("$baseUrl/initiate/");
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final body = jsonEncode({
      "phone": phone,
      "amount": amount,
      "buyer_name": buyerName,
      "buyer_email": buyerEmail,
      "network": network,
      "package": package,
      "payment_method": paymentMethod, // ✅ Added
      if (customerId != null) "customer_id": customerId,
    });

    print('📦 Sending Zenopay request: $body');

    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      print('📥 Zenopay response: ${response.statusCode} → ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Parsed response: $data');

        final status = data['status']?.toString().toLowerCase();
        final orderId = data['order_id']?.toString();

        if ((status == 'initiated' || status == 'success') && orderId != null) {
          return orderId;
        } else if (data['resultcode'] == '000' && orderId != null) {
          return orderId;
        } else {
          print('⚠️ Unexpected success response: $data');
          return null;
        }
      } else {
        print('❌ Zenopay error: ${response.statusCode} → ${response.body}');
        return null;
      }
    } catch (e) {
      print('⚠️ Timeout or error during Zenopay call: $e');
      return "PENDING_REQUEST_SENT";
    }
  }

  /// 📊 Step 2: Check Zenopay payment status via Django backend (with retry + fallback)
  static Future<String> checkZenopayStatus(String orderId) async {
    final url = Uri.parse("$baseUrl/status/$orderId/");
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    print('🔍 Checking status for order: $orderId');

    int attempts = 0;
    const maxAttempts = 3;
    String lastError = "";

    while (attempts < maxAttempts) {
      try {
        print('🔁 Attempt ${attempts + 1} → $url');
        final response = await http
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 15));

        print('📊 Status response: ${response.statusCode} → ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final rawStatus = data['status']?.toString().toUpperCase();

          print('🔹 Raw status: $rawStatus');

          if (rawStatus == "COMPLETED" || rawStatus == "SUCCESS") {
            return "COMPLETED";
          } else if (["PENDING", "INITIATED", "PROCESSING"].contains(rawStatus)) {
            return "PENDING";
          } else if (["FAIL", "FAILED", "CANCELLED"].contains(rawStatus)) {
            return "FAIL";
          } else {
            return "UNKNOWN";
          }
        } else {
          print('❌ Status check failed: ${response.statusCode}');
          lastError = "Status code ${response.statusCode}";
        }
      } catch (e) {
        print('❌ Exception during status check: $e');
        lastError = e.toString();
      }

      attempts++;
    }

    print('⚠️ All attempts failed for $orderId. Returning fallback status.');
    return "UNKNOWN";
  }
}