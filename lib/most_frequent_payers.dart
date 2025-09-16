import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MostFrequentPayers extends StatelessWidget {
  final List<DocumentSnapshot> payments;

  const MostFrequentPayers({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> frequency = {};

    for (final doc in payments) {
      final name = doc['customer_name'] ?? 'Unknown';
      frequency[name] = (frequency[name] ?? 0) + 1;
    }

    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = sorted.take(5).toList();

    return Card(
      color: Colors.deepPurple.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🔁 Most Frequent Payers',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            ...top5.map((entry) => ListTile(
                  leading: const Icon(Icons.repeat, color: Colors.white70),
                  title: Text(entry.key,
                      style: const TextStyle(color: Colors.white)),
                  trailing: Text('${entry.value} payments',
                      style: const TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontWeight: FontWeight.bold)),
                )),
          ],
        ),
      ),
    );
  }
}