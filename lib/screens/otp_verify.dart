import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'churppy_alert_plan.dart'; // After admin verifies OTP → Go to Plans

class AdminOTPVerifyScreen extends StatefulWidget {
  final String firstname, lastname, email, password, phone, address, businessName;

  const AdminOTPVerifyScreen({
    super.key,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.password,
    required this.phone,
    required this.address,
    required this.businessName,
  });

  @override
  State<AdminOTPVerifyScreen> createState() => _AdminOTPVerifyScreenState();
}

class _AdminOTPVerifyScreenState extends State<AdminOTPVerifyScreen> {
  final TextEditingController otpCtrl = TextEditingController();
  bool isLoading = false;
  bool isResending = false;

  // =================== VERIFY OTP ===================
  Future<void> verifyOTP() async {
    if (otpCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Please enter OTP")),
      );
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse("https://churppy.eurekawebsolutions.com/api/admin_verify_otp.php");
    final body = {
      "email": widget.email,
      "otp": otpCtrl.text.trim(),
      "firstname": widget.firstname,
      "lastname": widget.lastname,
      "password": widget.password,
      "user_phone": widget.phone,
      "address": widget.address,
      "business_name": widget.businessName,
    };

    try {
      final response = await http.post(url, body: body);
      final result = json.decode(response.body);

      print("📨 ADMIN VERIFY OTP => ${response.body}");

      if (result['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();

        // Store merchant_id
      final merchantId = result['user_id'].toString();

        
        await prefs.setString("user_id", merchantId);

        await prefs.setBool("isMerchantLoggedIn", true);

        if (!mounted) return;

        // Navigate to Plans Screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ChurppyPlansScreen()),
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${result['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // =================== RESEND OTP ===================
  Future<void> resendOTP() async {
    setState(() => isResending = true);

    final url = Uri.parse("https://churppy.eurekawebsolutions.com/api/resend_admin_otp.php");

    try {
      final response = await http.post(url, body: {"email": widget.email});
      final result = json.decode(response.body);

      print("📨 ADMIN RESEND OTP => ${response.body}");

      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ OTP resent successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${result['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error: $e")),
      );
    } finally {
      if (mounted) setState(() => isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final maxCardW = w.clamp(320.0, 440.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxCardW),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 30),

                    // =================== LOGO ===================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: maxCardW * 0.5,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              "Verify Your Email",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Enter the OTP sent to ${widget.email}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 30),

                            // =================== OTP INPUT ===================
                            TextField(
                              controller: otpCtrl,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                              ),
                              decoration: InputDecoration(
                                hintText: "Enter OTP",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF804692)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 16,
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),

                            // =================== VERIFY BUTTON ===================
                            SizedBox(
                              height: 48,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF804692),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: isLoading ? null : verifyOTP,
                                child: isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Verify OTP',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // =================== RESEND OTP ===================
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Didn't receive OTP? ",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: isResending ? null : resendOTP,
                                  child: Text(
                                    isResending ? "Sending..." : "Resend",
                                    style: const TextStyle(
                                      color: Color(0xFF804692),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =================== BACK BUTTON ===================
            Positioned(
              left: 10,
              top: 10,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE0E0E0),
                  ),
                  child: const Icon(Icons.arrow_back, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
