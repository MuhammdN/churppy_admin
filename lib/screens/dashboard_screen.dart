import 'dart:convert';
import 'package:churppy_admin/screens/AlertsListScreen.dart';
import 'package:churppy_admin/screens/contactUsScreen.dart';
import 'package:churppy_admin/screens/profile.dart';
import 'package:churppy_admin/screens/select_alert.dart';
import 'package:dotted_line/dotted_line.dart';
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
  String? profileImage;
  String? firstName;
  String? lastName;

  int totalChurppyAlerts = 0;
  int totalDelivered = 0;
  int totalCustomers = 0;
  int orderReceived = 0;

  bool isLoading = true;

  // ✅ New filter dropdown value
  String selectedFilter = "all";
  final List<Map<String, String>> filterOptions = [
    {"label": "All Time", "value": "all"},
    {"label": "Weekly", "value": "week"},
    {"label": "Monthly", "value": "month"},
    {"label": "Yearly", "value": "year"},
  ];

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
      await _fetchUserProfile(savedUserId);
      _fetchDashboardData(savedUserId, selectedFilter);
    }
  }

  /// ✅ Fetch User Profile
  Future<void> _fetchUserProfile(String uid) async {
    final url =
        Uri.parse("https://churppy.eurekawebsolutions.com/api/user.php?id=$uid");

    try {
      final res = await http.get(url);
      debugPrint("📥 Profile Response: ${res.body}");

      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);

        if (result["status"] == "success") {
          final data = result["data"];

          setState(() {
            profileImage = data["image"];
            firstName = data["first_name"];
            lastName = data["last_name"];
          });
        }
      }
    } catch (e) {
      debugPrint("⚠️ Profile Fetch Error: $e");
    }
  }

  /// ✅ Dashboard API call (now with filter)
  Future<void> _fetchDashboardData(String uid, String filter) async {
    setState(() => isLoading = true);
    final url =
        Uri.parse("https://churppy.eurekawebsolutions.com/api/admin_dashboard.php");

    try {
      final response = await http.post(url, body: {
        "user_id": uid,
        "filter": filter,
      });

      debugPrint("📥 Raw Dashboard Response: ${response.body}");

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

                        /// ✅ RIGHT — PROFILE IMAGE
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ProfileScreen()),
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
                                          size: 45, color: Colors.grey);
                                    },
                                  ),
                                )
                              : const Icon(Icons.person,
                                  size: 70, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  /// 🔰 Page Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dashboard',
                          style: GoogleFonts.roboto(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        /// ✅ Filter Dropdown
                        DropdownButton<String>(
                          value: selectedFilter,
                          icon: const Icon(Icons.filter_list, color: Colors.purple),
                          underline: const SizedBox(),
                          items: filterOptions.map((opt) {
                            return DropdownMenuItem<String>(
                              value: opt["value"],
                              child: Text(opt["label"]!,
                                  style: GoogleFonts.roboto(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null && userId != null) {
                              setState(() => selectedFilter = val);
                              _fetchDashboardData(userId!, val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// 🔰 SEND ALERT BANNER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>  SelectAlertScreen()),
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
                  SizedBox(height: 25),
                 Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "3 Simple Steps",
        style: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        "1. Select Alert",
        style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
      ),
      const SizedBox(height: 4),
      Text(
        "2. Enter Location, Day(s) and Hours of Operation",
        style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
      ),
      const SizedBox(height: 4),
      Text(
        "3. Review",
        style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
      ),
     

     
    ],
  ),
),

                
SizedBox(height: 25),
                  
    Center(
  child: SizedBox(
    width: 350, 
    child: DottedLine(
      dashColor: Color(0xFF804692),
      lineThickness: 2,
      dashLength: 20,
      dashGapLength: 4,
    ),
  ),
),

    SizedBox(height: 25),
                  /// 🔰 Stats Section
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
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
                                color: Color(0xFF804692),
                              ),
                              const SizedBox(height: 10),
                              _statBox(
                                icon: Icons.star,
                                title: 'Order Received',
                                count: orderReceived.toString(),
                                color: Colors.orangeAccent,
                              ),
                            ],
                          ),
                        ),
SizedBox(height: 25),
                  
    Center(
  child: SizedBox(
    width: 350, 
    child: DottedLine(
      dashColor: Color(0xFF804692),
      lineThickness: 2,
      dashLength: 20,
      dashGapLength: 4,
    ),
  ),
),

    SizedBox(height: 25),

                  /// 🔰 Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "LET US CUSTOMIZE ALERTS FOR YOU!",
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF804692),
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
                        SizedBox(height: 20),

    
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
}
