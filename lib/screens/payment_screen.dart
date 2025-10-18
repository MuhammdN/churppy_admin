import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool saveCard = true;
  int selectedMethod = 0;
  int _userId = 0;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString("user");

    if (userString != null) {
      final userMap = jsonDecode(userString);
      _userId = userMap['id'];

      if (_userId != null) {
        final url =
            "https://churppy.eurekawebsolutions.com/api/user.php?id=$_userId";

        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success') {
            setState(() {
              _profileImageUrl = data['data']['image'];
            });
          }
        }
      }
    }
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString("user");
    if (userString != null) {
      final userMap = jsonDecode(userString);
      setState(() {
        _userId = userMap['id'] ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final scale = (w / 390).clamp(0.85, 1.25);
    double fs(double x) => x * scale;

    // Example static values (since no fields are passed now)
    final subtotal = 25.0;
    final taxes = subtotal * 0.1;
    final delivery = 1.50;
    final grandTotal = subtotal + taxes + delivery;

    return Scaffold(
      backgroundColor: const Color(0xfff9f9f9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(12)),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: h - fs(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔰 Top Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              size: fs(22),
                              color: Colors.black,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          SizedBox(width: fs(10)),
                          Image.asset("assets/images/logo.png",
                              height: fs(34)),
                        ],
                      ),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: fs(20),
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _profileImageUrl != null &&
                                _profileImageUrl!.startsWith("http")
                                ? NetworkImage(_profileImageUrl!)
                                : null,
                            child: (_profileImageUrl == null ||
                                !_profileImageUrl!.startsWith("http"))
                                ? Icon(
                              Icons.person,
                              size: fs(20),
                              color: Colors.grey[800],
                            )
                                : null,
                          ),
                          SizedBox(width: fs(10)),
                          Icon(Icons.search,
                              size: fs(22), color: Colors.black),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: fs(24)),

                  /// 🔶 Order Summary
                  Text("Order summary",
                      style: TextStyle(
                          fontSize: fs(16), fontWeight: FontWeight.bold)),
                  SizedBox(height: fs(12)),

                  _summaryRow("Order (1 item)",
                      "\$${subtotal.toStringAsFixed(2)}", fs),
                  _summaryRow("Taxes (10%)", "\$${taxes.toStringAsFixed(2)}", fs),
                  _summaryRow("Delivery fees", "\$${delivery.toStringAsFixed(2)}", fs),

                  Divider(height: fs(24)),
                  _summaryRow("Total:", "\$${grandTotal.toStringAsFixed(2)}", fs,
                      bold: true),

                  SizedBox(height: fs(10)),

                  Text("Estimated delivery time: 15 - 30mins",
                      style: TextStyle(fontSize: fs(11))),

                  SizedBox(height: fs(24)),

                  /// 💳 Payment Methods
                  Text("Payment methods",
                      style: TextStyle(
                          fontSize: fs(16), fontWeight: FontWeight.bold)),
                  SizedBox(height: fs(12)),

                  _paymentCard(
                    index: 0,
                    logo: "assets/images/p1.png",
                    title: "Credit card",
                    subtitle: "5105 •••• •••• 0505",
                    selected: selectedMethod == 0,
                    fs: fs,
                  ),
                  SizedBox(height: fs(12)),
                  _paymentCard(
                    index: 1,
                    logo: "assets/images/p2.png",
                    title: "Debit card",
                    subtitle: "3566 •••• •••• 0905",
                    selected: selectedMethod == 1,
                    fs: fs,
                  ),

                  SizedBox(height: fs(12)),

                  /// ☑️ Save Card Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: saveCard,
                        activeColor: Colors.green,
                        onChanged: (val) => setState(() => saveCard = val!),
                      ),
                      Expanded(
                        child: Text(
                          "Save card details for future payments",
                          style: TextStyle(fontSize: fs(12)),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: fs(40)),

                  /// 💲Total Price + Pay Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          style:
                          TextStyle(fontSize: fs(18), color: Colors.black),
                          children: [
                            const TextSpan(
                              text: "Total price\n",
                              style:
                              TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            TextSpan(
                              text: "\$${grandTotal.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 25),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_userId == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("⚠️ User not logged in"),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PaymentSuccessScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                              horizontal: fs(70), vertical: fs(25)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text("Pay Now",
                            style: TextStyle(
                                fontSize: fs(14), color: Colors.white)),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String title, String amount, double Function(double) fs,
      {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: fs(4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: fs(13),
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(amount,
              style: TextStyle(
                  fontSize: fs(13),
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _paymentCard({
    required int index,
    required String logo,
    required String title,
    required String subtitle,
    required bool selected,
    required double Function(double) fs,
  }) {
    return GestureDetector(
      onTap: () => setState(() => selectedMethod = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: fs(12), vertical: fs(10)),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff1e1e1e) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? Colors.transparent : Colors.grey.shade300),
          boxShadow: [
            if (!selected)
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
          ],
        ),
        child: Row(
          children: [
            Image.asset(logo, width: fs(38), height: fs(38)),
            SizedBox(width: fs(12)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: fs(13),
                    color: selected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: fs(12),
                    color: selected ? Colors.white70 : Colors.grey,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: fs(20),
              color: selected ? Colors.white : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ Dummy Payment Success Screen
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("✅ Payment Successful!",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
