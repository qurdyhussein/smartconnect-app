import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  double downloadMbps = 0.0;
  bool testing = false;

  Future<void> startTest() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection.')),
      );
      return;
    }

    setState(() {
      testing = true;
      downloadMbps = 0.0;
    });

    try {
      final url = Uri.parse('https://via.placeholder.com/1000x1000.jpg');
      final stopwatch = Stopwatch()..start();

      final response = await http.get(url);
      stopwatch.stop();

      if (response.statusCode == 200) {
        final int bytes = response.bodyBytes.length;
        final seconds = stopwatch.elapsedMilliseconds / 1000;
        final double bits = bytes * 8;
        final double mbps = (bits / seconds) / 1000000;

        setState(() => downloadMbps = mbps);

        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('speed_tests').add({
            'uid': uid,
            'download_speed': mbps,
            'upload_speed': 0.0,
            'tested_at': Timestamp.now(),
          });
        }
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speed test failed: $e')),
      );
    }

    setState(() => testing = false);
  }

  Stream<QuerySnapshot> getHistoryStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('speed_tests')
        .where('uid', isEqualTo: uid)
        .orderBy('tested_at', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      appBar: AppBar(
        title: const Text('Internet Speed Test'),
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _tile('Download Speed', '${downloadMbps.toStringAsFixed(2)} Mbps'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: testing ? null : startTest,
                icon: const Icon(Icons.network_check),
                label: Text(testing ? 'Testing...' : 'Start Test'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(color: Colors.white54),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.show_chart, color: Colors.white70, size: 20),
                      SizedBox(width: 6),
                      Text('Test History',
                          style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white70),
                    onPressed: () {
                      // Export history (optional)
                    },
                  )
                ],
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: getHistoryStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: CircularProgressIndicator(color: Colors.teal),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'No history yet.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i];
                      final testedAt =
                          (data['tested_at'] as Timestamp).toDate();
                      return Card(
                        color: Colors.teal.shade600.withOpacity(0.8),
                        child: ListTile(
                          title: Text(
                            '${data['download_speed'].toStringAsFixed(2)} Mbps ↓',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '$testedAt',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(String label, String value) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 18)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
}