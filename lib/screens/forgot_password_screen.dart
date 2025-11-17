import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Controllers
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController otpCtrl = TextEditingController();
  final TextEditingController newPasswordCtrl = TextEditingController();
  final TextEditingController confirmPasswordCtrl = TextEditingController();

  // State
  bool isLoading = false;
  bool isOTPSent = false;
  bool isOTPVerified = false;
  final Map<String, String?> _errors = {};

  // -------------------- API URLs --------------------
  final String apiSendOTP = "https://churppy.eurekawebsolutions.com/api/send_reset_otp.php";
  final String apiVerifyOTP = "https://churppy.eurekawebsolutions.com/api/verify_reset_otp.php";
  final String apiUpdatePassword = "https://churppy.eurekawebsolutions.com/api/update_password.php";

  // -------------------- Validation --------------------
  bool _validateEmail() {
    _errors.clear();
    if (emailCtrl.text.trim().isEmpty) {
      _errors['email'] = "Email is required";
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailCtrl.text.trim())) {
      _errors['email'] = "Enter a valid email";
    }
    setState(() {});
    return _errors.isEmpty;
  }

  bool _validateOTP() {
    _errors.clear();
    if (otpCtrl.text.trim().isEmpty) {
      _errors['otp'] = "OTP is required";
    } else if (otpCtrl.text.trim().length < 4) {
      _errors['otp'] = "Enter valid OTP";
    }
    setState(() {});
    return _errors.isEmpty;
  }

  bool _validatePassword() {
    _errors.clear();
    if (newPasswordCtrl.text.isEmpty) {
      _errors['password'] = "Password is required";
    } else if (newPasswordCtrl.text.length < 6) {
      _errors['password'] = "Password must be at least 6 characters";
    }
    if (confirmPasswordCtrl.text.isEmpty) {
      _errors['confirm_password'] = "Please confirm your password";
    } else if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
      _errors['confirm_password'] = "Passwords do not match";
    }
    setState(() {});
    return _errors.isEmpty;
  }

  // -------------------- API Calls --------------------
  Future<void> _sendOTP() async {
    if (!_validateEmail()) return;
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiSendOTP),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"email": emailCtrl.text.trim()}),
      );

      if (response.body.isEmpty) throw "Empty response from server";

      final result = json.decode(response.body);
      if (result['status'] == 'success') {
        setState(() => isOTPSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "OTP sent successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Failed to send OTP")),
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

  Future<void> _verifyOTP() async {
    if (!_validateOTP()) return;
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiVerifyOTP),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": emailCtrl.text.trim(),
          "otp": otpCtrl.text.trim(),
        }),
      );

      if (response.body.isEmpty) throw "Empty response from server";

      final result = json.decode(response.body);
      if (result['status'] == 'success') {
        setState(() => isOTPVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "OTP verified")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Invalid OTP")),
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

  Future<void> _resetPassword() async {
    if (!_validatePassword()) return;
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUpdatePassword),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": emailCtrl.text.trim(),
          "otp": otpCtrl.text.trim(), // optional if backend verifies OTP separately
          "password": newPasswordCtrl.text.trim(),
        }),
      );

      if (response.body.isEmpty) throw "Empty response from server";

      final result = json.decode(response.body);
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Password updated successfully")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Failed to update password")),
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

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final maxCardW = w.clamp(320.0, 440.0);

    return Scaffold(
      backgroundColor: Colors.white,
      
      appBar: AppBar(
  backgroundColor: Colors.white,
  foregroundColor: const Color(0xFF804692),
  elevation: 0,
  centerTitle: true, // Centers the title
  toolbarHeight: 80, // Change this value to adjust AppBar height
  title: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Image.asset(
      'assets/images/logo.png',
      width: maxCardW * 0.5,
      fit: BoxFit.contain,
    ),
  ),
),


      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCardW),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.lock_reset, size: 80, color: const Color(0xFF804692).withOpacity(0.8)),
                  const SizedBox(height: 20),
                  const Text(
                    'Reset Your Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF804692)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your email and follow the steps to reset your password',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
                  ),
                  const SizedBox(height: 32),
                  _buildEmailSection(),
                  if (isOTPSent) _buildOTPSection(),
                  if (isOTPVerified) _buildPasswordSection(),
                  const SizedBox(height: 24),
                  _buildActionButton(),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text.rich(
                        TextSpan(
                          text: "Remember your password? ",
                          style: TextStyle(color: Colors.black87),
                          children: [
                            TextSpan(
                              text: 'Back to Login',
                              style: TextStyle(
                                color: Color(0xFF804692),
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
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
        ),
      ),
    );
  }

  // -------------------- UI Sections --------------------
  Widget _buildEmailSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Email Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            enabled: !isOTPSent,
            decoration: InputDecoration(
              hintText: 'Enter your email',
              errorText: _errors['email'],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          if (!isOTPSent) const Text('We will send a verification code to this email', style: TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      );

  Widget _buildOTPSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text('Verification Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: otpCtrl,
            keyboardType: TextInputType.number,
            enabled: !isOTPVerified,
            decoration: InputDecoration(
              hintText: 'Enter OTP',
              errorText: _errors['otp'],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: const Icon(Icons.sms_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          if (!isOTPVerified) const Text('Check your email for the 6-digit code', style: TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      );

  Widget _buildPasswordSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text('New Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: newPasswordCtrl,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Enter new password',
              errorText: _errors['password'],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Confirm Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: confirmPasswordCtrl,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Re-enter new password',
              errorText: _errors['confirm_password'],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Password must be at least 6 characters long', style: TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      );

  Widget _buildActionButton() {
    String buttonText = "Send Verification Code";
    VoidCallback? onPressed = _sendOTP;

    if (isOTPSent && !isOTPVerified) {
      buttonText = "Verify Code";
      onPressed = _verifyOTP;
    } else if (isOTPVerified) {
      buttonText = "Reset Password";
      onPressed = _resetPassword;
    }

    return SizedBox(
      height: 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF804692),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(buttonText),
      ),
    );
  }
}
