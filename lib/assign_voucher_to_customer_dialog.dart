import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignVoucherToCustomerDialog extends StatefulWidget {
  final String customerUid;
  final String customerName;

  const AssignVoucherToCustomerDialog({
    super.key,
    required this.customerUid,
    required this.customerName,
  });

  @override
  State<AssignVoucherToCustomerDialog> createState() => _AssignVoucherToCustomerDialogState();
}

class _AssignVoucherToCustomerDialogState extends State<AssignVoucherToCustomerDialog> {
  String? selectedVoucherId;
  String? selectedVoucherCode;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Voucher'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Customer: ${widget.customerName}'),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('vouchers')
                .where('status', isEqualTo: 'available')
                .orderBy('created_at', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Text('No available vouchers.');
              }

              return DropdownButtonFormField<String>(
                isExpanded: true,
                hint: const Text('Select voucher to assign'),
                value: selectedVoucherId,
                items: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final code = data['code'] ?? 'N/A';
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(code),
                    onTap: () => selectedVoucherCode = code,
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedVoucherId = val),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: selectedVoucherId == null ? null : () async {
            final ref = FirebaseFirestore.instance.collection('vouchers').doc(selectedVoucherId);
            await ref.update({
              'status': 'assigned',
              'assigned_to': {
                'uid': widget.customerUid,
                'name': widget.customerName,
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