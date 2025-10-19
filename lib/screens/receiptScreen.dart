import 'package:churppy_admin/screens/contactUsScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // ✅ For formatting current date
import 'dashboard_screen.dart'; // ✅ Make sure this import is correct

import 'drawer.dart'; // ✅ For ChurppyDrawer

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Current date in dd/MM/yy format
    final String currentDate = DateFormat('dd/MM/yy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
                    ClipOval(
                      child: Image.asset('assets/images/truck.png',
                          width: 70, height: 70, fit: BoxFit.cover),
                    ),
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
                            color: Colors.green,
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
                            color: Colors.purple,
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
                padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 5),
                child: _styledButton("HOME", Colors.purple, () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  );
                }, withBell: true),
              ),

              /// CONTACT US button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 5),
                child: _styledButton("CONTACT US", Colors.red, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ContactUsScreen()),
                  );
                }),
              ),

              const SizedBox(height: 30),

              /// Customize Alerts Link
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    "TRY CUSTOMIZE ALERTS",
                    style: GoogleFonts.inter(
                      color: Colors.purple,
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

  /// 🔹 Row Widget
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

  /// 🔹 Styled Button with optional bell
  Widget _styledButton(String text, Color color, VoidCallback onTap,
      {bool withBell = false}) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        child: TextButton(
          onPressed: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (withBell) ...[
                Image.asset(
                  'assets/images/bell_churppy.png',
                  height: 30,
                  width: 30,
                ),
                const SizedBox(width: 2),
              ],
              Text(
                text,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
