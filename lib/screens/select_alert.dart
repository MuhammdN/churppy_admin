import 'package:churppy_admin/screens/contactUsScreen.dart';
import 'package:churppy_admin/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'drawer.dart';
import 'location.dart'; // LocationAlertStep2Screen yahan se aati hai
import 'create_churppy_alert_screen.dart';

class SelectAlertScreen extends StatefulWidget {
  const SelectAlertScreen({super.key});

  @override
  State<SelectAlertScreen> createState() => _SelectAlertScreenState();
}

class _SelectAlertScreenState extends State<SelectAlertScreen> {
  int _selectedOption = 0;

  // ✅ ADDED FOR PROFILE IMAGE
  String? userId;
  String? profileImage;
  String? firstName;
  String? lastName;
  bool _isLoading = true;

  // 🔹 Alert Titles
  final Map<int, String> _alertTitles = {
    0: "LOCATION ALERT - MOST POPULAR",
    1: "CHURPPY CHAIN ALERT",
    2: "LAST MINUTE DEALS",
    3: "CUSTOMIZE ALERTS",
  };

  // 🔹 Sample Texts
  final Map<int, String> _sampleTexts = {
    0: "Tee's Tasty Kitchen will be located at 33 Churppy Rd, Churppy, 33333 on October 9th from 11am to 6pm. Look Forward to Seeing You! (Clock with time left or starting in x minutes)",
    1: "Someone in your area just ordered from Tee's Tasty Kitchen, 101 Churppy College Court. Place your own order now! (Clock with time left)",
    2: "We Cooked Too Much! Stop By Tee's Tasty Kitchen, 101 Churppy Corner, 33333 by 9pm tonight and receive 25% OFF!! (Clock with time left)",
    3: "Customize Alerts request",
  };

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  /// ✅ Load user_id then fetch profile
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString("user_id");

    debugPrint("✅ Logged-in User ID: $savedUserId");

    setState(() {
      userId = savedUserId;
    });

    if (savedUserId != null) {
      await _fetchUserProfile(savedUserId);
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  /// ✅ Fetch User Profile
  Future<void> _fetchUserProfile(String uid) async {
    final url = Uri.parse(
        "https://churppy.eurekawebsolutions.com/api/user.php?id=$uid");

    try {
      final res = await http.get(url);
      debugPrint("📥 Profile Response: ${res.body}");

      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);

        if (result["status"] == "success") {
          final data = result["data"];

          setState(() {
            profileImage = data["image"];     // ✅ full URL already
            firstName = data["first_name"];
            lastName = data["last_name"];
          });
        }
      }
    } catch (e) {
      debugPrint("⚠️ Profile Fetch Error: $e");
    }
  }

  void _handleSendAlert() {
    /// ✅ Ab hum selected alert ke hisaab se alertType bhejte hain
    String selectedTitle = _alertTitles[_selectedOption] ?? "Alert";
    String selectedText = _sampleTexts[_selectedOption] ?? "";

    // ✅ Decide alertType
    String alertType = _selectedOption == 3 ? "custom" : "churppy";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationAlertStep2Screen(
          alertTitle: selectedTitle,
          alertDescription: selectedText,
          alertType: alertType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const ChurppyDrawer(),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// 🔰 Top Header - UPDATED WITH BACK ARROW AND PROFILE IMAGE
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// Left: Back Button + Menu + Logo
                      Row(
                        children: [
                          // ✅ ADDED BACK ARROW
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.arrow_back,
                                size: 24,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Builder(
                            builder: (context) => GestureDetector(
                              onTap: () => Scaffold.of(context).openDrawer(),
                              child: Image.asset(
                                'assets/icons/menu.png',
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Image.asset(
                            'assets/images/logo.png',
                            width: 100,
                          ),
                        ],
                      ),

                      /// ✅ RIGHT — PROFILE IMAGE (TAPPABLE)
                      _isLoading 
                          ? const CircularProgressIndicator()
                          : GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                );
                              },
                              child: profileImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: Image.network(
                                        profileImage!,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, o, s) {
                                          return const Icon(Icons.person,
                                              size: 40, color: Colors.grey);
                                        },
                                      ),
                                    )
                                  : const Icon(Icons.person,
                                      size: 40, color: Colors.grey),
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔰 Alert Banner (SEND CHURPPY ALERT Button)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: _handleSendAlert,
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/bell_churppy.png',
                          height: 70,
                          width: 70,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8BC34A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'SEND CHURPPY ALERT',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// 🔰 Scrollable Alert Options
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "STEP 1 - SELECT ALERT",
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildOption(
                          0,
                          _alertTitles[0]!,
                          "Tell customers where you are NOW or where you will be located!",
                          _sampleTexts[0]!,
                          titleColor: Colors.purple,
                        ),
                        _buildOption(
                          1,
                          _alertTitles[1]!,
                          "Bundle orders together in the same area. SHORT TERM, meant for NOW.",
                          _sampleTexts[1]!,
                          titleColor: Colors.green,
                        ),
                        _buildOption(
                          2,
                          _alertTitles[2]!,
                          "",
                          _sampleTexts[2]!,
                          titleColor: Colors.red,
                        ),

                        // ✅ Customize Option (same behavior)
                        _buildOption(
                          3,
                          _alertTitles[3]!,
                          "",
                          _sampleTexts[3]!,
                          titleColor: Colors.purple,
                        ),
                        const Divider(),
                        const SizedBox(height: 20),

                        /// 🔰 Connect For Help Button
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ContactUsScreen()),
                              );
                            },
                            child: Text(
                              "CONNECT FOR HELP",
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  /// ✅ Updated option builder with animated border outline
  Widget _buildOption(
    int value,
    String title,
    String description,
    String sample, {
    Color? titleColor,
  }) {
    bool isSelected = _selectedOption == value;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF8BC34A) : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF8BC34A).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              ),
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              spreadRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio button with custom styling
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 16, top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF8BC34A) : Colors.grey,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF8BC34A) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with color
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: titleColor ?? Colors.black,
                    ),
                  ),
                  
                  // Description (if available)
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                  
                  // Sample text (if available)
                  if (sample.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        sample,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: Colors.black87,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}