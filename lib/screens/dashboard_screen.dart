import 'dart:convert';
import 'package:churppy_admin/screens/contactUsScreen.dart';
import 'package:churppy_admin/screens/select_alert.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'drawer.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? userId;

  // 🔹 Dashboard Stats
  int totalDelivered = 0;
  int totalCustomers = 0;
  int orderReceived = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchDashboardData();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString("user_id");

    setState(() {
      userId = savedUserId;
    });

    print("✅ Logged-in User ID: $savedUserId");
  }

  Future<void> _fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString("user_id");

    if (savedUserId == null) {
      print("⚠️ No user ID found in SharedPreferences");
      return;
    }

    final url =
        Uri.parse("https://churppy.eurekawebsolutions.com/api/admin_dashboard.php");

    try {
      final response = await http.post(
        url,
        body: {
          "user_id": savedUserId,
        },
      );

      print("🔗 API URL: $url");
      print("📤 Request Body: {user_id: $savedUserId}");
      print("📥 Status Code: ${response.statusCode}");
      print("📥 Raw Response: ${response.body}");

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        if (result['status'] == 'success') {
          final data = result['data'];
          setState(() {
            totalDelivered = data['total_delivered'] ?? 0;
            totalCustomers = data['total_customers'] ?? 0;
            orderReceived = data['order_received'] ?? 0;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ ${result['message']}")),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("⚠️ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final maxCardW = w.clamp(320.0, 480.0);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const ChurppyDrawer(),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCardW),
            child: SingleChildScrollView(
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
                                  width: 50,
                                  height: 50,
                                ),
                              ),
                            ),
                            const SizedBox(width: 1),
                            Image.asset(
                              'assets/images/logo.png',
                              width: 100,
                            ),
                          ],
                        ),
                        Image.asset(
                          'assets/images/truck.png',
                          width: 100,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ],
                    ),
                  ),

                  /// 🔰 Page Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Dashboard',
                      style: GoogleFonts.roboto(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// 🔰 Tappable Alert Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SelectAlertScreen()),
                        );
                      },
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
                                color: const Color(0xFF8DC63F),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'SEND CHURPPY ALERT',
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

                  const SizedBox(height: 20),

                  /// 🔰 4 Simple Steps
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "4 Simple Steps",
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _stepText("1. Select Alert"),
                        _stepText(
                            "2. Enter Location, Day(s) and Hours of Operation"),
                        _stepText("3. Review"),
                        _stepText("4. Send Churppy Alert"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 35, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8DC63F),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        "NEXT - Send Alert",
                        style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// 🔰 Stats Section
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              _statBox(
                                icon: Icons.notifications,
                                title: 'Total Churppy Alerts',
                                count: totalDelivered.toString(),
                                color: const Color(0xFF8DC63F),
                              ),
                              const SizedBox(height: 10),
                              _statBox(
                                icon: Icons.person_outline,
                                title: 'Total Customers',
                                count: totalCustomers.toString(),
                                color: Colors.purple,
                              ),
                              const SizedBox(height: 10),
                              _statBox(
                                icon: Icons.remove_red_eye_outlined,
                                title: 'Order Received',
                                count: orderReceived.toString(),
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),

                  const SizedBox(height: 20),

                  /// 🔰 Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "LET US CUSTOMIZE ALERTS FOR YOU!",
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent, // 🔹 Background remove
    shadowColor: Colors.transparent,     // 🔹 Shadow remove
    elevation: 0,                        // 🔹 Elevation 0
  ),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactUsScreen()),
    );
  },
  child: Text(
    "CONNECT WITH US",
    style: GoogleFonts.roboto(
      fontWeight: FontWeight.bold,
      color: Colors.red, // 🔹 Text ka color same rakha
    ),
  ),
),

                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔰 Stat Box Widget
  Widget _statBox({
    required IconData icon,
    required String title,
    required String count,
    required Color color,
  }) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _stepText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }
}
