import 'dart:convert';
import 'dart:io';
import 'package:churppy_admin/screens/contactUsScreen.dart';
import 'package:churppy_admin/screens/profile.dart';
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
  String? profileImage;
  String alert = "";
  String _locationName = "Loading location..."; // 🔰 Store location name
  bool _isFetchingLocation = true; // 🔰 Track location fetching
  String _timeRemaining = "Calculating..."; // 🔰 Dynamic time remaining

  /// ✅ Will store real business name from DB
  String businessName = "";

  @override
  void initState() {
    super.initState();
    _loadUserId();
    alert = widget.alert.title;
    _getLocationNameFromCoordinates(); // 🔰 Get location name on init
    _calculateTimeRemaining(); // 🔰 Calculate dynamic time remaining
  }

  /// ✅ Convert relative image name to full URL
  String _abs(String fileName) {
    if (fileName.startsWith("http://") || fileName.startsWith("https://")) {
      return fileName;
    }
    return "https://churppy.eurekawebsolutions.com/uploads/$fileName";
  }

  /// ✅ Robust extractor for business name from various APIs
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
    // Fallback to user full name if available
    final fn = data['first_name']?.toString() ?? '';
    final ln = data['last_name']?.toString() ?? '';
    final full = ('$fn $ln').trim();
    if (full.isNotEmpty) return full;
    return "";
  }
/// ✅ Fetch user profile image
Future<void> _fetchProfileImage(String id) async {
  try {
    final url = Uri.parse(
      "https://churppy.eurekawebsolutions.com/api/user.php?id=$id",
    );
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['status'] == 'success' && jsonData['data'] is Map) {
        final userData = jsonData['data'] as Map<String, dynamic>;
        
        // Try different possible keys for profile image
        final imagePath = userData['profile_image'] ?? 
                         userData['image'] ?? 
                         userData['avatar'] ?? 
                         userData['photo'];
        
        if (imagePath != null && imagePath.toString().isNotEmpty) {
          setState(() {
            profileImage = _abs(imagePath.toString());
          });
          debugPrint("✅ Profile image loaded: $profileImage");
        } else {
          debugPrint("ℹ️ No profile image found for user");
        }
      }
    }
  } catch (e) {
    debugPrint("❌ Error fetching profile image: $e");
  }
}
  /// ✅ Try user_with_merchant first (can contain business info),
  /// then fallback to users.php (your provided endpoint) for at least a name
  Future<void> _fetchBusinessName(String id) async {
    try {
      // 1) Try user_with_merchant.php
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

      // 2) Fallback to user.php (the code you provided)
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

      // If still empty, keep it blank (UI shows "Loading..." until fetched)
      if (businessName.isEmpty) {
        debugPrint("❌ Business name not found in APIs.");
      }
    } catch (e) {
      debugPrint("❌ Business fetch failed: $e");
    }
  }

  Future<void> _loadUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final savedUserId = prefs.getString("user_id");
  setState(() => userId = savedUserId);

  if (savedUserId != null) {
    await _fetchBusinessName(savedUserId);
    await _fetchProfileImage(savedUserId); // ✅ ADD THIS LINE
  }

  debugPrint("✅ SharedPref User ID (ReviewChurppyScreen): $savedUserId");
  debugPrint("✅ Data received: "
      "${widget.alert.title}, ${widget.alert.description}, ${widget.alert.location}, "
      "Radius: ${widget.alert.radius}, Image: ${widget.alert.imageName}, "
      "AlertType: ${widget.alert.alertType}, Discount: ${widget.alert.discount}");
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
      // Accepts "HH:mm" or "HH:mm:ss"
      final base = rawTime.length >= 8 ? "HH:mm:ss" : "HH:mm";
      return DateFormat("h a").format(DateFormat(base).parse(rawTime));
    } catch (_) {
      return rawTime;
    }
  }

  /// 🔰 NEW: Get actual location name from coordinates using reverse geocoding
  Future<void> _getLocationNameFromCoordinates() async {
    debugPrint("📍 Raw location data: ${widget.alert.location}");
    
    // If location is already a name (not coordinates), use it directly
    if (!widget.alert.location.contains(",")) {
      setState(() {
        _locationName = widget.alert.location;
        _isFetchingLocation = false;
      });
      return;
    }

    try {
      final parts = widget.alert.location.split(",");
      if (parts.length == 2) {
        final lat = parts[0].trim();
        final lon = parts[1].trim();
        
        debugPrint("📍 Converting coordinates to address: Lat: $lat, Lon: $lon");

        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1'
        );

        final response = await http.get(url, headers: {
          'User-Agent': 'ChurppyApp/1.0'
        });

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          debugPrint("📍 Reverse geocoding response: $data");
          
          final address = data['address'];
          final displayName = data['display_name'];
          
          if (address != null) {
            // Priority-based location name extraction
            String locationName = "Selected Location";
            
            if (address['road'] != null && address['road'].toString().isNotEmpty) {
              locationName = address['road'].toString(); // Street name
            } else if (address['neighbourhood'] != null && address['neighbourhood'].toString().isNotEmpty) {
              locationName = address['neighbourhood'].toString(); // Neighborhood
            } else if (address['suburb'] != null && address['suburb'].toString().isNotEmpty) {
              locationName = address['suburb'].toString(); // Suburb
            } else if (address['city'] != null && address['city'].toString().isNotEmpty) {
              locationName = address['city'].toString(); // City
            } else if (address['town'] != null && address['town'].toString().isNotEmpty) {
              locationName = address['town'].toString(); // Town
            } else if (address['village'] != null && address['village'].toString().isNotEmpty) {
              locationName = address['village'].toString(); // Village
            } else if (address['county'] != null && address['county'].toString().isNotEmpty) {
              locationName = address['county'].toString(); // County
            } else if (address['state'] != null && address['state'].toString().isNotEmpty) {
              locationName = address['state'].toString(); // State
            } else if (displayName != null && displayName.toString().isNotEmpty) {
              // Use first part of display name
              locationName = displayName.toString().split(',').first;
            }
            
            setState(() {
              _locationName = locationName;
              _isFetchingLocation = false;
            });
            debugPrint("✅ Final Location Name: $locationName");
          } else {
            setState(() {
              _locationName = "Selected Location";
              _isFetchingLocation = false;
            });
          }
        } else {
          debugPrint("❌ Reverse geocoding failed with status: ${response.statusCode}");
          setState(() {
            _locationName = "Selected Location";
            _isFetchingLocation = false;
          });
        }
      } else {
        setState(() {
          _locationName = widget.alert.location;
          _isFetchingLocation = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error getting location name: $e");
      setState(() {
        _locationName = "Selected Location";
        _isFetchingLocation = false;
      });
    }
  }

  /// 🔰 NEW: Calculate dynamic time remaining based on dates and times
  void _calculateTimeRemaining() {
    try {
      debugPrint("📅 Calculating time remaining...");
      debugPrint("📅 Start Date: ${widget.alert.startDate}");
      debugPrint("📅 Expiry Date: ${widget.alert.expiryDate}");
      debugPrint("⏰ Start Time: ${widget.alert.startTime}");
      debugPrint("⏰ End Time: ${widget.alert.endTime}");

      // Parse dates and times
      final startDate = DateTime.parse(widget.alert.startDate);
      final expiryDate = DateTime.parse(widget.alert.expiryDate);
      
      // Parse times (handle both HH:mm and HH:mm:ss formats)
      final startTimeParts = widget.alert.startTime.split(':');
      final endTimeParts = widget.alert.endTime.split(':');
      
      final startDateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        int.parse(startTimeParts[0]),
        int.parse(startTimeParts[1]),
      );
      
      final endDateTime = DateTime(
        expiryDate.year,
        expiryDate.month,
        expiryDate.day,
        int.parse(endTimeParts[0]),
        int.parse(endTimeParts[1]),
      );

      debugPrint("📅 Start DateTime: $startDateTime");
      debugPrint("📅 End DateTime: $endDateTime");

      // Calculate total duration in minutes
      final totalDuration = endDateTime.difference(startDateTime).inMinutes;
      debugPrint("⏱️ Total Duration: $totalDuration minutes");

      // Calculate remaining time from now
      final now = DateTime.now();
      final remainingDuration = endDateTime.difference(now).inMinutes;
      debugPrint("⏱️ Remaining Duration: $remainingDuration minutes");

      // Format the remaining time
      if (remainingDuration <= 0) {
        setState(() => _timeRemaining = "Expired");
      } else if (remainingDuration < 60) {
        setState(() => _timeRemaining = "$remainingDuration mins left");
      } else if (remainingDuration < 1440) { // Less than 24 hours
        final hours = remainingDuration ~/ 60;
        final minutes = remainingDuration % 60;
        setState(() => _timeRemaining = "${hours}h ${minutes}m left");
      } else {
        final days = remainingDuration ~/ 1440;
        final hours = (remainingDuration % 1440) ~/ 60;
        setState(() => _timeRemaining = "${days}d ${hours}h left");
      }

      debugPrint("⏰ Formatted Time Remaining: $_timeRemaining");

    } catch (e) {
      debugPrint("❌ Error calculating time remaining: $e");
      setState(() => _timeRemaining = "Time calculation error");
    }
  }

  /// ✅ Check if this is a Last Minute Deal
  bool get _isLastMinuteDeal {
    return widget.alert.title.contains("LAST MINUTE DEALS") || 
           widget.alert.alertType == "last_minute";
  }

  /// ✅ Check if this is a Churppy Chain Alert
  bool get _isChainAlert {
    return widget.alert.title.contains("CHURPPY CHAIN ALERT") || 
           widget.alert.alertType == "chain";
  }

  /// ✅ Check if this is a Location Alert
  bool get _isLocationAlert {
    return widget.alert.title.contains("LOCATION ALERT") || 
           widget.alert.alertType == "location";
  }

  /// ✅ Check if this is a Custom Alert
  bool get _isCustomAlert {
    return widget.alert.title.contains("CUSTOMIZE ALERTS") || 
           widget.alert.alertType == "custom";
  }

  /// ✅ Check if discount is valid (not "0")
  bool get _hasValidDiscount {
    return widget.alert.discount != "0" && 
           widget.alert.discount.isNotEmpty;
  }

  /// ✅ Get appropriate description based on alert type
  String get _alertDescription {
    if (_isChainAlert) {
      return "Someone in your area just ordered from ${businessName.isNotEmpty ? businessName : "this business"}. Place your own order now!";
    } else if (_isLastMinuteDeal) {
      if (_hasValidDiscount) {
        return "We Cooked Too Much! Stop By ${businessName.isNotEmpty ? businessName : "our location"} by ${formatTime(widget.alert.endTime)} tonight and receive ${widget.alert.discount}!!";
      } else {
        return "We Cooked Too Much! Stop By ${businessName.isNotEmpty ? businessName : "our location"} by ${formatTime(widget.alert.endTime)} tonight for special deals!";
      }
    } else if (_isLocationAlert) {
      return "${businessName.isNotEmpty ? businessName : "We"} will be located at ${_isFetchingLocation ? "selected location" : _locationName} on ${formatDate(widget.alert.startDate)} from ${formatTime(widget.alert.startTime)} to ${formatTime(widget.alert.endTime)}. Look Forward to Seeing You!";
    } else if (_isCustomAlert) {
      return widget.alert.description.isNotEmpty 
          ? widget.alert.description 
          : "Custom alert message from ${businessName.isNotEmpty ? businessName : "our business"}.";
    } else {
      // Default description
      return widget.alert.description.isNotEmpty 
          ? widget.alert.description 
          : "${businessName.isNotEmpty ? businessName : "We"} will be at ${_isFetchingLocation ? "selected location" : _locationName} on ${formatDate(widget.alert.startDate)} from ${formatTime(widget.alert.startTime)} to ${formatTime(widget.alert.endTime)}.";
    }
  }

  /// ✅ Get appropriate icon based on alert type
  IconData get _alertIcon {
    if (_isChainAlert) return Icons.link_rounded;
    if (_isLastMinuteDeal) return Icons.flash_on_rounded;
    if (_isLocationAlert) return Icons.location_on_rounded;
    if (_isCustomAlert) return Icons.edit_rounded;
    return Icons.notifications_rounded;
  }

  /// ✅ Get appropriate icon color based on alert type
  Color get _alertIconColor {
    if (_isChainAlert) return Colors.blue.shade700;
    if (_isLastMinuteDeal) return Colors.orange.shade700;
    if (_isLocationAlert) return Colors.green.shade700;
    if (_isCustomAlert) return Colors.purple.shade700;
    return Colors.grey.shade700;
  }

  /// ✅ Get appropriate background color based on alert type
  Color get _alertBackgroundColor {
    if (_isChainAlert) return Colors.blue.shade50;
    if (_isLastMinuteDeal) return Colors.orange.shade50;
    if (_isLocationAlert) return Colors.green.shade50;
    if (_isCustomAlert) return Colors.purple.shade50;
    return Colors.grey.shade50;
  }

  /// ✅ Send Alert API call
  Future<void> _sendAlert({required int status}) async {
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("User ID not found")));
      return;
    }

    // We prefer the DB business name; if missing, we fallback to previous title
    final titleToSave = businessName.isNotEmpty ? businessName : widget.alert.title;

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(
          "https://churppy.eurekawebsolutions.com/api/admin_add_alert.php");
      final request = http.MultipartRequest('POST', uri);

      // ✅ UPDATED: Added location_name field for backend
      request.fields.addAll({
        'merchant_id': userId!,
        'title': titleToSave, // ✅ Save BUSINESS NAME instead of alert title
        'description': widget.alert.description,
        'location': widget.alert.location, // 🔰 Original coordinates
        'location_name': _locationName, // 🔰 NEW: Derived location name
        'start_date': widget.alert.startDate,
        'expiry_date': widget.alert.expiryDate,
        'start_time': widget.alert.startTime,
        'end_time': widget.alert.endTime,
        'radius': widget.alert.radius.toString(),
        'status': status.toString(), // ✅ 1=Approve, 0=Save for Later
        'alert_type': widget.alert.alertType,
        'discount': widget.alert.discount, // ✅ Send discount to API
      });

      // ✅ Image Handling (file vs existing filename)
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
          request.fields['existing_image'] =
              widget.alert.imageName.split('/').last;
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
          final alertStatus = jsonData['status'] ?? status;

          // ✅ UPDATED: Different success messages based on status
          final successMessage = status == 1 
              ? "Alert created and activated successfully!" 
              : "Alert saved as draft successfully!";

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
                    // ✅ UPDATED: Different icon based on status
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: status == 1 ? Colors.green.shade50 : Colors.blue.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: status == 1 ? Colors.green.shade200 : Colors.blue.shade200, 
                          width: 3
                        ),
                      ),
                      child: Icon(
                        status == 1 ? Icons.check_rounded : Icons.save_rounded,
                        color: status == 1 ? Color(0xFF8BC34A) : Colors.blue.shade600,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                   
                    Text(
                      successMessage,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    // ✅ Only show remaining alerts for APPROVED alerts
                   // ✅ Show remaining alerts for both APPROVE (1) and SAVE FOR LATER (0)
if ((status == 1 || status == 0) && remain != null && max != null)
  Column(
    children: [
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
    ],
  ),

                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          // Optional: Navigate back or reset
                          if (mounted) {
                            Navigator.pop(context); // Go back to previous screen
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: status == 1 ? Color(0xFF8BC34A) : Colors.blue.shade600,
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

            // ✅ Navigate to PaymentScreen and FORCE create alert (only for Approve)
           // ✅ Navigate to PaymentScreen and FORCE create alert (for Approve or Save for Later)
if (status == 1 || status == 0) {
  Future.delayed(const Duration(milliseconds: 600), () {
    if (mounted) {
      Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => PaymentScreen(
      alert: widget.alert,
      status: status, // ✅ Pass status (1 or 0)
      key: const ValueKey("force_create_alert"),
    ),
  ),
);

    }
  });
}

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
            child: Column(
              children: [
                Expanded(
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

                            // ✅ NEW: Discount Display Card (Only for Last Minute Deals with valid discount)
                            if (_isLastMinuteDeal && _hasValidDiscount)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.orange.shade50,
                                        Colors.red.shade50,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.shade200,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.local_offer_rounded,
                                          color: Colors.orange.shade700,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'SPECIAL OFFER',
                                              style: GoogleFonts.roboto(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.orange.shade700,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              widget.alert.discount,
                                              style: GoogleFonts.roboto(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red.shade700,
                                              ),
                                            ),
                                            Text(
                                              'Last Minute Deal',
                                              style: GoogleFonts.roboto(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            if (_isLastMinuteDeal && _hasValidDiscount)
                              const SizedBox(height: 16),

                            // ✅ UPDATED: Alert Details Card with dynamic content based on alert type
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                  color: _alertBackgroundColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Alert Type Header
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: _alertIconColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            _alertIcon,
                                            color: _alertIconColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getAlertTypeTitle(),
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: _alertIconColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: Image.network(
                                              _abs(widget.alert.imageName),
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: Colors.grey.shade100,
                                                child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                businessName.isNotEmpty ? businessName : "Loading...",
                                                style: GoogleFonts.roboto(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _alertDescription,
                                                style: GoogleFonts.roboto(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                  height: 1.4,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              if (_isLocationAlert || _isLastMinuteDeal || _isCustomAlert)
                                                Row(
                                                  children: [
                                                    Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        _isFetchingLocation ? "Loading location..." : _locationName,
                                                        style: GoogleFonts.roboto(
                                                          fontSize: 11,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (_isLocationAlert || _isLastMinuteDeal || _isCustomAlert)
                                                const SizedBox(height: 4),
                                              if (_isLocationAlert || _isLastMinuteDeal || _isCustomAlert)
                                                Row(
                                                  children: [
                                                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _timeRemaining,
                                                      style: GoogleFonts.roboto(
                                                        fontSize: 11,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: Text(
                                          _timeRemaining,
                                          style: GoogleFonts.roboto(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ✅ UPDATED: Buttons with proper status
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 2),
                              child: _styledButton("APPROVE", Colors.green, () {
                                _sendAlert(status: 1); // ✅ Status 1 for Active
                              }),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 6),
                              child: _styledButton("SAVE FOR LATER", Colors.blue.shade700,
                                  () {
                                _sendAlert(status: 0); // ✅ Status 0 for Draft
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

                            const SizedBox(height: 20),

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

                /// 🔰 NEW: Back Arrow Section (Exactly like Drawer)
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

  /// ✅ Get alert type title for display
  String _getAlertTypeTitle() {
    if (_isChainAlert) return "CHURPPY CHAIN ALERT";
    if (_isLastMinuteDeal) return "LAST MINUTE DEAL";
    if (_isLocationAlert) return "LOCATION ALERT";
    if (_isCustomAlert) return "CUSTOM ALERT";
    return "ALERT";
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
                                          size: 70, color: Colors.grey);
                                    },
                                  ),
                                )
                              : const Icon(Icons.person,
                                  size: 70, color: Colors.grey),
                        ),
        ],
      ),
    );
  }

  Widget _styledButton(String text, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}