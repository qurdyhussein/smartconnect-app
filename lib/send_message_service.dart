import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class SendMessageService {
  static const String atApiKey = 'atsk_6ccf22b28ae31c2f02047fffb43ed7b5fbf3593232e392bf9bea6a852efdd65e6f8676bd'; // weka API key yako hapa
  static const String atUsername = 'sandbox'; // au jina la live account
  static const String smsEndpoint =
      'https://api.sandbox.africastalking.com/version1/messaging';

  static Future<void> sendMessageToUsers({
    required String message,
    required String targetUserId,
    required bool sendSms,
  }) async {
    final usersRef = FirebaseFirestore.instance.collection('users');

    if (targetUserId == 'ALL') {
      final allUsers = await usersRef.get();
      for (var doc in allUsers.docs) {
        await _sendToSingleUser(
          userId: doc.id,
          phoneNumber: doc['phone_number'],
          message: message,
          sendSms: sendSms,
        );
      }
    } else {
      final userDoc = await usersRef.doc(targetUserId).get();
      final phone = userDoc['phone_number'];
      await _sendToSingleUser(
        userId: targetUserId,
        phoneNumber: phone,
        message: message,
        sendSms: sendSms,
      );
    }
  }

  static Future<void> _sendToSingleUser({
    required String userId,
    required String phoneNumber,
    required String message,
    required bool sendSms,
  }) async {
    final timestamp = FieldValue.serverTimestamp();

    // 1. Tuma notification Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'message': message,
      'timestamp': timestamp,
      'status': 'unread',
      'channel': sendSms ? 'SMS + App' : 'App',
    });

    // 2. Tuma SMS ikiwa imechaguliwa
    String? smsStatus;
    if (sendSms) {
      try {
        final response = await http.post(
          Uri.parse(smsEndpoint),
          headers: {
            'apiKey': atApiKey,
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: {
            'username': atUsername,
            'to': phoneNumber,
            'message': message,
          },
        );

        smsStatus = response.statusCode == 201 ? 'Success' : 'Failed';
      } catch (e) {
        smsStatus = 'Failed';
      }
    }

    // 3. Log usage history
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('usageHistory')
        .add({
      'type': 'Message Sent',
      'description': 'Sent: "$message" to $phoneNumber',
      'status': sendSms ? (smsStatus ?? 'Unknown') : 'App Only',
      'channel': sendSms ? 'SMS + App' : 'App',
      'timestamp': timestamp,
    });
  }
}