import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'top_paying_customers.dart';
import 'most_frequent_payers.dart';
import 'inactive_customers.dart';
import 'payment_method_breakdown.dart';
import 'analysis_export_helper.dart'; // <- hakikisha hili lipo

class CustomerAnalysisScreen extends StatefulWidget {
  final List<DocumentSnapshot> allPayments;

  const CustomerAnalysisScreen({super.key, required this.allPayments});

  @override
  State<CustomerAnalysisScreen> createState() => _CustomerAnalysisScreenState();
}

class _CustomerAnalysisScreenState extends State<CustomerAnalysisScreen> {
  late DateTime selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
  }

  List<DocumentSnapshot> get filteredPayments {
    return widget.allPayments.where((doc) {
      final date = (doc['date'] as Timestamp).toDate();
      return date.month == selectedMonth.month && date.year == selectedMonth.year;
    }).toList();
  }

  List<String> getRecentMonths(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final date = DateTime(now.year, now.month - i, 1);
      return DateFormat('MMMM yyyy').format(date);
    });
  }

  @override
  Widget build(BuildContext context) {
    final months = getRecentMonths(6);
    final selectedLabel = DateFormat('MMMM yyyy').format(selectedMonth);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF001F3F),
        appBar: AppBar(
          title: const Text('Customer Analysis'),
          backgroundColor: Colors.teal,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.download),
              onSelected: (value) async {
                if (filteredPayments.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚠️ No data to export')),
                  );
                  return;
                }

                if (value == 'pdf') {
                  await exportAnalysisToPDF(
                    payments: filteredPayments,
                    month: selectedMonth,
                    context: context,
                  );
                } else if (value == 'csv') {
                  await exportAnalysisToCSV(
                    payments: filteredPayments,
                    month: selectedMonth,
                    context: context,
                  );
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
                PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
              ],
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Top Paying'),
              Tab(text: 'Frequent Payers'),
              Tab(text: 'Inactive'),
              Tab(text: 'Methods'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Text('📅 Month:',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    dropdownColor: Colors.blueGrey[900],
                    style: const TextStyle(color: Colors.white),
                    value: selectedLabel,
                    items: months.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(m),
                      );
                    }).toList(),
                    onChanged: (value) {
                      final index = months.indexOf(value!);
                      final targetDate = DateTime(
                          DateTime.now().year, DateTime.now().month - index);
                      setState(() => selectedMonth = targetDate);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  TopPayingCustomers(payments: filteredPayments),
                  MostFrequentPayers(payments: filteredPayments),
                  InactiveCustomers(payments: filteredPayments),
                  PaymentMethodBreakdown(payments: filteredPayments),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}