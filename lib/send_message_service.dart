import 'package:cloud_firestore/cloud_firestore.dart';

class SendMessageService {
  static Future<void> sendMessageToAllCustomers({required String message}) async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    final customers = await usersRef.where('role', isEqualTo: 'customer').get();

    final batch = FirebaseFirestore.instance.batch();
    final now = DateTime.now();

    for (final doc in customers.docs) {
      final userId = doc.id;
      final notifRef = usersRef.doc(userId).collection('notifications').doc();

      batch.set(notifRef, {
        'message': message,
        'status': 'unread',
        'sent_at': Timestamp.fromDate(now),
        'sender': 'admin',
        'type': 'broadcast',
      });
    }

    await batch.commit();
  }
}