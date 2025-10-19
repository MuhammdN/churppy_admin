import 'dart:convert';
import 'dart:io';
import 'package:churppy_admin/screens/contactUsScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';

import 'PaymentScreen.dart';
import 'drawer.dart';
import 'location.dart'; // AlertModel import

class ReviewChurppyScreen extends StatefulWidget {
  final AlertModel alert;

  const ReviewChurppyScreen({super.key, required this.alert});

  @override
  State<ReviewChurppyScreen> createState() => _ReviewChurppyScreenState();
}

class _ReviewChurppyScreenState extends State<ReviewChurppyScreen> {
  String? userId;
  bool _isLoading = false;
  String alert = "";

  @override
  void initState() {
    super.initState();
    _loadUserId();
    alert = widget.alert.title;
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString("user_id");
    setState(() => userId = savedUserId);

    debugPrint("✅ SharedPref User ID (ReviewChurppyScreen): $savedUserId");
    debugPrint("✅ Data received: "
        "${widget.alert.title}, ${widget.alert.description}, ${widget.alert.location}, "
        "Radius: ${widget.alert.radius}, Image: ${widget.alert.imageName}, "
        "AlertType: ${widget.alert.alertType}");
  }

  String formatDate(String rawDate) {
    try {
      return DateFormat("MMMM d").format(DateTime.parse(rawDate));
    } catch (_) {
      return rawDate;
    }
  }

  String formatTime(String rawTime) {
    try {
      return DateFormat("h a").format(DateFormat("HH:mm").parse(rawTime));
    } catch (_) {
      return rawTime;
    }
  }

  String formatLocation(String rawLocation) {
    if (rawLocation.contains(",")) return "Selected Location";
    return rawLocation;
  }

  /// ✅ Send Alert API call
Future<void> _sendAlert({required int status}) async {
  if (userId == null) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("User ID not found")));
    return;
  }

  setState(() => _isLoading = true);

  try {
    final uri = Uri.parse(
        "https://churppy.eurekawebsolutions.com/api/admin_add_alert.php");
    final request = http.MultipartRequest('POST', uri);

    request.fields.addAll({
      'merchant_id': userId!,
      'title': widget.alert.title,
      'description': widget.alert.description,
      'location': widget.alert.location,
      'start_date': widget.alert.startDate,
      'expiry_date': widget.alert.expiryDate,
      'start_time': widget.alert.startTime,
      'end_time': widget.alert.endTime,
      'radius': widget.alert.radius.toString(),
      'status': status.toString(),
      'alert_type': widget.alert.alertType,
    });

    // ✅ Image Handling
    if (widget.alert.imageName.isNotEmpty) {
      final file = File(widget.alert.imageName);
      if (file.existsSync()) {
        final mimeType = lookupMimeType(file.path);
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          file.path,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ));
      } else {
        request.fields['existing_image'] = widget.alert.imageName.split('/').last;
      }
    }

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (!mounted) return;
    debugPrint("🔍 Raw API Response: $resBody");

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(resBody);
      final msg = jsonData['message']?.toString() ?? "";
      final statusStr = jsonData['status']?.toString().toLowerCase();

      // ✅ SUCCESS RESPONSE
      if (statusStr == 'success') {
        final remain = jsonData['remaining'];
        final max = jsonData['max_limit'];

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green.shade200, width: 3),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF8BC34A),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Alert Created Successfully!",
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8BC34A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Your alert has been created and is now active.",
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Remaining Alerts",
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "$remain",
                              style: GoogleFonts.roboto(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            Text(
                              " / $max",
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8BC34A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        "CONTINUE",
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        // ❌ ERROR CASES (Limit Reached / No Active Plan)
        final used = jsonData['used'];
        final max = jsonData['max_limit'];
        final lowerMsg = msg.toLowerCase();

        if (lowerMsg.contains("limit") ||
            lowerMsg.contains("reached") ||
            lowerMsg.contains("no active plan") ||
            lowerMsg.contains("no active") ||
            lowerMsg.contains("expired") ||
            (used != null && max != null && used == max)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jsonData['message'] ??
                  "Your plan has expired or no active plan found."),
              backgroundColor: Colors.red,
            ),
          );

          // ✅ Navigate to PaymentScreen and FORCE create alert
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentScreen(
                    alert: widget.alert,
                    // 👇 send flag to force alert insert after payment
                    key: const ValueKey("force_create_alert"),
                  ),
                ),
              );
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jsonData['message'] ?? "Something went wrong."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server Error: $resBody")),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Exception: $e")));
    debugPrint("🔥 Exception while sending alert: $e");
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final maxCardW = w.clamp(320.0, 480.0);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxCardW),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
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

                      Padding(
                        padding: const EdgeInsets.only(left: 22, top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(alert,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.purple)),
                            const SizedBox(height: 2),
                            const Text('STEP 3 - REVIEW',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.asset(
                                      'assets/images/truck.png',
                                      width: 70,
                                      height: 70,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "${widget.alert.title} will be located at ${formatLocation(widget.alert.location)} "
                                      "on ${formatDate(widget.alert.startDate)} from ${formatTime(widget.alert.startTime)} "
                                      "to ${formatTime(widget.alert.endTime)}.",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: const Text(
                                  "1hr 22mins left",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 2),
                        child: _styledButton("APPROVE", Colors.green, () {
                          _sendAlert(status: 1);
                        }),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 6),
                        child: _styledButton("SAVE FOR LATER", Colors.black54,
                            () {
                          _sendAlert(status: 0);
                        }),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 120, vertical: 6),
                        child: _styledButton("Contact Us", Colors.red, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ContactUsScreen()),
                          );
                        }),
                      ),

                      const SizedBox(height: 80),

                      Center(
                        child: TextButton(
                          onPressed: () {},
                          child: const Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "CUSTOMIZE ALERTS",
                                  style: TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: " - Complete Request",
                                  style: TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
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
                Image.asset('assets/icons/menu.png', width: 40, height: 40),
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
    );
  }

  Widget _styledButton(String text, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: TextButton(
          onPressed: onTap,
          child: Text(
            text,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: color),
          ),
        ),
      ),
    );
  }
}
