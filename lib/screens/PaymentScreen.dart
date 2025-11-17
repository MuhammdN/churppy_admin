import 'dart:convert';
import 'dart:io';
import 'package:churppy_admin/screens/contactUsScreen.dart';
import 'package:churppy_admin/screens/profile.dart';
import 'package:churppy_admin/screens/receiptScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import 'drawer.dart';
import 'location.dart'; // ✅ for AlertModel

class PaymentScreen extends material.StatefulWidget {
  final AlertModel? alert; // ✅ Alert coming from previous screen
  final int? status; // ✅ Added for 1 (Approve) / 0 (Save for Later)

  const PaymentScreen({super.key, this.alert, this.status});

  @override
  material.State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends material.State<PaymentScreen> {
  bool isLoading = false;
  String? userId;

  // ✅ For profile image
  String? profileImage;
  String? firstName;
  String? lastName;
  bool _profileLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();

    // ✅ Print the status coming from previous screen
    debugPrint("🟩 Status received from previous screen: ${widget.status}");
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString("user_id");
    setState(() => userId = savedUserId);
    debugPrint("✅ SharedPref User ID (PaymentScreen): $savedUserId");

    if (savedUserId != null) {
      await _fetchUserProfile(savedUserId);
    }
  }

  /// ✅ Fetch User Profile
  Future<void> _fetchUserProfile(String uid) async {
    final url = Uri.parse("https://churppy.eurekawebsolutions.com/api/user.php?id=$uid");
    try {
      final res = await http.get(url);
      debugPrint("📥 Profile Response (PaymentScreen): ${res.body}");

      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);
        if (result["status"] == "success") {
          final data = result["data"];
          setState(() {
            profileImage = data["image"];
            firstName = data["first_name"];
            lastName = data["last_name"];
            _profileLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("⚠️ Profile Fetch Error (PaymentScreen): $e");
      setState(() => _profileLoading = false);
    }
  }

  /// ✅ Create PaymentIntent
  Future<String?> _createPaymentIntent(int amount) async {
    try {
      final url = Uri.parse("https://churppy.eurekawebsolutions.com/api/create_payment_intent.php");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"amount": amount, "currency": "usd"}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["client_secret"];
      } else {
        debugPrint("❌ Status: ${response.statusCode}");
        debugPrint("❌ Body: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
      return null;
    }
  }

  /// ✅ After Payment Success
  Future<void> _afterPaymentSuccess() async {
    if (userId == null) return;

    // ---- Update merchant amount ----
    final response = await http.post(
      Uri.parse("https://churppy.eurekawebsolutions.com/api/update_amount.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "merchant_id": userId,
        "amount": 38,
      }),
    );

    final data = jsonDecode(response.body);
    debugPrint("📥 Update Amount Response: $data");

    if (data["status"] != "success") {
      material.ScaffoldMessenger.of(context).showSnackBar(
        material.SnackBar(content: material.Text("DB update failed: ${data['message']}")),
      );
      return;
    }

    // ---- Insert alert if present → force_create skip limits ----
    if (widget.alert != null) {
      final alert = widget.alert!;
      final uri = Uri.parse("https://churppy.eurekawebsolutions.com/api/admin_add_alert.php");
      final req = http.MultipartRequest('POST', uri);

      debugPrint("📦 Sending alert with status: ${widget.status}");

      req.fields.addAll({
        'merchant_id': userId!,
        'title': alert.title,
        'description': alert.description,
        'location': alert.location,
        'start_date': alert.startDate,
        'expiry_date': alert.expiryDate,
        'start_time': alert.startTime,
        'end_time': alert.endTime,
        'radius': alert.radius.toString(),
        'status': widget.status?.toString() ?? '1', // ✅ Use status from previous screen
        'alert_type': alert.alertType,
        'force_create': '1',
      });

      if (alert.imageName.isNotEmpty) {
        final file = File(alert.imageName);
        if (file.existsSync()) {
          final mimeType = lookupMimeType(file.path);
          req.files.add(await http.MultipartFile.fromPath(
            'image',
            file.path,
            contentType: mimeType != null ? MediaType.parse(mimeType) : null,
          ));
        } else {
          req.fields['existing_image'] = alert.imageName.split('/').last;
        }
      }

      final sendResp = await req.send();
      final sendBody = await sendResp.stream.bytesToString();
      debugPrint("📩 Alert Insert Response: $sendBody");
    }

    material.ScaffoldMessenger.of(context).showSnackBar(
      const material.SnackBar(content: material.Text("✅ Payment successful!")),
    );

    Navigator.pushAndRemoveUntil(
      context,
      material.MaterialPageRoute(builder: (context) => const ReceiptScreen()),
      (route) => false,
    );
  }

  /// ✅ Handle Payment Flow
  Future<void> _handlePayment() async {
    setState(() => isLoading = true);

    final clientSecret = await _createPaymentIntent(3800);

    if (clientSecret == null) {
      setState(() => isLoading = false);
      material.ScaffoldMessenger.of(context).showSnackBar(
        const material.SnackBar(content: material.Text("Payment Intent creation failed")),
      );
      return;
    }

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Churppy',
          style: material.ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      await _afterPaymentSuccess();
      setState(() => isLoading = false);
   } catch (e) {
  setState(() => isLoading = false);

  // CHECK IF USER CANCELLED PAYMENT SHEET
  if (e is StripeException && e.error.code == FailureCode.Canceled) {
    material.ScaffoldMessenger.of(context).showSnackBar(
      const material.SnackBar(
        content: material.Text(
          "Payment cancelled",
          style: material.TextStyle(color: material.Colors.white),
        ),
        backgroundColor: material.Colors.orange,
        behavior: material.SnackBarBehavior.floating,
      ),
    );
    return;
  }

  // ANY OTHER PAYMENT ERROR
  material.ScaffoldMessenger.of(context).showSnackBar(
    material.SnackBar(
      content: material.Text("❌ Payment failed: $e"),
      backgroundColor: material.Colors.red,
      behavior: material.SnackBarBehavior.floating,
    ),
  );
}
  }

  @override
  material.Widget build(material.BuildContext context) {
    return material.Scaffold(
      backgroundColor: material.Colors.white,
      drawer: const ChurppyDrawer(),
      body: material.SafeArea(
        child: material.Column(
          children: [
            // ===== Scrollable Content =====
            Expanded(
              child: material.SingleChildScrollView(
                child: material.Column(
                  children: [
                    // ===== Header - SAME UI =====
                    material.Padding(
                      padding: const material.EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                      child: material.Row(
                        mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
                        children: [
                          material.Row(
                            children: [
                              Builder(
                                builder: (ctx) => GestureDetector(
                                  onTap: () => material.Scaffold.of(ctx).openDrawer(),
                                  child: material.Image.asset('assets/icons/menu.png', width: 40, height: 40),
                                ),
                              ),
                              const material.SizedBox(width: 10),
                              material.Image.asset('assets/images/logo.png',
                                  width: 100, height: 40, fit: material.BoxFit.contain),
                            ],
                          ),
                          _profileLoading
                              ? const material.CircularProgressIndicator()
                              : material.GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      material.MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                    );
                                  },
                                  child: profileImage != null
                                      ? material.ClipOval(
                                          child: material.Image.network(
                                            profileImage!,
                                            width: 50,
                                            height: 50,
                                            fit: material.BoxFit.cover,
                                            errorBuilder: (c, o, s) =>
                                                const material.Icon(material.Icons.person, size: 30),
                                          ),
                                        )
                                      : const material.Icon(material.Icons.person, size: 40),
                                ),
                        ],
                      ),
                    ),

                    // ===== Heading =====
                    material.Padding(
                      padding: const material.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: material.Row(
                        children: [
                          material.Image.asset('assets/images/bell_churppy.png', height: 60, width: 60),
                          const material.SizedBox(width: 10),
                          const material.Text(
                            "PAYMENT",
                            style: material.TextStyle(
                                fontSize: 20,
                                fontWeight: material.FontWeight.bold,
                                fontStyle: material.FontStyle.italic,
                                color: material.Colors.black),
                          ),
                        ],
                      ),
                    ),

                    // ===== Step Info =====
                    const material.Padding(
                      padding: material.EdgeInsets.only(top: 5, bottom: 10),
                      child: material.Column(
                        crossAxisAlignment: material.CrossAxisAlignment.start,
                        children: [
                          material.Text("Pay and Send Churppy Alert",
                              style: material.TextStyle(fontSize: 18, fontWeight: material.FontWeight.w600)),
                          material.SizedBox(height: 8),
                          material.Text("Current Plan: Single Use",
                              style: material.TextStyle(
                                  fontSize: 14,
                                  color: material.Colors.black,
                                  fontWeight: material.FontWeight.bold)),
                        ],
                      ),
                    ),

                    // ===== Payment Details =====
                    material.Padding(
                      padding: const material.EdgeInsets.symmetric(horizontal: 20),
                      child: material.Container(
                        padding: const material.EdgeInsets.all(16),
                        child: material.Column(
                          children: [
                            _rowText("Churppy Alert", "\$16"),
                            _rowText("PDF upload", "20"),
                            _rowText("Credit Card Fee", "2"),
                            const material.Divider(thickness: 1),
                            _rowText("TOTAL:", "\$38",
                                isBold: true, color: material.Colors.black),
                            const material.SizedBox(height: 10),
                            const material.Text("Credit Card On File or Add New Card",
                                style: material.TextStyle(fontSize: 13, color: material.Colors.black87)),
                          ],
                        ),
                      ),
                    ),

                    const material.SizedBox(height: 20),

                    // ===== Pay Button =====
                    material.Padding(
                      padding: const material.EdgeInsets.symmetric(horizontal: 60, vertical: 2),
                      child: isLoading
                          ? const material.CircularProgressIndicator()
                          : _styledButton("Pay/Send Churppy Alert", material.Colors.black, _handlePayment),
                    ),

                    const material.SizedBox(height: 20),

                    // ===== Contact Us Button =====
                    material.Padding(
                      padding: const material.EdgeInsets.symmetric(horizontal: 120, vertical: 20),
                      child: _styledButton(
                        "Contact Us",
                        material.Colors.red,
                        () {
                          Navigator.push(
                            context,
                            material.MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                          );
                        },
                      ),
                    ),

                    const material.SizedBox(height: 20),

                    // ===== Customize Alerts Link =====
                    material.Center(
                      child: material.TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            material.MaterialPageRoute(builder: (_) => const ReceiptScreen()),
                          );
                        },
                        child: const material.Text.rich(
                          material.TextSpan(
                            children: [
                              material.TextSpan(
                                text: "TRY CUSTOMIZE ALERTS",
                                style: material.TextStyle(
                                    color: material.Colors.purple,
                                    fontWeight: material.FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// 🔰 Back Arrow Section
            material.Container(
              color: material.Colors.white,
              padding: const material.EdgeInsets.only(left: 16, top: 10, bottom: 16),
              width: double.infinity,
              child: material.Row(
                children: [
                  material.CircleAvatar(
                    backgroundColor: material.Colors.grey[300],
                    child: material.IconButton(
                      icon: const material.Icon(material.Icons.arrow_back, color: material.Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Row Widget for Payment Items
  material.Widget _rowText(String left, String right,
      {bool isBold = false, material.Color color = material.Colors.black87}) {
    return material.Padding(
      padding: const material.EdgeInsets.symmetric(vertical: 4),
      child: material.Row(
        mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
        children: [
          material.Text(left,
              style: material.TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? material.FontWeight.bold : material.FontWeight.normal,
                  color: color)),
          material.Text(right,
              style: material.TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? material.FontWeight.bold : material.FontWeight.normal,
                  color: color)),
        ],
      ),
    );
  }

  material.Widget _styledButton(
      String text, material.Color color, material.VoidCallback onTap) {
    return material.SizedBox(
      width: double.infinity,
      height: 70,
      child: material.Card(
        elevation: 1.5,
        shape: material.RoundedRectangleBorder(
          borderRadius: material.BorderRadius.circular(6),
        ),
        child: material.TextButton(
          onPressed: onTap,
          child: material.Text(
            text,
            style: material.TextStyle(
              fontWeight: material.FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
