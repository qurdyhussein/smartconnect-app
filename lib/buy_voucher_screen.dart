import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuyVoucherScreen extends StatefulWidget {
  const BuyVoucherScreen({super.key});

  @override
  State<BuyVoucherScreen> createState() => _BuyVoucherScreenState();
}

class _BuyVoucherScreenState extends State<BuyVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedNetwork;
  String? customNetwork;
  String? selectedPackage;

  final List<String> packageOptions = [
    '2 hours',
    '6 hours',
    '12 hours',
    '24 hours',
    '3 days',
    'weekly',
    'monthly (1 device)',
    'monthly (2 devices)',
    'semester',
  ];

  final Map<String, int> packagePrices = {
    '2 hours': 500,
    '6 hours': 1000,
    '12 hours': 1500,
    '24 hours': 3000,
    '3 days': 4000,
    'weekly': 5000,
    'monthly (1 device)': 15000,
    'monthly (2 devices)': 20000,
    'semester': 35000,
  };

  List<String> networkOptions = [];
  bool isLoadingNetworks = true;

  @override
  void initState() {
    super.initState();
    _loadNetworks();
  }

  Future<void> _loadNetworks() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('networks').get();
      final names = snapshot.docs.map((doc) => doc['name'].toString()).toList();
      setState(() {
        networkOptions = [...names, 'Other'];
        isLoadingNetworks = false;
      });
    } catch (e) {
      setState(() => isLoadingNetworks = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to load networks: $e')),
      );
    }
  }

  void _proceedToPayment() {
    if (_formKey.currentState!.validate()) {
      final network = selectedNetwork == 'Other' ? customNetwork : selectedNetwork;
      final package = selectedPackage;
      final price = packagePrices[package]!;

      Navigator.pushNamed(
        context,
        '/payment',
        arguments: {
          'network': network,
          'package': package,
          'price': price,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Voucher'),
        backgroundColor: const Color(0xFFFF7043),
      ),
      body: isLoadingNetworks
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedNetwork,
                      decoration: const InputDecoration(labelText: 'Select Network'),
                      items: networkOptions.map((network) {
                        return DropdownMenuItem(value: network, child: Text(network));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedNetwork = val;
                          customNetwork = null;
                        });
                      },
                      validator: (val) => val == null ? 'Please select a network' : null,
                    ),
                    if (selectedNetwork == 'Other') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Enter Network Name'),
                        onChanged: (val) => customNetwork = val,
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Enter network name' : null,
                      ),
                    ],
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedPackage,
                      decoration: const InputDecoration(labelText: 'Select Package'),
                      items: packageOptions.map((pkg) {
                        return DropdownMenuItem(value: pkg, child: Text(pkg));
                      }).toList(),
                      onChanged: (val) => setState(() => selectedPackage = val),
                      validator: (val) => val == null ? 'Please select a package' : null,
                    ),
                    const SizedBox(height: 20),
                    if (selectedPackage != null)
                      Text(
                        'Price: TZS ${packagePrices[selectedPackage]}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _proceedToPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                        ),
                        child: const Text('Buy Now', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}