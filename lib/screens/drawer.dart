import 'package:churppy_admin/screens/contactUsScreen.dart';
import 'package:churppy_admin/screens/location.dart';
import 'package:churppy_admin/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'dashboard_screen.dart';
import 'login.dart';
import 'orders_history_screen.dart';

class ChurppyDrawer extends StatefulWidget {
  const ChurppyDrawer({super.key});

  @override
  State<ChurppyDrawer> createState() => _ChurppyDrawerState();
}

class _ChurppyDrawerState extends State<ChurppyDrawer> {
  // ✅ ADDED FOR PROFILE IMAGE
  String? userId;
  String? profileImage;
  String? firstName;
  String? lastName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  /// ✅ Load user_id then fetch profile
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString("user_id");

    debugPrint("✅ Logged-in User ID (Drawer): $savedUserId");

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
      debugPrint("📥 Profile Response (Drawer): ${res.body}");

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
      debugPrint("⚠️ Profile Fetch Error (Drawer): $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    return Drawer(
      width: screenW, // 🔹 Full responsive width
      child: Column(
        children: [
          /// 🔹 Main Purple Body
          Expanded(
            child: Container(
              color: const Color(0xFF804692),
              child: SingleChildScrollView( // ✅ scrollable for small devices
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🔝 Top bar
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.only(
                        top: screenH * 0.05,
                        left: 12,
                        right: 12,
                        bottom: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/icons/menu.png',
                                  width: screenW * 0.1,
                                  height: screenW * 0.1,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: screenW * 0.25,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          /// ✅ PROFILE IMAGE INSTEAD OF TRUCK ICON
                          _isLoading 
                              ? CircularProgressIndicator()
                              : GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                    );
                                  },
                                  child: profileImage != null
                                      ? ClipOval(
                                          child: Image.network(
                                            profileImage!,
                                            width: screenW * 0.1,
                                            height: screenW * 0.1,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, o, s) {
                                              return Container(
                                                width: screenW * 0.18,
                                                height: screenW * 0.18,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.person,
                                                  size: screenW * 0.1,
                                                  color: Colors.grey[600],
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : Container(
                                          width: screenW * 0.18,
                                          height: screenW * 0.18,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.person,
                                            size: screenW * 0.1,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 🔘 Menu items
                    _buildDrawerItem(context, "Home", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DashboardScreen()),
                      );
                    }),
                    _buildDrawerItem(context, "Orders", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const OrdersHistoryScreen()),
                      );
                    }),
                    _buildDrawerItem(context, "Profile", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfileScreen()),
                      );
                    }),
                    _buildDrawerItem(context, "Logout", () {
                      _showLogoutDialog(context);
                    }),

                    SizedBox(height: screenH * 0.06),

                    // 🔹 Contact + Footer texts
                    Center(
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              // Navigate to Contact Us / Feedback screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ContactUsScreen()),
                              );
                            },
                            child: Text(
                              "Contact Us or Submit feedback.",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          InkWell(
                            onTap: () {
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
                              "Create Churppy Alerts In Just 4 Steps",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          SizedBox(height: screenH * 0.09),
                          Text("Thank You For Choosing Churppy!",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 12),
                          Text("We Appreciate Your Business",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// 🔸 Bottom white section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16, top: 10, bottom: 16),
            width: double.infinity,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          title: Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w500)),
          onTap: onTap,
        ),
        const Divider(color: Colors.white54, height: 1),
      ],
    );
  }

  /// 🔔 Logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        content: const Text("Are you sure you want to logout?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}