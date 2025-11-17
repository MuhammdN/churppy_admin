import 'dart:convert';
import 'package:churppy_admin/screens/receiptScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'contactUsScreen.dart';
import 'alertsListScreen.dart';
import 'drawer.dart';

class AlertPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> alertData;
  final Function onPaymentSuccess;

  const AlertPaymentScreen({
    super.key,
    required this.alertData,
    required this.onPaymentSuccess,
  });

  @override
  State<AlertPaymentScreen> createState() => _AlertPaymentScreenState();
}

class _AlertPaymentScreenState extends State<AlertPaymentScreen> {
  bool isLoading = false;
  bool _paymentCompleted = false;

  String? userId;
  String? profileImage;
  bool profileLoading = true;

  final double churppyAmount = 16;
  final double pdfUploadAmount = 20;
  final double cardFee = 2;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("user_id");

    if (userId != null) {
      await fetchUserProfile();
    }
  }

  Future<void> fetchUserProfile() async {
    final url = Uri.parse(
        "https://churppy.eurekawebsolutions.com/api/user.php?id=$userId");

    try {
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data["status"] == "success") {
        profileImage = data["data"]["image"];
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => profileLoading = false);
  }

  Future<String?> createPaymentIntent(double amount) async {
    try {
      final url = Uri.parse(
          "https://churppy.eurekawebsolutions.com/api/create_payment_intent.php");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": (amount * 100).toInt(),
          "currency": "usd",
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)["client_secret"];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> openPaymentSheet(double totalAmount) async {
    if (!mounted || _paymentCompleted) return;

    setState(() => isLoading = true);

    final clientSecret = await createPaymentIntent(totalAmount);

    if (clientSecret == null) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showSnack("Payment Intent creation failed");
      return;
    }

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: "Churppy",
          paymentIntentClientSecret: clientSecret,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      setState(() {
        _paymentCompleted = true;
        isLoading = false;
      });

      await updateAlertAfterPayment();

      widget.onPaymentSuccess();

      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 500));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => AlertsListScreen(userId: userId!),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        _paymentCompleted = false;
      });

      if (e is StripeException && e.error.code == FailureCode.Canceled) {
        showSnack("Payment cancelled.");
        return;
      }

      showSnack("Payment failed. Please try again.");
    }
  }

  Future<void> updateAlertAfterPayment() async {
    final url = Uri.parse(
        "https://churppy.eurekawebsolutions.com/api/update_alert_payment.php");

    final alert = widget.alertData;

    final response = await http.post(url, body: {
      "alert_id": alert['id'].toString(),
      "merchant_id": alert['merchant_id'].toString(),
      "location": alert['location'],
      "start_date": alert['start_date'],
      "expiry_date": alert['expiry_date'],
      "start_time": alert['start_time'],
      "end_time": alert['end_time'],
      "alert_type": alert["alert_type"] ?? "churppy",
      "radius": alert["alert_radius"]?.toString() ?? "5",
    });

    final data = jsonDecode(response.body);

    if (data["status"] != "success") {
      throw Exception(data["message"]);
    }
  }

  void showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double total = churppyAmount + pdfUploadAmount + cardFee;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const ChurppyDrawer(),

      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ⭐ HEADER
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Builder(
                            builder: (ctx) => GestureDetector(
                              onTap: () => Scaffold.of(ctx).openDrawer(),
                              child: Image.asset(
                                "assets/icons/menu.png",
                                height: 40,
                                width: 40,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Image.asset("assets/images/logo.png",
                              height: 40, fit: BoxFit.contain),
                        ],
                      ),

                      profileLoading
                          ? const CircularProgressIndicator()
                          : profileImage != null
                              ? ClipOval(
                                  child: Image.network(
                                    profileImage!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.person, size: 40),
                    ],
                  ),
                ),

                // ⭐ PAYMENT TITLE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Image.asset("assets/images/bell_churppy.png", height: 70),
                      const SizedBox(width: 10),
                      Text(
                        "PAYMENT",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // ⭐ PRICE DETAILS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        priceItem("Churppy Alert", "\$${churppyAmount.toString()}"),
                        priceItem("PDF Upload", "\$${pdfUploadAmount.toString()}"),
                        priceItem("Credit Card Fee", "\$${cardFee.toString()}"),
                        const Divider(),
                        priceItem(
                          "TOTAL:",
                          "\$${total.toString()}",
                          bold: true,
                          big: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ⭐ PAY BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : payButton(() => openPaymentSheet(total)),
                ),

                const SizedBox(height: 20),

                // ⭐ CONTACT US BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 120),
                  child: contactButton(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                    );
                  }),
                ),
              ],
            ),

            // ⭐ BOTTOM LEFT CIRCULAR BACK ARROW
            Positioned(
              bottom: 20,
              left: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.07),
                  ),
                  child: const Icon(Icons.arrow_back, size: 26),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget priceItem(String left, String right,
      {bool bold = false, bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left,
              style: GoogleFonts.poppins(
                fontSize: big ? 17 : 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              )),
          Text(right,
              style: GoogleFonts.poppins(
                fontSize: big ? 20 : 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget payButton(VoidCallback onTap) {
    return SizedBox(
      height: 65,
      child: Card(
        elevation: 1.5,
        child: TextButton(
          onPressed: onTap,
          child: Text(
            "Pay/Send Churppy Alert",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget contactButton(VoidCallback onTap) {
    return SizedBox(
      height: 65,
      child: Card(
        color: Colors.red.shade50,
        child: TextButton(
          onPressed: onTap,
          child: Text(
            "Contact Us",
            style: GoogleFonts.poppins(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
