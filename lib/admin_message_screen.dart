import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'send_message_service.dart';

class AdminMessageScreen extends StatefulWidget {
  const AdminMessageScreen({super.key});

  @override
  State<AdminMessageScreen> createState() => _AdminMessageScreenState();
}

class _AdminMessageScreenState extends State<AdminMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedUserId;
  bool _sendSms = false;
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance.collection('users');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Message to Customers'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Message', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your message here...',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Send To', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: usersRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final users = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  value: _selectedUserId,
                  hint: const Text('Select a customer or send to all'),
                  items: [
                    const DropdownMenuItem(value: 'ALL', child: Text('All Customers')),
                    ...users.map((doc) {
                      final name = doc['full_name'] ?? 'Unnamed';
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(name),
                      );
                    }),
                  ],
                  onChanged: (value) => setState(() => _selectedUserId = value),
                );
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _sendSms,
              onChanged: (val) => setState(() => _sendSms = val!),
              title: const Text('Also send via SMS'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: _isSending
                  ? const CircularProgressIndicator(color: Colors.green)
                  : const Text('Send Message'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              onPressed: _isSending ? null : _handleSendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message and select a recipient.')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await SendMessageService.sendMessageToUsers(
        message: message,
        targetUserId: _selectedUserId!,
        sendSms: _sendSms,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully!')),
      );

      _messageController.clear();
      setState(() => _selectedUserId = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }
}