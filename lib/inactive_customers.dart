import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InactiveCustomers extends StatelessWidget {
  final List<DocumentSnapshot> payments;

  const InactiveCustomers({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonthPayments = payments.where((doc) {
      final date = (doc['date'] as Timestamp).toDate();
      return date.month == now.month && date.year == now.year;
    }).toList();

    final allCustomerIds = payments.map((doc) => doc['customer_id']).toSet();
    final activeCustomerIds =
        currentMonthPayments.map((doc) => doc['customer_id']).toSet();

    final inactiveIds = allCustomerIds.difference(activeCustomerIds);

    final Map<String, String> inactiveNames = {};
    for (final doc in payments) {
      final id = doc['customer_id'];
      final name = doc['customer_name'];
      if (inactiveIds.contains(id)) {
        inactiveNames[id] = name;
      }
    }

    final sorted = inactiveNames.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Card(
      color: Colors.orange.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🕒 Inactive Customers (This Month)',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            if (sorted.isEmpty)
              const Text('✅ All customers have paid this month.',
                  style: TextStyle(color: Colors.greenAccent))
            else
              ...sorted.map((entry) => ListTile(
                    leading: const Icon(Icons.person_off,
                        color: Colors.white70),
                    title: Text(entry.value,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text('ID: ${entry.key}',
                        style: const TextStyle(color: Colors.white54)),
                  )),
          ],
        ),
      ),
    );
  }
}