import 'dart:convert';
import 'package:churppy_admin/screens/AlertsListScreen.dart';
import 'package:churppy_admin/screens/contactUsScreen.dart';
import 'package:churppy_admin/screens/profile.dart';
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

  // ✅ NEW
  String? profileImage;
  String? firstName;
  String? lastName;

  int totalChurppyAlerts = 0;
  int totalDelivered = 0;
  int totalCustomers = 0;
  int orderReceived = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  /// ✅ Load user_id then fetch profile + stats
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString("user_id");

    debugPrint("✅ Logged-in User ID: $savedUserId");

    setState(() {
      userId = savedUserId;
    });

    if (savedUserId != null) {
      await _fetchUserProfile(savedUserId);     // ✅ NEW
      _fetchDashboardData(savedUserId);
    }
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

  /// ✅ Dashboard API call
  Future<void> _fetchDashboardData(String uid) async {
    final url = Uri.parse(
        "https://churppy.eurekawebsolutions.com/api/admin_dashboard.php");

    try {
      final response = await http.post(url, body: {"user_id": uid});

      debugPrint("📥 Raw Response: ${response.body}");

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        if (result['status'] == 'success') {
          final data = result['data'];

          setState(() {
            totalChurppyAlerts = data['total_churppy_alerts'] ?? 0;
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
      debugPrint("⚠️ Error: $e");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error: $e")),
      );
    }
  }

  /// ✅ Navigate to Alerts List Screen
  void _navigateToAlertsList() {
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlertsListScreen(userId: userId!),
        ),
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

                        /// ✅ RIGHT — PROFILE IMAGE (NOW TAPPABLE)
                        GestureDetector(
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
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, o, s) {
                                      return const Icon(Icons.person,
                                          size: 70, color: Colors.grey);
                                    },
                                  ),
                                )
                              : const Icon(Icons.person,
                                  size: 70, color: Colors.grey),
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

                  /// Purple dashed divider
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final dashWidth = 9.0;
                          final dashCount =
                              (constraints.maxWidth / (2 * dashWidth)).floor();
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(dashCount, (_) {
                              return Container(
                                width: dashWidth,
                                height: 3,
                                color: Colors.purple,
                              );
                            }),
                          );
                        },
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
                              // ✅ TAPPABLE TOTAL CHURPPY ALERTS
                              GestureDetector(
                                onTap: _navigateToAlertsList,
                                child: _statBox(
                                  icon: Icons.notifications,
                                  title: 'Total Churppy Alerts',
                                  count: totalChurppyAlerts.toString(),
                                  color: const Color(0xFF8DC63F),
                                ),
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
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ContactUsScreen()),
                            );
                          },
                          child: Text(
                            "CONNECT WITH US",
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
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

  /// 🔰 Stat Box Widget - EXACTLY SAME AS BEFORE
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