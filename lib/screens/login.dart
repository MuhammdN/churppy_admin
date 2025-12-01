import 'dart:convert';
import 'package:churppy_admin/screens/churppy_alert_plan.dart';
import 'package:churppy_admin/screens/forgot_password_screen.dart';
import 'package:churppy_admin/screens/google_login_service.dart.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_picker/country_picker.dart';

import '../routes.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();

  Country? selectedCountry;
  bool isLoading = false;
  bool socialLoading = false;

  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
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

  // ------------------ VALIDATION ------------------
  bool _validateInputs() {
    _errors.clear();

    if (phoneCtrl.text.trim().isNotEmpty) {
      if (!RegExp(r'^[0-9]{6,}$').hasMatch(phoneCtrl.text.trim())) {
        _errors['phone'] = "Enter a valid phone number";
      }
    } else {
      if (emailCtrl.text.trim().isEmpty) {
        _errors['email'] = "Email is required";
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailCtrl.text.trim())) {
        _errors['email'] = "Enter a valid email";
      }
    }

    if (passwordCtrl.text.trim().isEmpty) {
      _errors['password'] = "Password is required";
    } else if (passwordCtrl.text.length < 6) {
      _errors['password'] = "Password must be at least 6 characters";
    }

    setState(() {});
    return _errors.isEmpty;
  }

  // ------------------ NORMAL LOGIN ------------------
  Future<void> _login() async {
    if (!_validateInputs()) return;

    setState(() => isLoading = true);

    final url = Uri.parse("https://churppy.eurekawebsolutions.com/api/admin_login.php");

    final requestBody = {
      if (phoneCtrl.text.trim().isNotEmpty)
        "phone_number": "+${selectedCountry?.phoneCode}${phoneCtrl.text.trim()}",
      if (phoneCtrl.text.trim().isEmpty) "email": emailCtrl.text.trim(),
      "password": passwordCtrl.text.trim(),
    };

    try {
      final response = await http.post(url, body: requestBody);
      final result = json.decode(response.body);

      if (result['status'] == 'success') {
        final user = result['user'] ?? result['data'];

        if (user['role_id'].toString() == "3") {
          final prefs = await SharedPreferences.getInstance();

          await prefs.setString("admin", jsonEncode(user));
          await prefs.setString("user_id", user['id'].toString());

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ------------------ SOCIAL LOGIN BACKEND ------------------
  Future<void> _handleSocialBackend(Map<String, dynamic> social) async {
    setState(() => socialLoading = true);

    final url = Uri.parse(
      "https://churppy.eurekawebsolutions.com/api/social_login_admin.php",
    );

    final cleanBody = social.map((key, value) => MapEntry(key, value ?? ""));

    try {
      final response = await http.post(url, body: cleanBody);
      final result = json.decode(response.body);

      if (result['status'] == 'success') {
        final user = result['data'];
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString("admin", jsonEncode(user));
        await prefs.setString("user_id", user['id'].toString());

        // ------------------------------------
        // ⭐ CHECK IF NEW USER CREATED
        // ------------------------------------
        final msg = result['message'].toString().toLowerCase();

        if (msg.contains("created")) {
          // NEW USER → plans screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ChurppyPlansScreen()),
          );
          return;
        }

        // EXISTING USER → dashboard
        Navigator.pushReplacementNamed(context, Routes.dashboard);

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${result['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Login Failed: $e")),
      );
    } finally {
      setState(() => socialLoading = false);
    }
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final contentMaxW = screenW.clamp(320.0, 480.0);

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
                    const SizedBox(height: 35),
                    Image.asset("assets/images/logo.png", width: contentMaxW * 0.5),
                    const SizedBox(height: 35),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Enter your mobile number',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                InkWell(
                                  onTap: () => _showCountryPicker(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Color(0xFFBDBDBD)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(selectedCountry?.flagEmoji ?? '🌎',
                                            style: const TextStyle(fontSize: 20)),
                                        const SizedBox(width: 6),
                                        Text('+${selectedCountry?.phoneCode ?? ''}',
                                            style: const TextStyle(fontSize: 14)),
                                        const Icon(Icons.arrow_drop_down, size: 18),
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
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            _field("Email", emailCtrl, error: _errors['email']),
                            _field("Password", passwordCtrl,
                                obscure: true, error: _errors['password']),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const ForgotPasswordScreen()),
                                  );
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Color(0xFF804692),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ---------------- GOOGLE LOGIN ----------------
                            _socialButton(
                              icon: "assets/images/google.png",
                              text: "Continue with Google",
                              onTap: () async {
                                final data =
                                    await SocialAuthService.loginWithGoogle();
                                if (data != null) _handleSocialBackend(data);
                              },
                            ),

                            const SizedBox(height: 12),

                            // ---------------- APPLE LOGIN ----------------
                            _socialButton(
                              icon: "assets/images/apple.png",
                              text: "Continue with Apple",
                              onTap: () async {
                                final data =
                                    await SocialAuthService.loginWithApple();
                                if (data != null) _handleSocialBackend(data);
                              },
                            ),

                            const SizedBox(height: 20),

                            // ---------------- SUBMIT LOGIN BUTTON ----------------
                            SizedBox(
                              height: 48,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF804692),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: isLoading ? null : _login,
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white)
                                    : const Text('Continue'),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SignupScreen(),
                                    ),
                                  );
                                },
                                child: const Text.rich(
                                  TextSpan(
                                    text: "Don’t have an account? ",
                                    style: TextStyle(color: Colors.black87),
                                    children: [
                                      TextSpan(
                                        text: "Sign Up",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                          color: Color(0xFF804692),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
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

  // ------------------ WIDGET HELPERS ------------------
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
        ),
      ),
    );
  }

  Widget _socialButton({
    required String icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF804692), width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: socialLoading ? null : onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(icon, height: 24),
            const SizedBox(width: 10),
            Text(text),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() => selectedCountry = country);
      },
    );
  }
}
