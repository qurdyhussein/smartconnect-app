import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartconnect/metrics_card.dart';
import 'package:smartconnect/voucher_management_screen.dart';
import 'package:smartconnect/customer_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userStream = FirebaseFirestore.instance.collection('users').doc(uid).snapshots();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0,
        title: const Text(
          'SmartConnect Admin',
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.orange),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            color: Colors.orange,
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: Container(
        width: 220,
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.orange),
              child: Text('Admin Menu', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            _hoverTile(
              icon: Icons.dashboard,
              label: 'Dashboard',
              onTap: () {
                Navigator.pushNamed(context, '/dashboard');
              },
            ),
            _hoverTile(
              icon: Icons.people,
              label: 'Customers',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerManagementScreen()),
                );
              },
            ),
            _hoverTile(
              icon: Icons.vpn_key,
              label: 'Vouchers',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VoucherManagementScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/admin_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Container(color: Colors.black.withOpacity(0.4)),
          StreamBuilder<DocumentSnapshot>(
            stream: userStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final name = snapshot.data!['full_name'] ?? 'Admin';

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ListView(
                    children: [
                      Text(
                        'Welcome, $name 👋🏾',
                        style: const TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildMetricsSection(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    final now = DateTime.now();
    final twoDaysLater = now.add(const Duration(days: 2));

    final vouchersStream = FirebaseFirestore.instance.collection('vouchers').snapshots();
    final customersStream = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'customer')
        .snapshots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: customersStream,
          builder: (context, snapshot) {
            final total = snapshot.hasData ? snapshot.data!.docs.length : 0;

            return _buildCardGrid([
              MetricsCard(
                icon: Icons.people,
                label: 'Total Customers',
                count: total,
                color: Colors.orange,
              ),
            ]);
          },
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: vouchersStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            final total = docs.length;
            final assigned = docs.where((d) => d['status'] == 'assigned').length;
            final used = docs.where((d) => d['status'] == 'used').length;
            final expiringSoon = docs.where((d) {
              final expiry = (d['expiry'] as Timestamp).toDate();
              return expiry.isBefore(twoDaysLater) && expiry.isAfter(now);
            }).length;

            return _buildCardGrid([
              MetricsCard(
                icon: Icons.vpn_key,
                label: 'Total Vouchers',
                count: total,
                color: Colors.teal,
              ),
              MetricsCard(
                icon: Icons.assignment_ind,
                label: 'Assigned Vouchers',
                count: assigned,
                color: Colors.blueAccent,
              ),
              MetricsCard(
                icon: Icons.check_circle,
                label: 'Used Vouchers',
                count: used,
                color: Colors.green,
              ),
              MetricsCard(
                icon: Icons.warning_amber,
                label: 'Expiring Soon',
                count: expiringSoon,
                color: Colors.redAccent,
              ),
            ]);
          },
        ),
      ],
    );
  }

  Widget _buildCardGrid(List<Widget> cards) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.6,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }

  Widget _hoverTile({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.orange.shade100,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        leading: Icon(icon, color: Colors.black87),
        title: Text(label),
        dense: true,
      ),
    );
  }
}