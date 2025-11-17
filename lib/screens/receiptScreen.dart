import 'package:churppy_admin/screens/contactUsScreen.dart';
import 'package:churppy_admin/screens/location.dart';
import 'package:churppy_admin/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // ✅ For formatting current date
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'dashboard_screen.dart'; // ✅ Make sure this import is correct
import 'drawer.dart'; // ✅ For ChurppyDrawer

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  String? userId;
  String? userName;
  String? userEmail;
  String? userImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// ✅ Load user ID from SharedPreferences and fetch profile data
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString("user_id");
      
      setState(() {
        userId = savedUserId;
      });

      debugPrint("✅ SharedPref User ID (ReceiptScreen): $savedUserId");

      if (savedUserId != null) {
        await _fetchUserProfile(savedUserId);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ Error loading user data: $e");
      setState(() => _isLoading = false);
    }
  }

  /// ✅ Fetch user profile from API
  Future<void> _fetchUserProfile(String uid) async {
  final url = Uri.parse("https://churppy.eurekawebsolutions.com/api/user.php?id=$uid");

  try {
    final res = await http.get(url);
    debugPrint("📥 Receipt Profile Response: ${res.body}");

    if (res.statusCode == 200) {
      final result = jsonDecode(res.body);

      if (result["status"] == "success") {
        final data = result["data"];

        setState(() {
          userName = "${data["first_name"] ?? ""} ${data["last_name"] ?? ""}".trim();
          userEmail = data["email"];
          userImage = data["image"]; // ⭐ SAME AS DASHBOARD
          _isLoading = false;
        });
      }
    }
  } catch (e) {
    debugPrint("⚠️ Receipt Profile Error: $e");
    setState(() => _isLoading = false);
  }
}

  /// ✅ Update user data from API response
  void _updateUserData(Map<String, dynamic> userData) {
    setState(() {
      userName = _getUserName(userData);
      userEmail = userData['email']?.toString();
      
      _isLoading = false;
    });

  
  }

  /// ✅ Extract user name from data
  String _getUserName(Map<String, dynamic> data) {
    final firstName = data['first_name']?.toString() ?? '';
    final lastName = data['last_name']?.toString() ?? '';
    final businessName = data['business_name']?.toString() ?? '';
    final name = data['name']?.toString() ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (businessName.isNotEmpty) {
      return businessName;
    } else if (name.isNotEmpty) {
      return name;
    } else {
      return 'User';
    }
  }

 

  /// ✅ Convert relative image name to full URL
  String _abs(String fileName) {
    if (fileName.startsWith("http://") || fileName.startsWith("https://")) {
      return fileName;
    }
    return "https://churppy.eurekawebsolutions.com/uploads/$fileName";
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Current date in dd/MM/yy format
    final String currentDate = DateFormat('dd/MM/yy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF804692)),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    /// ===== Header =====
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ChurppyDrawer()),
                              );
                            },
                            child: Row(
                              children: [
                                Image.asset('assets/icons/menu.png',
                                    width: 40, height: 40),
                                const SizedBox(width: 10),
                                Image.asset('assets/images/logo.png',
                                    width: 100, height: 40, fit: BoxFit.contain),
                              ],
                            ),
                          ),
                       GestureDetector(
  onTap: () {
    //  Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (context) => ProfileScreen()),
    // );
  },
  child: ClipOval(
    child: userImage != null && userImage!.isNotEmpty
        ? Image.network(
            userImage!,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.person, size: 40, color: Colors.grey),
          )
        : const Icon(Icons.person, size: 40, color: Colors.grey),
  ),
)


                        ],
                      ),
                    ),

                    /// Bell + Success Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/bell_churppy.png',
                            height: 60,
                            width: 60,
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "SUCCESS",
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8DC63F),
                                ),
                              ),
                              Text(
                                "Thank You For Choosing",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              Text(
                                "Churppy!",
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF804692),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                   

                    /// ===== Receipt Box =====
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Receipt",
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Current Plan: Single Use",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),

                          /// Items
                          _rowText("Churppy Alert", "\$16"),
                          _rowText("PDF upload", "20"),
                          _rowText("Credit Card Fee", "2"),
                          const Divider(thickness: 1),

                          /// Total
                          _rowText("Paid", "\$38",
                              isBold: true, color: Colors.black),
                          const SizedBox(height: 5),
                          Text(
                            currentDate, // ✅ Dynamic current date
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 15),

                          /// Receipt Options
                          Text("Print Receipt",
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                          Text("Save",
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                          Text("Send to Quickbooks",
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// HOME button with bell
                    Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 130),

                      child: _styledButton("HOME", Color(0xFF804692), () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const DashboardScreen()),
                        );
                      }, withBell: true),
                    ),
const SizedBox(height: 2),
                    /// CONTACT US button
                    Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 130),
                      child: _styledButton("CONTACT US", Colors.red, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ContactUsScreen()),
                        );
                      }),
                    ),

                    const SizedBox(height: 20),

                    /// Customize Alerts Link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LocationAlertStep2Screen(
                                alertTitle: "CUSTOMIZE ALERTS",
                                alertDescription: "Customize Alerts request", 
                                alertType: "custom",
                              ),
                            ),
                          );
                        },
                        child: Text(
                          "TRY CUSTOMIZE ALERTS",
                          style: GoogleFonts.inter(
                            color: Color(0xFF804692),
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  /// 🔹 Info Row Widget for User Information
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Row Widget for Receipt Items
  Widget _rowText(String left, String right,
      {bool isBold = false, Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color)),
          Text(right,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color)),
        ],
      ),
    );
  }
Widget _styledButton(String text, Color color, VoidCallback onTap,
    {bool withBell = false}) {
  return Stack(
    clipBehavior: Clip.none, // allow icon to go outside
    children: [
      // Main Button
      SizedBox(
        width: double.infinity,
        height: 45,
        child: Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextButton(
            onPressed: onTap,
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
          ),
        ),
      ),

      // Bell ONLY when withBell = true
      if (withBell)
        Positioned(
          left: -35, // ← Button ke bahir
          top: 8,
          child: Image.asset(
            'assets/images/bell_churppy.png',
            height: 35,
            width: 35,
          ),
        ),
    ],
  );
}
}