import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignVoucherDialog extends StatefulWidget {
  final DocumentSnapshot voucherDoc;

  const AssignVoucherDialog({super.key, required this.voucherDoc});

  @override
  State<AssignVoucherDialog> createState() => _AssignVoucherDialogState();
}

class _AssignVoucherDialogState extends State<AssignVoucherDialog> {
  String? selectedUserId;
  String? selectedUserName;

  @override
  Widget build(BuildContext context) {
    final voucher = widget.voucherDoc.data() as Map<String, dynamic>;

    return AlertDialog(
      title: const Text('Assign Voucher'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Code: ${voucher['code']}'),
          Text('Package: ${voucher['package']}'),
          Text('Network: ${voucher['network']}'),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'customer')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();

              final customers = snapshot.data!.docs;

              return DropdownButtonFormField<String>(
                value: selectedUserId,
                hint: const Text('Select customer'),
                items: customers.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final fullName = data['full_name'] ?? 'No Name';
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(fullName),
                    onTap: () => selectedUserName = fullName,
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedUserId = val),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: selectedUserId == null
              ? null
              : () async {
                  await widget.voucherDoc.reference.update({
                    'status': 'assigned',
                    'assigned_to': {
                      'uid': selectedUserId,
                      'name': selectedUserName ?? 'customer',
                    },
                    'assigned_at': Timestamp.now(),
                  });
                  Navigator.pop(context);
                },
          child: const Text('Assign'),
        ),
      ],
    );
  }
}