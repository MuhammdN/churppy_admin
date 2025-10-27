import 'package:churppy_admin/screens/contactUsScreen.dart';
import 'package:churppy_admin/screens/location.dart';
import 'package:churppy_admin/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_screen.dart';
import 'login.dart';
import 'orders_history_screen.dart';
// pakistan
class ChurppyDrawer extends StatelessWidget {
  const ChurppyDrawer({super.key});

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
                          ClipOval(
                            child: Image.asset(
                              'assets/images/truck.png',
                              width: screenW * 0.18,
                              height: screenW * 0.18,
                              fit: BoxFit.cover,
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
  static void _showLogoutDialog(BuildContext context) {
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
