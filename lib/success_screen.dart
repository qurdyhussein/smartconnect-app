import 'package:flutter/material.dart';
import 'package:smartconnect/booking_status_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SuccessScreen extends StatefulWidget {
  final String orderTrackingId;
  final String network;
  final String package;

  const SuccessScreen({
    super.key,
    required this.orderTrackingId,
    required this.network,
    required this.package,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  String? _statusMessage;
  bool _isLoading = true;
  String? _voucherCode;
  DateTime? _expiry;

  @override
  void initState() {
    super.initState();
    _checkAndAssignVoucher();
  }

  Duration getExpiryDuration(String package) {
    switch (package.toLowerCase()) {
      case '2 hours':
        return const Duration(hours: 2);
      case 'daily':
        return const Duration(days: 1);
      case 'weekly':
        return const Duration(days: 7);
      case 'monthly':
        return const Duration(days: 30);
      case 'semester':
        return const Duration(days: 180);
      default:
        return const Duration(hours: 6);
    }
  }

  Future<void> _checkAndAssignVoucher() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _statusMessage = "User not logged in.";
        _isLoading = false;
      });
      return;
    }

    final status = await BookingStatusService.checkStatus(widget.orderTrackingId);

    if (status == "COMPLETED") {
      try {
        final query = await FirebaseFirestore.instance
            .collection('vouchers')
            .where('status', isEqualTo: 'available')
            .where('network', isEqualTo: widget.network)
            .where('package', isEqualTo: widget.package)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          setState(() {
            _statusMessage = "No available voucher found.";
            _isLoading = false;
          });
          return;
        }

        final doc = query.docs.first;
        final docRef = doc.reference;

        final expiryDuration = getExpiryDuration(widget.package);
        final expiryTime = DateTime.now().add(expiryDuration);

        await docRef.update({
          'status': 'assigned',
          'assigned_to': uid,
          'assigned_at': FieldValue.serverTimestamp(),
          'expiry': expiryTime,
        });

        setState(() {
          _voucherCode = doc['code'];
          _expiry = expiryTime;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _statusMessage = "Error assigning voucher: $e";
          _isLoading = false;
        });
      }
    } else if (status == "PENDING") {
      setState(() {
        _statusMessage = "Malipo yako yanashughulikiwa...";
        _isLoading = false;
      });
    } else {
      setState(() {
        _statusMessage = "Malipo hayakufanikiwa.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF512DA8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Payment Status', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const CircularProgressIndicator()
              : _voucherCode != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 80),
                        const SizedBox(height: 20),
                        const Text('Voucher Assigned!',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text('Code: $_voucherCode',
                            style: const TextStyle(fontSize: 20, color: Colors.deepPurple)),
                        const SizedBox(height: 8),
                        Text('Network: ${widget.network}'),
                        Text('Package: ${widget.package}'),
                        Text('Expires: ${_expiry?.toLocal()}'),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: const Text('Done', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  : Text(
                      _statusMessage ?? "Unknown status",
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
        ),
      ),
    );
  }
}