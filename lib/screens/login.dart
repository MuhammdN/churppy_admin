import 'dart:convert';
import 'package:churppy_admin/screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_picker/country_picker.dart'; // ✅ new package

import '../routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();

  Country? selectedCountry; // ✅ changed from manual flag/code

  bool isLoading = false;
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    // ✅ default = US 🇺🇸
    selectedCountry = Country(
      phoneCode: '1',
      countryCode: 'US',
      e164Sc: 0,
      geographic: true,
      level: 1,
      name: 'United States',
      example: '',
      displayName: 'United States',
      displayNameNoCountryCode: 'United States',
      e164Key: '',
    );
  }

  /// ✅ Validate Inputs (same logic)
  bool _validateInputs() {
    _errors.clear();

    if (phoneCtrl.text.trim().isNotEmpty) {
      if (!RegExp(r'^[0-9]{6,}$').hasMatch(phoneCtrl.text.trim())) {
        _errors['phone'] = "Enter a valid phone number";
      }
    } else {
      if (emailCtrl.text.trim().isEmpty) {
        _errors['email'] = "Email is required";
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
          .hasMatch(emailCtrl.text.trim())) {
        _errors['email'] = "Enter a valid email";
      }
    }

    if (passwordCtrl.text.trim().isEmpty) {
      _errors['password'] = "Password is required";
    } else if (passwordCtrl.text.trim().length < 6) {
      _errors['password'] = "Password must be at least 6 characters";
    }

    setState(() {});
    return _errors.isEmpty;
  }

  /// ✅ Admin Login API (unchanged)
  Future<void> _login() async {
    if (!_validateInputs()) return;

    setState(() => isLoading = true);
    final url = Uri.parse("https://churppy.eurekawebsolutions.com/api/admin_login.php");

    final requestBody = {
      if (phoneCtrl.text.trim().isNotEmpty)
        "phone_number": "+${selectedCountry?.phoneCode ?? '1'}${phoneCtrl.text.trim()}",
      if (phoneCtrl.text.trim().isEmpty)
        "email": emailCtrl.text.trim(),
      "password": passwordCtrl.text.trim(),
    };

    try {
      final response = await http.post(url, body: requestBody);
      print("🔗 API URL: $url");
      print("📤 Request Body: $requestBody");
      print("📥 Status Code: ${response.statusCode}");
      print("📥 Raw Response: ${response.body}");

      final result = json.decode(response.body);

      if (result['status'] == 'success') {
        final user = result['user'] ?? result['data'];
        if (user['role_id'].toString() == "3") {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("user_id", user['id'].toString());
          if (user['token'] != null) {
            await prefs.setString("token", user['token'].toString());
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Login successful!")),
          );
          Navigator.pushReplacementNamed(context, Routes.dashboard);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ You are not allowed to login.")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${result['message']}")),
        );
      }
    } catch (e) {
      print("⚠️ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to connect: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
  /// ✅ Forgot Password Handler
void _handleForgotPassword() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ForgotPasswordScreen(),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final isTablet = media.size.shortestSide >= 600;
    final contentMaxW = screenW.clamp(320.0, isTablet ? 560.0 : 440.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxW),
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 30),

                    /// 🔰 LOGO
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: contentMaxW * 0.5,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(minHeight: constraints.maxHeight),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Enter your mobile number',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        // ✅ replaced with country_picker
                                        InkWell(
                                          onTap: () => _showCountryPicker(context),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 12),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Color(0xFFBDBDBD)),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                Text(selectedCountry?.flagEmoji ?? '🌎',
                                                    style: const TextStyle(fontSize: 20)),
                                                const SizedBox(width: 6),
                                                Text('+${selectedCountry?.phoneCode ?? ''}',
                                                    style: const TextStyle(fontSize: 14)),
                                                const Icon(Icons.arrow_drop_down, size: 20),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: phoneCtrl,
                                            keyboardType: TextInputType.phone,
                                            decoration: InputDecoration(
                                              hintText: 'Phone Number',
                                              errorText: _errors['phone'],
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    _field("Email", emailCtrl,
                                        error: _errors['email']),
                                    _field("Password", passwordCtrl,
                                        obscure: true,
                                        error: _errors['password']),
                                    
 const SizedBox(height: 2),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _handleForgotPassword,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Color(0xFF804692),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                                    SizedBox(
                                      height: 48,
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF804692),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                        onPressed: isLoading ? null : _login,
                                        child: isLoading
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text('Continue'),
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    Center(
                                      child: GestureDetector(
                                        onTap: () => Navigator.pushReplacementNamed(
                                            context, Routes.signup),
                                        child: const Text.rich(
                                          TextSpan(
                                            text: "Don't have an account? ",
                                            style:
                                                TextStyle(color: Colors.black87),
                                            children: [
                                              TextSpan(
                                                text: 'Sign up.',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            ],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 12),
                                      child: Text(
                                        "Review terms and conditions. Changes, inappropriate language, and non-protocol use of our platform is prohibited. Violators will be banned and reported. Churppy is Trademark and Patent Pending.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController ctrl,
      {bool obscure = false, String? error}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          errorText: error,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: true, // ✅ shows +code
      onSelect: (Country country) {
        setState(() {
          selectedCountry = country;
        });
      },
    );
  }
}
