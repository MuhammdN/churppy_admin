import 'dart:convert';
import 'dart:io';
import 'package:churppy_admin/screens/contactUsScreen.dart';
import 'package:churppy_admin/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import 'drawer.dart';
import 'Review_Churppy_Screen.dart';

/// 🔰 Alert Model
class AlertModel {
  final String merchantId;
  final String title;
  final String description;
  final String location;
  final String startDate;
  final String expiryDate;
  final String startTime;
  final String endTime;
  final String radius;
  final String imageName;
  final String alertType; // ✅ New field
  final String discount; // ✅ UPDATED: Now required field with "0" as default

  AlertModel({
    required this.merchantId,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    required this.expiryDate,
    required this.startTime,
    required this.endTime,
    required this.radius,
    required this.imageName,
    required this.alertType,
    required this.discount, // ✅ UPDATED: Now required
  });
}

/// 🔰 UPDATED: New AddressAutocompleteField with country restriction and current location
class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  const AddressAutocompleteField({super.key, required this.controller});

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  String? _currentCountryCode;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getUserLocationAndCountry();
  }

  // 🧭 Current location & country
  Future<void> _getUserLocationAndCountry() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _currentPosition = pos;

    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json');
    final resp = await http.get(uri, headers: {
      'User-Agent': 'ChurppyAdmin/1.0 (admin@churppy.com)',
    });

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      final countryCode = data['address']?['country_code']?.toString().toUpperCase();
      setState(() {
        _currentCountryCode = countryCode;
        // Auto-fill address with current location
        widget.controller.text = data['display_name'] ?? '';
      });
    }
  }

  // 📍 Fetch suggestions limited to current country
  Future<List<Map<String, dynamic>>> fetchSuggestions(String query) async {
    if (query.isEmpty || _currentCountryCode == null) return [];

    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&countrycodes=${_currentCountryCode!.toLowerCase()}&format=json&addressdetails=1&limit=6');

    final resp = await http.get(uri, headers: {
      'User-Agent': 'ChurppyAdmin/1.0 (admin@churppy.com)',
    });

    if (resp.statusCode == 200) {
      final List data = json.decode(resp.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  }

  // 📍 Use current location (lat,lon)
  Future<void> useCurrentLocation() async {
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      widget.controller.text = "${pos.latitude},${pos.longitude}";
    });
    _getUserLocationAndCountry();
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<Map<String, dynamic>>(
      controller: widget.controller,
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: "Search Address",
            hintStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            errorText: null,
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: useCurrentLocation,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(width: 2, color: Colors.black),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
      },
      suggestionsCallback: fetchSuggestions,
      itemBuilder: (context, suggestion) {
        final addr = suggestion['address'] ?? {};
        final street = [
          addr['road'],
          addr['pedestrian'],
          addr['footway'],
          addr['residential']
        ].where((e) => e != null).join(", ");

        final locality = [
          addr['suburb'],
          addr['city'],
          addr['town'],
          addr['village']
        ].where((e) => e != null).join(", ");

        final display = [street, locality]
            .where((e) => e.isNotEmpty)
            .join(", ");

        return ListTile(
          title: Text(display.isNotEmpty
              ? display
              : suggestion['display_name'] ?? ''),
        );
      },
      onSelected: (suggestion) {
        final addr = suggestion['address'] ?? {};
        final street = [
          addr['road'],
          addr['pedestrian'],
          addr['footway'],
          addr['residential']
        ].where((e) => e != null).join(", ");

        final locality = [
          addr['suburb'],
          addr['city'],
          addr['town'],
          addr['village']
        ].where((e) => e != null).join(", ");

        final display = [street, locality]
            .where((e) => e.isNotEmpty)
            .join(", ");

        setState(() {
          widget.controller.text = display.isNotEmpty
              ? display
              : suggestion['display_name'] ?? '';
        });
      },
      emptyBuilder: (context) => const ListTile(
        title: Text('No results found'),
      ),
    );
  }
}

class LocationAlertStep2Screen extends StatefulWidget {
  final String alertTitle;
  final String alertDescription;
  final String alertType; // ✅ New field

  const LocationAlertStep2Screen({
    super.key,
    required this.alertTitle,
    required this.alertDescription,
    required this.alertType,
  });

  @override
  State<LocationAlertStep2Screen> createState() =>
      _LocationAlertStep2ScreenState();
}

class _LocationAlertStep2ScreenState extends State<LocationAlertStep2Screen> {
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _firstDayCtrl = TextEditingController();
  final TextEditingController _lastDayCtrl = TextEditingController();
  final TextEditingController _timeStartCtrl = TextEditingController();
  final TextEditingController _timeEndCtrl = TextEditingController();

  /// 🔹 NEW controllers for custom alerts
  final TextEditingController _customTitleCtrl = TextEditingController();
  final TextEditingController _customDescCtrl = TextEditingController();

  // ✅ UPDATED: Default value "0" for discount
  String _selectedDiscount = "0";

  // ✅ Discount options
  final List<String> _discountOptions = [
    '0', // ✅ Default value
    '10% OFF',
    '15% OFF', 
    '20% OFF',
    '25% OFF',
    '30% OFF',
    '35% OFF',
    '40% OFF',
    '45% OFF',
    '50% OFF'
  ];

  String? userId;
  String? profileImage; // ✅ ADDED FOR PROFILE IMAGE
  String? firstName;    // ✅ ADDED FOR USER NAME
  String? lastName;     // ✅ ADDED FOR USER NAME
  String? imageName;
  String? _existingImageUrl; // 🔰 NEW: Store existing image URL from database
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  // 🔰 NEW: Loading state variables
  bool _isImageUploading = false;
  bool _isInitialLoading = true;

  bool get isCustom => widget.alertType == "custom";
  bool get isLastMinuteDeal => widget.alertTitle.contains("LAST MINUTE DEALS");

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString("user_id");
    setState(() => userId = savedUserId);
    debugPrint("✅ Logged-in User ID (LocationAlertStep2Screen): $savedUserId");

    if (savedUserId != null) {
      await _fetchUserDetails(savedUserId);
      await _fetchUserProfile(savedUserId); // ✅ ADDED FOR PROFILE DATA
    }
    
    // 🔰 Hide initial loader after data is loaded
    setState(() {
      _isInitialLoading = false;
    });
  }

  /// ✅ NEW: Fetch User Profile for Header
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

  Future<void> _fetchUserDetails(String id) async {
    try {
      final url = Uri.parse(
          "https://churppy.eurekawebsolutions.com/api/user_with_merchant.php?id=$id");

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final userData = data['data'];

          setState(() {
            imageName = userData['image'] != null &&
                    userData['image'].toString().isNotEmpty
                ? userData['image'].toString().split('/').last
                : null;
            
            // 🔰 NEW: Store the complete image URL for preview
            _existingImageUrl = userData['image'] != null &&
                    userData['image'].toString().isNotEmpty
                ? userData['image'].toString()
                : null;
          });

          debugPrint("🖼️ Current Image (from DB): $imageName");
          debugPrint("🖼️ Existing Image URL: $_existingImageUrl");
        }
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
    }
  }

  /// ✅ Upload image to server and print status in console
  Future<void> _uploadImageToServer(String userId) async {
    if (_pickedImage == null) return;

    setState(() {
      _isImageUploading = true;
    });

    try {
      final uri = Uri.parse(
          "https://churppy.eurekawebsolutions.com/api/user_with_merchant.php");
      final request = http.MultipartRequest('POST', uri);
      request.fields['id'] = userId;
      request.files
          .add(await http.MultipartFile.fromPath('image', _pickedImage!.path));

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final jsonResp = json.decode(respStr);

      if (jsonResp['status'] == 'success') {
        debugPrint("✅ Image uploaded successfully!");
        // 🔰 Update existing image URL after successful upload
        if (jsonResp['data'] != null && jsonResp['data']['image'] != null) {
          setState(() {
            _existingImageUrl = jsonResp['data']['image'];
          });
        }
      } else {
        debugPrint("❌ Image upload failed: ${jsonResp['message']}");
      }
    } catch (e) {
      debugPrint("⚠️ Upload Exception: $e");
    } finally {
      setState(() {
        _isImageUploading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _pickedImage = File(picked.path);
      imageName = picked.name;
    });

    debugPrint("📸 Image selected: $imageName");

    if (userId != null) {
      await _uploadImageToServer(userId!);
    } else {
      debugPrint("⚠️ Cannot upload — userId is null!");
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      String formatted =
          "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      controller.text = formatted;
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final now = DateTime.now();
      final dt =
          DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      String formatted =
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00";
      controller.text = formatted;
    }
  }

  // ✅ UPDATED: Single validation for both date and time (72 hours max, 10 minutes min)
  String? _validateDateTime() {
    if (_firstDayCtrl.text.isEmpty || _lastDayCtrl.text.isEmpty || 
        _timeStartCtrl.text.isEmpty || _timeEndCtrl.text.isEmpty) {
      return null;
    }
    
    try {
      // Combine date and time
      final startDateTime = DateTime.parse("${_firstDayCtrl.text} ${_timeStartCtrl.text}");
      final endDateTime = DateTime.parse("${_lastDayCtrl.text} ${_timeEndCtrl.text}");
      
      final totalDuration = endDateTime.difference(startDateTime);
      
      debugPrint("⏰ Total Duration: ${totalDuration.inHours} hours ${totalDuration.inMinutes.remainder(60)} minutes");
      
      // Check minimum 10 minutes
      if (totalDuration.inMinutes < 10) {
        return "⚠️ Minimum alert duration should be 10 minutes";
      }
      
      // Check maximum 72 hours (3 days)
      if (totalDuration.inHours > 72) {
        return "⚠️ Maximum alert duration should be 72 hours (3 days)";
      }
      
      return null;
    } catch (e) {
      debugPrint("❌ DateTime validation error: $e");
      return "⚠️ Invalid date/time format";
    }
  }

  void _sendChurppyAlert() {
    // ✅ UPDATED: No need to check discount separately, always sends "0" or selected discount

    if (userId == null ||
        _addressCtrl.text.isEmpty ||
        _firstDayCtrl.text.isEmpty ||
        _lastDayCtrl.text.isEmpty ||
        _timeStartCtrl.text.isEmpty ||
        _timeEndCtrl.text.isEmpty ||
        imageName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ All fields are required")),
      );
      return;
    }

    // ✅ UPDATED: Single date-time validation
    final dateTimeError = _validateDateTime();
    if (dateTimeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dateTimeError)),
      );
      return;
    }

    // 🔰 Don't proceed if image is still uploading
    if (_isImageUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please wait for image to finish uploading")),
      );
      return;
    }

    final titleToSend = isCustom
        ? (_customTitleCtrl.text.isNotEmpty
            ? _customTitleCtrl.text
            : "Custom Alert")
        : widget.alertTitle;
    
    final descToSend = isCustom
        ? (_customDescCtrl.text.isNotEmpty
            ? _customDescCtrl.text
            : "Custom alert description")
        : widget.alertDescription;

    final alert = AlertModel(
      merchantId: userId!,
      title: titleToSend,
      description: descToSend,
      location: _addressCtrl.text,
      startDate: _firstDayCtrl.text,
      expiryDate: _lastDayCtrl.text,
      startTime: _timeStartCtrl.text,
      endTime: _timeEndCtrl.text,
      radius: "7 miles",
      imageName: imageName!,
      alertType: widget.alertType,
      discount: _selectedDiscount, // ✅ UPDATED: Always sends value ("0" or selected discount)
    );

    debugPrint("📦 Going to Review screen with alertType: ${alert.alertType}");
    debugPrint("💰 Discount being sent: ${_selectedDiscount}");

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReviewChurppyScreen(alert: alert)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                    /// 🔰 Top Header - UPDATED WITH PROFILE IMAGE
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Builder(
                                builder: (context) => GestureDetector(
                                  onTap: () => Scaffold.of(context).openDrawer(),
                                  child: Image.asset('assets/icons/menu.png',
                                      width: 40, height: 40),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Image.asset('assets/images/logo.png', width: 100),
                            ],
                          ),

                          /// ✅ RIGHT — PROFILE IMAGE (TAPPABLE)
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

                    /// 🔰 Alert Banner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: _sendChurppyAlert,
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

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Dynamic Title
                            Text(
                              widget.alertTitle,
                              style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.purple),
                            ),
                            const SizedBox(height: 4),
                            Text("STEP 2 - ENTER LOCATION, DAY(S) AND HOURS",
                                style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.bold, fontSize: 16)),

                            const SizedBox(height: 16),

                            /// ✅ If CUSTOM, show text fields for user input
                            if (isCustom) ...[
                              TextField(
                                controller: _customTitleCtrl,
                                decoration: const InputDecoration(
                                    labelText: "Enter Custom Alert Title",
                                    border: OutlineInputBorder()),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _customDescCtrl,
                                decoration: const InputDecoration(
                                    labelText: "Enter Custom Alert Description",
                                    border: OutlineInputBorder()),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                            ],

                            /// ✅ ALWAYS SHOW THE SELECTED ALERT DESCRIPTION (for both custom and pre-defined alerts)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(6),
                                color: Colors.grey.shade100,
                              ),
                              child: Row(
                                children: [
                                  profileImage != null
          ? ClipRRect(
             borderRadius: BorderRadius.zero,
              child: Image.network(
                profileImage!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) {
                  return const Icon(Icons.person, size: 40, color: Colors.grey);
                },
              ),
            )
          : const Icon(Icons.person, size: 40, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.alertDescription, // ✅ This will show the selected alert description
                                      style: GoogleFonts.roboto(
                                          fontSize: 12, color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ✅ UPDATED: Discount Dropdown for Last Minute Deals (always shows "0" as default)
                            if (isLastMinuteDeal) ...[
                              Text("SELECT DISCOUNT",
                                  style: GoogleFonts.roboto(
                                      fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedDiscount,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  hint: const Text("Choose Discount"),
                                  items: _discountOptions.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value == "0" ? "No Discount" : value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedDiscount = newValue ?? "0";
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            Text(
                              "LOCATION IS SET TO DEFAULT ADDRESS.\nYou can change location to Where You Are NOW, Where You Will be OR PROMOTE IN A ZIP CODE.",
                              style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "NOTE: Alerts are sent to customers within 7 miles from location",
                              style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 16),

                            // ✅ UPDATED: New AddressAutocompleteField with all features from SignupScreen
                            SizedBox(
                              height: 50,
                              child: AddressAutocompleteField(
                                  controller: _addressCtrl),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: const [
                                Text("ENTER DAYS",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(width: 6),
                                Icon(Icons.calendar_today,
                                    size: 18, color: Colors.red),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _firstDayCtrl,
                                    readOnly: true,
                                    onTap: () => _pickDate(_firstDayCtrl),
                                    style: GoogleFonts.inter(fontSize: 12),
                                    decoration: const InputDecoration(
                                      hintText: "FIRST DAY",
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _lastDayCtrl,
                                    readOnly: true,
                                    onTap: () => _pickDate(_lastDayCtrl),
                                    style: GoogleFonts.inter(fontSize: 12),
                                    decoration: const InputDecoration(
                                      hintText: "LAST DAY",
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: const [
                                Text("ENTER TIME",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(width: 6),
                                Icon(Icons.access_time,
                                    size: 18, color: Colors.red),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _timeStartCtrl,
                                    readOnly: true,
                                    onTap: () => _pickTime(_timeStartCtrl),
                                    style: GoogleFonts.inter(fontSize: 12),
                                    decoration: const InputDecoration(
                                      hintText: "START",
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _timeEndCtrl,
                                    readOnly: true,
                                    onTap: () => _pickTime(_timeEndCtrl),
                                    style: GoogleFonts.inter(fontSize: 12),
                                    decoration: const InputDecoration(
                                      hintText: "END",
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // ✅ UPDATED: Single date-time validation message
                            if (_validateDateTime() != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _validateDateTime()!,
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            const SizedBox(height: 16),

                            // =================== IMAGE UPLOAD SECTION ===================
                            Text("IMAGE",
                                style: GoogleFonts.roboto(
                                    fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _isImageUploading ? null : _pickImage,
                                    child: Container(
                                      height: 45,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _isImageUploading
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade200,
                                        border: Border.all(color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        imageName ?? "No file selected",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: _isImageUploading
                                              ? Colors.grey.shade600
                                              : Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _isImageUploading ? null : _pickImage,
                                    child: Container(
                                      height: 45,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _isImageUploading
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade200,
                                        border: Border.all(color: Colors.grey.shade400),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: _isImageUploading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(Colors.black),
                                              ),
                                            )
                                          : const Text("Upload"),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // ✅ Responsive image preview card - Show both existing and newly uploaded images
                            if (_existingImageUrl != null || _pickedImage != null) ...[
                              const SizedBox(height: 16),
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Image Preview",
                                        style: GoogleFonts.roboto(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // 🔰 Show newly picked image if available, otherwise show existing image from database
                                      if (_pickedImage != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.file(
                                            _pickedImage!,
                                            width: MediaQuery.of(context).size.width * 0.8,
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      else if (_existingImageUrl != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            _existingImageUrl!,
                                            width: MediaQuery.of(context).size.width * 0.8,
                                            fit: BoxFit.contain,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                width: MediaQuery.of(context).size.width * 0.8,
                                                height: 200,
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                            loadingProgress.expectedTotalBytes!
                                                        : null,
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: MediaQuery.of(context).size.width * 0.8,
                                                height: 200,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.error_outline, color: Colors.red, size: 40),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      'Failed to load image',
                                                      style: GoogleFonts.roboto(
                                                        fontSize: 12,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),
                            Center(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const ContactUsScreen()),
                                  );
                                },
                                child: Text(
                                  "CONTACT US",
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
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
          ),
        ),

        /// 🔰 Overlay Loader - Shows on top of the screen
        if (_isInitialLoading || _isImageUploading)
          Container(
            color: Colors.black.withOpacity(0.5), // Semi-transparent background
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8BC34A)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isImageUploading ? "Uploading Image..." : "Loading...",
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}