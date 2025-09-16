import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class PaymentMethodBreakdown extends StatelessWidget {
  final List<DocumentSnapshot> payments;

  const PaymentMethodBreakdown({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> methodCounts = {};

    for (final doc in payments) {
      final method = (doc['method'] ?? 'Unknown').toString();
      methodCounts[method] = (methodCounts[method] ?? 0) + 1;
    }

    final total = methodCounts.values.fold<int>(0, (a, b) => a + b);
    final colors = [Colors.teal, Colors.orange, Colors.purple, Colors.blue];

    return Card(
      color: Colors.blueGrey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 Payment Method Breakdown',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: methodCounts.entries.mapIndexed((index, entry) {
                    final percentage = (entry.value / total * 100).toStringAsFixed(1);
                    return PieChartSectionData(
                      color: colors[index % colors.length],
                      value: entry.value.toDouble(),
                      title: '${entry.key}\n$percentage%',
                      radius: 60,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E item) f) {
    var index = 0;
    return map((e) => f(index++, e));
  }
}