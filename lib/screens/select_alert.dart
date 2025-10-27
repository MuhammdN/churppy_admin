import 'package:churppy_admin/screens/contactUsScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // 🔹 Alert Titles
  final Map<int, String> _alertTitles = {
    0: "LOCATION ALERT - MOST POPULAR",
    1: "CHURPPY CHAIN ALERT",
    2: "LAST MINUTE DEALS",
    3: "CUSTOMIZE ALERTS",
  };

  // 🔹 Sample Texts
  final Map<int, String> _sampleTexts = {
    0: "Tee’s Tasty Kitchen will be located at 33 Churppy Rd, Churppy, 33333 on October 9th from 11am to 6pm. Look Forward to Seeing You! (Clock with time left or starting in x minutes)",
    1: "Someone in your area just ordered from Tee’s Tasty Kitchen, 101 Churppy College Court. Place your own order now! (Clock with time left)",
    2: "We Cooked Too Much! Stop By Tee’s Tasty Kitchen, 101 Churppy Corner, 33333 by 9pm tonight and receive 25% OFF!! (Clock with time left)",
    3: "Customize Alerts request",
  };

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
                /// 🔰 Top Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// Left: Menu + Logo
                      Row(
                        children: [
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

                      /// Right: Truck icon
                      Image.asset(
                        'assets/images/truck.png',
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
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
                        GestureDetector(
                          onTap: () => setState(() => _selectedOption = 3),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedOption == 3
                                  ? Colors.grey.shade100
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Radio<int>(
                                value: 3,
                                groupValue: _selectedOption,
                                onChanged: (val) {
                                  setState(() => _selectedOption = val!);
                                },
                              ),
                              title: Text(
                                _alertTitles[3]!,
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  _sampleTexts[3]!,
                                  style: GoogleFonts.roboto(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
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

  /// ✅ Unified option builder with tap area selecting radio
  Widget _buildOption(
    int value,
    String title,
    String description,
    String sample, {
    Color? titleColor,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = value), // 👈 tap anywhere
      child: Container(
        decoration: BoxDecoration(
          color: _selectedOption == value
              ? Colors.grey.shade100
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Radio<int>(
                value: value,
                groupValue: _selectedOption,
                onChanged: (val) {
                  setState(() => _selectedOption = val!);
                },
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: titleColor ?? Colors.black,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                  if (sample.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      sample,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
