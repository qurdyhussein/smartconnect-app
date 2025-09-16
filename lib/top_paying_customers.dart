import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TopPayingCustomers extends StatelessWidget {
  final List<DocumentSnapshot> payments;

  const TopPayingCustomers({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> totals = {};

    for (final doc in payments) {
      final name = doc['customer_name'] ?? 'Unknown';
      final amount = (doc['amount'] ?? 0).toDouble();

      totals[name] = (totals[name] ?? 0) + amount;
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = sorted.take(5).toList();

    return Card(
      color: Colors.teal.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🏆 Top Paying Customers',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            ...top5.map((entry) => ListTile(
                  leading: const Icon(Icons.person, color: Colors.white70),
                  title: Text(entry.key,
                      style: const TextStyle(color: Colors.white)),
                  trailing: Text('TSh ${entry.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold)),
                )),
          ],
        ),
      ),
    );
  }
}