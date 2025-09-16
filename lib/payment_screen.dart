import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartconnect/payment_service.dart';
import 'package:smartconnect/payment_webview.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late String network;
  late String package;
  late int price;

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'name': 'M-Pesa',
      'image': 'assets/payments/mpesa_card.png',
      'color': Color(0xFF1FBF3F),
    },
    {
      'name': 'Tigo Pesa',
      'image': 'assets/payments/tigo_card.png',
      'color': Color(0xFF2E3192),
    },
    {
      'name': 'Airtel Money',
      'image': 'assets/payments/airtel_card.png',
      'color': Color(0xFFE60000),
    },
    {
      'name': 'HaloPesa',
      'image': 'assets/payments/halopesa_card.png',
      'color': Color(0xFFFAA61A),
    },
  ];

  int selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.75);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    network = args['network'];
    package = args['package'];
    price = args['price'];
  }

  void _payNow() async {
    final selectedMethod = paymentMethods[selectedIndex]['name'];
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final phone = _phoneController.text.trim();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Initiating Pesapal payment...')),
      );

      final redirectUrl = await PaymentService.initiatePaymentViaBackend(
        phone: phone,
        amount: price
        
      );

      if (redirectUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed. Please try again.')),
        );
        return;
      }

      print('🌐 Redirect to: $redirectUrl');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebView(url: redirectUrl),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFFF3F4F6);
    final selectedMethod = paymentMethods[selectedIndex]['name'];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF512DA8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Payment', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Network: $network', style: const TextStyle(fontSize: 16)),
                      Text('Package: $package', style: const TextStyle(fontSize: 16)),
                      Text('Price: TZS $price',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Choose Payment Method',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: paymentMethods.length,
                    onPageChanged: (index) => setState(() => selectedIndex = index),
                    itemBuilder: (context, index) {
                      final method = paymentMethods[index];
                      final isSelected = index == selectedIndex;
                      final scale = isSelected ? 1.0 : 0.9;

                      return TweenAnimationBuilder(
                        tween: Tween<double>(begin: scale, end: scale),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white,
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: method['color'].withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 6),
                                    ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  method['image'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Enter Phone Number',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 0712345678',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (!RegExp(r'^0[67][0-9]{7,8}$').hasMatch(val)) {
                      return 'Enter a valid Tanzanian number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _payNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Pay Now',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
