import 'package:churppy_admin/screens/contactUsScreen.dart';
import 'package:churppy_admin/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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

  // ✅ ADDED FOR PROFILE IMAGE AND BUSINESS NAME
  String? userId;
  String? profileImage;
  String? firstName;
  String? lastName;
  String businessName = ""; // ✅ NEW: Dynamic business name
  bool _isLoading = true;

  // 🔹 Alert Titles
  final Map<int, String> _alertTitles = {
    0: "LOCATION ALERT - MOST POPULAR",
    1: "CHURPPY CHAIN ALERT", 
    2: "LAST MINUTE DEALS",
    3: "CUSTOMIZE ALERTS",
  };

  // 🔹 Sample Texts - NOW DYNAMIC WITH BUSINESS NAME
  final Map<int, String> _sampleTexts = {
    0: "Loading business info...",
    1: "Loading business info...", 
    2: "Loading business info...",
    3: "Customize Alerts request",
  };

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  /// ✅ Load user_id then fetch profile AND business name
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString("user_id");

    debugPrint("✅ Logged-in User ID: $savedUserId");

    setState(() {
      userId = savedUserId;
    });

    if (savedUserId != null) {
      await _fetchUserProfile(savedUserId);
      await _fetchBusinessName(savedUserId); // ✅ NEW: Fetch business name
      _updateSampleTexts(); // ✅ NEW: Update texts with business name
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

  /// ✅ NEW: Fetch Business Name from APIs
  Future<void> _fetchBusinessName(String id) async {
    try {
      // 1) Try user_with_merchant.php first
      try {
        final url1 = Uri.parse(
          "https://churppy.eurekawebsolutions.com/api/user_with_merchant.php?id=$id",
        );
        final r1 = await http.get(url1);
        if (r1.statusCode == 200) {
          final j = jsonDecode(r1.body);
          if (j['status'] == 'success' && j['data'] is Map) {
            final bn = _guessBusinessName(j['data'] as Map<String, dynamic>);
            if (bn.isNotEmpty) {
              setState(() => businessName = bn);
              debugPrint("✅ Business name (merchant API): $businessName");
              return;
            }
          }
        }
      } catch (e) {
        debugPrint("⚠️ user_with_merchant fetch error: $e");
      }

      // 2) Fallback to user.php
      try {
        final url2 = Uri.parse(
          "https://churppy.eurekawebsolutions.com/api/user.php?id=$id",
        );
        final r2 = await http.get(url2);
        if (r2.statusCode == 200) {
          final j = jsonDecode(r2.body);
          if (j['status'] == 'success' && j['data'] is Map) {
            final bn = _guessBusinessName(j['data'] as Map<String, dynamic>);
            if (bn.isNotEmpty) {
              setState(() => businessName = bn);
              debugPrint("✅ Business name (user API): $businessName");
              return;
            }
          }
        }
      } catch (e) {
        debugPrint("⚠️ user.php fetch error: $e");
      }

      // If still empty, use first + last name
      if (businessName.isEmpty && firstName != null) {
        setState(() => businessName = "$firstName${lastName != null ? ' $lastName' : ''}");
        debugPrint("✅ Using user name as business name: $businessName");
      }
    } catch (e) {
      debugPrint("❌ Business fetch failed: $e");
    }
  }

  /// ✅ NEW: Extract business name from API data
  String _guessBusinessName(Map<String, dynamic> data) {
    final candidates = [
      'business_name',
      'business_title', 
      'title',
      'name',
      'about_us'
    ];
    for (final k in candidates) {
      final v = data[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return "";
  }

  /// ✅ NEW: Calculate time remaining for alerts
  String _getTimeRemaining(int alertType) {
    final now = DateTime.now();
    
    switch (alertType) {
      case 0: // Location Alert - Starting in X minutes
        final startTime = DateTime(now.year, now.month, now.day, 11, 0); // 11 AM today
        final difference = startTime.difference(now);
        
        if (difference.isNegative) {
          return "Started ${difference.inHours.abs()}h ${difference.inMinutes.abs() % 60}m ago";
        } else {
          return "Starting in ${difference.inHours}h ${difference.inMinutes % 60}m";
        }
        
      case 1: // Chain Alert - Time left
        final endTime = DateTime(now.year, now.month, now.day, 20, 0); // 8 PM today
        final difference = endTime.difference(now);
        
        if (difference.isNegative) {
          return "Ended ${difference.inHours.abs()}h ago";
        } else {
          return "${difference.inHours}h ${difference.inMinutes % 60}m left";
        }
        
      case 2: // Last Minute Deal - Time left
        final endTime = DateTime(now.year, now.month, now.day, 21, 0); // 9 PM today
        final difference = endTime.difference(now);
        
        if (difference.isNegative) {
          return "Deal expired ${difference.inHours.abs()}h ago";
        } else {
          return "${difference.inHours}h ${difference.inMinutes % 60}m left";
        }
        
      default:
        return "";
    }
  }

  /// ✅ NEW: Format date for display
  String _getFormattedDate() {
    final now = DateTime.now();
    return DateFormat('MMMM d').format(now); // e.g., "October 9"
  }

  /// ✅ NEW: Update sample texts with dynamic business name and REAL times
  void _updateSampleTexts() {
    final business = businessName.isNotEmpty ? businessName : "Our Business";
    final todayDate = _getFormattedDate();
    
    setState(() {
      // Location Alert - with actual start time calculation
      _sampleTexts[0] = "$business will be located at 33 Churppy Rd, Churppy, 33333 on $todayDate from 11am to 6pm. Look Forward to Seeing You! ${_getTimeRemaining(0)}";
      
      // Chain Alert - with actual time left calculation
      _sampleTexts[1] = "Someone in your area just ordered from $business, 101 Churppy College Court. Place your own order now! ${_getTimeRemaining(1)}";
      
      // Last Minute Deal - with actual time left calculation
      _sampleTexts[2] = "We Cooked Too Much! Stop By $business, 101 Churppy Corner, 33333 by 9pm tonight and receive 25% OFF!! ${_getTimeRemaining(2)}";
    });
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