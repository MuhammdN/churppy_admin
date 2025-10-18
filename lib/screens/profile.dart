import 'dart:convert';
import 'dart:io';
import 'package:churppy_admin/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Data
  String _firstName = "";
  String _lastName = "";
  String _email = "";
  String _address = "";
  String _phoneNumber = "";
  String _password = "●●●●●●●●"; // display only
  String _profileImage = "";
  File? _selectedImage;
  bool _isEditing = false;
  bool _isLoading = false;
  int? _userId;

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController =
  TextEditingController(text: "●●●●●●●●"); // static look

  // Theme tokens
  final Color _purple = const Color(0xFF804692);
  final Color _green = const Color(0xFF6DC24B);
  final Color _chipBg = const Color(0xFFF6F6F6);

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchData();
  }

  Future<void> _loadUserIdAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");
    if (userId != null) {
      setState(() {
        _userId = int.tryParse(userId);
      });
      if (_userId != null) {
        await _fetchUserDataFromServer(_userId!);
      }
    }
  }

  Future<void> _fetchUserDataFromServer(int userId) async {
    setState(() => _isLoading = true);
    try {
      final url =
          'https://churppy.eurekawebsolutions.com/api/user.php?id=$userId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          final user = responseData['data'];
          setState(() {
            _firstName = user['first_name'] ?? "";
            _lastName = user['last_name'] ?? "";
            _email = user['email'] ?? "";
            _address = user['address'] ?? "";
            _phoneNumber = user['phone_number'] ?? "";
            _profileImage = user['image'] ?? "";

            _firstNameController.text = "$_firstName $_lastName";
            _lastNameController.text = _lastName;
            _emailController.text = _email;
            _addressController.text = _address;
            _phoneController.text = _phoneNumber;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading profile: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
        await _uploadImageToServer(_selectedImage!);
      }
    } catch (e) {
      debugPrint("Pick error: $e");
    }
  }

  Future<void> _uploadImageToServer(File imageFile) async {
    if (_userId == null) return;
    setState(() => _isLoading = true);
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('https://churppy.eurekawebsolutions.com/api/user.php'),
      );
      req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      req.fields['id'] = _userId.toString();

      final res = await req.send();
      final body = await res.stream.bytesToString();
      final jsonRes = jsonDecode(body);

      if (res.statusCode == 200 && jsonRes['status'] == 'success') {
        setState(() => _profileImage = jsonRes['imageUrl']);
      }
    } catch (e) {
      debugPrint("Upload error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserData() async {
    if (_userId == null) return;
    setState(() => _isLoading = true);
    try {
      final url =
      Uri.parse('https://churppy.eurekawebsolutions.com/api/user.php');
      final req = http.MultipartRequest('POST', url);
      req.fields['id'] = _userId.toString();
      req.fields['first_name'] = _firstNameController.text;
      req.fields['last_name'] = _lastNameController.text;
      req.fields['email'] = _emailController.text;
      req.fields['address'] = _addressController.text;
      req.fields['phone_number'] = _phoneController.text;

      if (_selectedImage != null) {
        req.files.add(
            await http.MultipartFile.fromPath('image', _selectedImage!.path));
      }

      final res = await req.send();
      final body = await res.stream.bytesToString();
      final jsonRes = jsonDecode(body);

      if (res.statusCode == 200 && jsonRes['status'] == 'success') {
        setState(() {
          _profileImage = jsonRes['image'] ?? _profileImage;
          _isEditing = false;
        });
      }
    } catch (e) {
      debugPrint("Save error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _green),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final poppins = GoogleFonts.poppins();
    final roboto = GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    );

    return Scaffold(
      backgroundColor: _purple,
      body: SafeArea(
        child: _isLoading
            ? const Center(
            child: CircularProgressIndicator(color: Colors.white))
            : Column(
          children: [
            // Top bar
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings,
                        color: Colors.white, size: 20),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ✅ Profile image (Square)
            GestureDetector(
              onTap: _isEditing ? _pickImage : null,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: _green, width: 3),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: _green.withOpacity(0.5),
                        blurRadius: 14,
                        spreadRadius: 1),
                  ],
                  image: DecorationImage(
                    image: _getProfileImage(),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Card body
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ✅ CHURPPY Heading inside Card
                      Row(
                        children: [
                          Expanded(
                            child: Text("CHURPPY", style: roboto),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 22, color: Colors.black54),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _labeledField("Name",
                          controller: _firstNameController,
                          hint: "Name",
                          textStyle: poppins),
                      _labeledField("Email",
                          controller: _emailController,
                          hint: "email@churppy.com",
                          textStyle: poppins),
                      _labeledField("Address",
                          controller: _addressController,
                          hint: "Your address",
                          textStyle: poppins),
                      _passwordField(poppins),

                      const SizedBox(height: 6),
                      const Divider(),

                      // Section with buttons
                      _staticRow("Product Details", poppins,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Product Details tapped")),
                            );
                          }),
                      _staticRow("Churppy Alerts History and MORE",
                          poppins, onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                  Text("Churppy Alerts History tapped")),
                            );
                          }),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (_isEditing) {
                                  _saveUserData();
                                } else {
                                  setState(() => _isEditing = true);
                                }
                              },
                              icon: Icon(
                                  _isEditing ? Icons.save : Icons.edit,
                                  size: 18),
                              label: Text(
                                  _isEditing ? "Save" : "Edit Profile",
                                  style: poppins),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _purple,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 16),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _confirmLogout,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: _green, width: 2),
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Text("Log out",
                                      style: poppins.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _green,
                                      borderRadius:
                                      BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (_profileImage.isNotEmpty && _profileImage.startsWith("http")) {
      return NetworkImage(_profileImage);
    } else {
      return const AssetImage("assets/images/profile_pic.png");
    }
  }

  Widget _labeledField(String label,
      {required TextEditingController controller,
        String? hint,
        required TextStyle textStyle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: textStyle.copyWith(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            enabled: _isEditing,
            style: textStyle,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              filled: true,
              fillColor: _chipBg,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField(TextStyle textStyle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Password",
              style: textStyle.copyWith(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            enabled: false,
            obscureText: true,
            style: textStyle,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outlined, size: 18),
              isDense: true,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              filled: true,
              fillColor: _chipBg,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _staticRow(String title, TextStyle textStyle, {VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(title, style: textStyle.copyWith(fontSize: 14)),
          trailing:
          const Icon(Icons.chevron_right, size: 20, color: Colors.black54),
          onTap: onTap, // ✅ tappable if callback provided
        ),
        const Divider(height: 0),
      ],
    );
  }
}
