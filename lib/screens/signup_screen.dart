import 'dart:convert';
import 'package:churppy_admin/screens/login.dart';
import 'package:churppy_admin/screens/otp_verify.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import '../routes.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool isLoading = false;
  Country? selectedCountry;

  // Controllers
  final TextEditingController businessNameCtrl = TextEditingController();
  final TextEditingController businessAddressCtrl = TextEditingController();
  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();

  final Map<String, String?> _errors = {};

  String? _currentCountryCode;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    selectedCountry = Country(
      phoneCode: '1',
      countryCode: 'US',
      e164Sc: 0,
      geographic: true,
      level: 1,
      name: 'United States',
      example: '',
      displayName: 'United States',
      displayNameNoCountryCode: 'United States',
      e164Key: '',
    );
    _getUserLocationAndCountry();
  }

  // 🧭 Fetch current location + country
  Future<void> _getUserLocationAndCountry() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location permissions are permanently denied')),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _currentPosition = pos;

    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json');
    final resp = await http.get(uri, headers: {
      'User-Agent': 'ChurppyAdmin/1.0 (admin@churppy.com)',
    });

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      final countryCode =
          data['address']?['country_code']?.toString().toUpperCase();

      setState(() {
        _currentCountryCode = countryCode;
        businessAddressCtrl.text = data['display_name'] ?? '';
      });
    }
  }

  // 📍 Address suggestions per country
  Future<List<Map<String, dynamic>>> fetchSuggestions(String query) async {
    if (query.isEmpty || _currentCountryCode == null) return [];

    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}'
        '&countrycodes=${_currentCountryCode!.toLowerCase()}'
        '&format=json&addressdetails=1&limit=6');

    final resp = await http.get(uri, headers: {
      'User-Agent': 'ChurppyAdmin/1.0 (admin@churppy.com)',
    });

    if (resp.statusCode == 200) {
      final List data = json.decode(resp.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // 📍 Set address to GPS location
  Future<void> useCurrentLocation() async {
    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      businessAddressCtrl.text = "${pos.latitude},${pos.longitude}";
    });
    _getUserLocationAndCountry();
  }

  // Validation
  bool _validateInputs() {
    _errors.clear();

    if (businessNameCtrl.text.trim().isEmpty) {
      _errors['businessName'] = "Business Name is required";
    }
    if (firstNameCtrl.text.trim().isEmpty) {
      _errors['firstName'] = "First name is required";
    }
    if (lastNameCtrl.text.trim().isEmpty) {
      _errors['lastName'] = "Last name is required";
    }
    if (emailCtrl.text.trim().isEmpty) {
      _errors['email'] = "Email is required";
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
        .hasMatch(emailCtrl.text.trim())) {
      _errors['email'] = "Enter a valid email";
    }
    if (passwordCtrl.text.trim().isEmpty) {
      _errors['password'] = "Password is required";
    } else if (passwordCtrl.text.trim().length < 6) {
      _errors['password'] = "Password must be at least 6 characters";
    }
    if (businessAddressCtrl.text.trim().isEmpty) {
      _errors['address'] = "Business Address is required";
    }
    if (phoneCtrl.text.trim().isEmpty) {
      _errors['phone'] = "Phone number is required";
    }

    setState(() {});
    return _errors.isEmpty;
  }

  // ⭐ STEP-1: Send Admin OTP (NOT final signup)
  Future<void> _signup() async {
    if (!_validateInputs()) return;

    setState(() => isLoading = true);

    final url = Uri.parse(
        "https://churppy.eurekawebsolutions.com/api/send_admin_otp.php");

    final requestBody = {
      "firstname": firstNameCtrl.text.trim(),
      "lastname": lastNameCtrl.text.trim(),
      "email": emailCtrl.text.trim(),
      "password": passwordCtrl.text.trim(),
      "user_phone":
          "+${selectedCountry?.phoneCode ?? '1'}${phoneCtrl.text.trim()}",
      "business_name": businessNameCtrl.text.trim(),
      "address": businessAddressCtrl.text.trim(),
    };

    try {
      final response = await http.post(url, body: requestBody);
      final result = json.decode(response.body);

      print("📩 ADMIN SEND OTP Request: $requestBody");
      print("📩 ADMIN SEND OTP Response: ${response.body}");

      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ OTP sent to your email")),
        );

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminOTPVerifyScreen(
              firstname: firstNameCtrl.text.trim(),
              lastname: lastNameCtrl.text.trim(),
              email: emailCtrl.text.trim(),
              password: passwordCtrl.text.trim(),
              phone:
                  "+${selectedCountry?.phoneCode ?? '1'}${phoneCtrl.text.trim()}",
              address: businessAddressCtrl.text.trim(),
              businessName: businessNameCtrl.text.trim(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${result['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ======================= UI ========================

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final maxCardW = w.clamp(320.0, 440.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxCardW),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 30),

                    // Logo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: maxCardW * 0.5,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            _field("Business Name", businessNameCtrl,
                                error: _errors['businessName']),

                            // ===================== Address Field =====================
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TypeAheadField<
                                  Map<String, dynamic>>(
                                controller: businessAddressCtrl,
                                suggestionsCallback: fetchSuggestions,
                                builder:
                                    (context, controller, focusNode) {
                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                      hintText: 'Business Address',
                                      errorText: _errors['address'],
                                      suffixIcon: IconButton(
                                        icon: const Icon(
                                            Icons.my_location),
                                        onPressed: useCurrentLocation,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12),
                                    ),
                                  );
                                },
                                itemBuilder:
                                    (context, suggestion) {
                                  final addr =
                                      suggestion['address'] ?? {};
                                  final street = [
                                    addr['road'],
                                    addr['pedestrian'],
                                    addr['footway'],
                                    addr['residential']
                                  ]
                                      .where((e) => e != null)
                                      .join(", ");

                                  final locality = [
                                    addr['suburb'],
                                    addr['city'],
                                    addr['town'],
                                    addr['village']
                                  ]
                                      .where((e) => e != null)
                                      .join(", ");

                                  final display = [
                                    street,
                                    locality
                                  ]
                                      .where((e) => e.isNotEmpty)
                                      .join(", ");

                                  return ListTile(
                                    title: Text(
                                      display.isNotEmpty
                                          ? display
                                          : suggestion[
                                                  'display_name'] ??
                                              '',
                                    ),
                                  );
                                },
                                onSelected:
                                    (suggestion) {
                                  final addr =
                                      suggestion['address'] ?? {};
                                  final street = [
                                    addr['road'],
                                    addr['pedestrian'],
                                    addr['footway'],
                                    addr['residential']
                                  ]
                                      .where((e) => e != null)
                                      .join(", ");

                                  final locality = [
                                    addr['suburb'],
                                    addr['city'],
                                    addr['town'],
                                    addr['village']
                                  ]
                                      .where((e) => e != null)
                                      .join(", ");

                                  final display = [
                                    street,
                                    locality
                                  ]
                                      .where((e) => e.isNotEmpty)
                                      .join(", ");

                                  setState(() {
                                    businessAddressCtrl.text =
                                        display.isNotEmpty
                                            ? display
                                            : suggestion[
                                                    'display_name'] ??
                                                '';
                                  });
                                },
                                emptyBuilder: (context) =>
                                    const ListTile(
                                      title:
                                          Text('No results found'),
                                    ),
                              ),
                            ),

                            // ===================== Remaining Fields =====================
                            _field("First Name", firstNameCtrl,
                                error: _errors['firstName']),
                            _field("Last Name", lastNameCtrl,
                                error: _errors['lastName']),
                            _field("Email", emailCtrl,
                                error: _errors['email']),
                            _field("Password", passwordCtrl,
                                obscure: true,
                                error: _errors['password']),

                            const Text(
                              'Enter your mobile number',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                InkWell(
                                  onTap: () =>
                                      _showCountryPicker(context),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Color(0xFFBDBDBD)),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          selectedCountry
                                                  ?.flagEmoji ??
                                              '🌎',
                                          style: const TextStyle(
                                              fontSize: 20),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '+${selectedCountry?.phoneCode ?? ''}',
                                          style: const TextStyle(
                                              fontSize: 14),
                                        ),
                                        const Icon(
                                            Icons.arrow_drop_down,
                                            size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: phoneCtrl,
                                    keyboardType:
                                        TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: 'Phone Number',
                                      errorText: _errors['phone'],
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  6)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ===================== Continue Button =====================
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 48,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF804692),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                              onPressed:
                                  isLoading ? null : _signup,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child:
                                          CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Continue'),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: const [
                              Expanded(
                                  child: Divider(
                                      color: Colors.grey)),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8),
                                child: Text('or',
                                    style: TextStyle(
                                        color: Colors.black54)),
                              ),
                              Expanded(
                                  child: Divider(
                                      color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Center(
                            child: GestureDetector(
                              onTap: () =>
                                  Navigator.pushReplacementNamed(
                                      context, Routes.login),
                              child: const Text.rich(
                                TextSpan(
                                  text:
                                      'If you already have an account, ',
                                  style: TextStyle(
                                      color: Colors.black87),
                                  children: [
                                    TextSpan(
                                      text: 'login.',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.w700,
                                        decoration:
                                            TextDecoration
                                                .underline,
                                      ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===================== BACK BUTTON =====================
            Positioned(
              left: 10,
              bottom: 42,
              child: InkWell(
                onTap: () =>
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LoginScreen()),
                    ),
                borderRadius:
                    BorderRadius.circular(100),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE0E0E0),
                  ),
                  child:
                      const Icon(Icons.arrow_back, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔶 Reusable field widget
  Widget _field(String hint, TextEditingController ctrl,
      {bool obscure = false, String? error}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          errorText: error,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // 🔶 Country picker
  void _showCountryPicker(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() {
          selectedCountry = country;
        });
      },
    );
  }
}
