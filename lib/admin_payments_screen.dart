import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'payments_graph.dart';
import 'export_helper.dart';
import 'pdf_export_helper.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  String searchQuery = '';
  DateTime currentMonth = DateTime.now();
  List<DocumentSnapshot> filteredPayments = [];

  Stream<QuerySnapshot> getPaymentsStream() {
    return FirebaseFirestore.instance
        .collection('payments')
        .orderBy('date', descending: true)
        .snapshots();
  }

  List<DocumentSnapshot> filterPayments(List<DocumentSnapshot> allDocs) {
    return allDocs.where((doc) {
      final name = doc['customer_name']?.toString().toLowerCase() ?? '';
      final date = (doc['date'] as Timestamp).toDate();
      final isSameMonth =
          date.month == currentMonth.month && date.year == currentMonth.year;
      return name.contains(searchQuery.toLowerCase()) && isSameMonth;
    }).toList();
  }

  Widget summaryTile(String label, String value, IconData icon, Color color) {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.25),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  const SizedBox(height: 4),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14)),
                ],
              ),
            )
          ],
        ),
      ),
    );
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
    final selectedMonth = DateFormat('MMMM yyyy').format(currentMonth);

    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      appBar: AppBar(
        title: const Text('Payments Dashboard'),
        backgroundColor: Colors.teal,
        actions: [
          PopupMenuButton<String>(
  icon: const Icon(Icons.download),
  onSelected: (value) async {
    if (filteredPayments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No payments to export.')),
      );
      return;
    }

    if (value == 'csv') {
      await exportPaymentsToCSV(filteredPayments, currentMonth, context);
    } else if (value == 'pdf') {
      await exportPaymentsToPDF(filteredPayments, currentMonth, context);
    }
  },
  itemBuilder: (context) => [
    const PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
    const PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
  ],
),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getPaymentsStream(),
        builder: (context, snapshot) {
          filteredPayments = snapshot.hasData
              ? filterPayments(snapshot.data!.docs)
              : [];
          final totalPaid = filteredPayments.fold<double>(
              0.0, (sum, doc) => sum + (doc['amount'] ?? 0.0));
          final uniqueCustomers = filteredPayments
              .map((doc) => doc['customer_id'])
              .toSet()
              .length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  summaryTile('Total Paid', 'TSh ${totalPaid.toStringAsFixed(0)}',
                      Icons.payments, Colors.tealAccent),
                  summaryTile('Customers Paid', '$uniqueCustomers',
                      Icons.people_alt, Colors.lightGreenAccent),
                ],
              ),
              const SizedBox(height: 8),
              summaryTile('Payments This Month', '${filteredPayments.length}',
                  Icons.calendar_today, Colors.orangeAccent),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by name',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) =>
                          setState(() => searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    dropdownColor: Colors.blueGrey[900],
                    style: const TextStyle(color: Colors.white),
                    value: selectedMonth,
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
                      setState(() => currentMonth = targetDate);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (filteredPayments.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text('No payments in this month.',
                      style: TextStyle(color: Colors.white54)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredPayments.length,
                  itemBuilder: (_, i) {
                    final data = filteredPayments[i];
                    final date = (data['date'] as Timestamp).toDate();
                    return Card(
                      color: Colors.teal.withOpacity(0.2),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.receipt,
                            color: Colors.white70),
                        title: Text(
                          '${data['customer_name']} - TSh ${data['amount']}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                        subtitle: Text(
                          '${DateFormat('dd MMM, h:mm a').format(date)} • ${data['method']}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 12),
              PaymentsGraph(selectedMonth: currentMonth),
            ],
          );
        },
      ),
    );
  }
}