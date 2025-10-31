import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isUserDataLoading = false;

  // 🔹 Controllers
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController messageCtrl = TextEditingController();
  final TextEditingController contactNumberCtrl = TextEditingController();

  // 🔹 Dropdown Values
  String? selectedCategory;
  final List<String> categories = [
    'Customize Your Churppy Alert',
    'Submit Feedback', 
    'Billing',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ✅ UPDATED METHOD: Load User Data from Shared Preferences and API
  Future<void> _loadUserData() async {
    setState(() => isUserDataLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id'); // ✅ Changed to getString
      
      debugPrint("🔍 User ID from SharedPreferences: $userId");

      if (userId != null && userId.isNotEmpty) {
        // Try user_with_merchant.php first
        await _fetchFromUserWithMerchant(userId);
      } else {
        setState(() => isUserDataLoading = false);
        debugPrint("⚠️ No user ID found in SharedPreferences");
      }
    } catch (e) {
      debugPrint("❌ Error loading user data: $e");
      setState(() => isUserDataLoading = false);
    }
  }

  // ✅ NEW: Fetch from user_with_merchant.php
  Future<void> _fetchFromUserWithMerchant(String userId) async {
    try {
      final url = Uri.parse(
        "https://churppy.eurekawebsolutions.com/api/user_with_merchant.php?id=$userId"
      );

      final response = await http.get(url);
      debugPrint("🔍 user_with_merchant API Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        debugPrint("🔍 user_with_merchant API Response: $result");

        if (result['status'] == 'success' && result['data'] != null) {
          final userData = result['data'];
          _autoFillUserData(userData);
          return;
        }
      }

      // If user_with_merchant fails, try user.php
      await _fetchFromUser(userId);
    } catch (e) {
      debugPrint("❌ Error in user_with_merchant: $e");
      await _fetchFromUser(userId);
    }
  }

  // ✅ NEW: Fetch from user.php (fallback)
  Future<void> _fetchFromUser(String userId) async {
    try {
      final url = Uri.parse(
        "https://churppy.eurekawebsolutions.com/api/user.php?id=$userId"
      );

      final response = await http.get(url);
      debugPrint("🔍 user.php API Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        debugPrint("🔍 user.php API Response: $result");

        if (result['status'] == 'success' && result['data'] != null) {
          final userData = result['data'];
          _autoFillUserData(userData);
          return;
        }
      }

      setState(() => isUserDataLoading = false);
    } catch (e) {
      debugPrint("❌ Error in user.php: $e");
      setState(() => isUserDataLoading = false);
    }
  }

  // ✅ NEW: Auto-fill user data in form fields
  void _autoFillUserData(Map<String, dynamic> userData) {
    setState(() {
      // Auto-fill email
      final email = userData['email']?.toString();
      if (email != null && email.isNotEmpty) {
        emailCtrl.text = email;
      }

      // Auto-fill contact number with country code
      final phone = userData['phone_number']?.toString() ?? 
                   userData['phone']?.toString() ?? 
                   userData['contact_number']?.toString();
      
      if (phone != null && phone.isNotEmpty) {
        // Add country code if not present (assuming US +1 as default)
        if (!phone.startsWith('+')) {
          contactNumberCtrl.text = '+1 $phone';
        } else {
          contactNumberCtrl.text = phone;
        }
      }

      isUserDataLoading = false;
    });

    debugPrint("✅ Auto-filled Email: ${emailCtrl.text}");
    debugPrint("✅ Auto-filled Contact: ${contactNumberCtrl.text}");
  }

  Future<void> _submitContact() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Please select a category"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse(
        "https://churppy.eurekawebsolutions.com/api/save_contact_info.php");

    final requestBody = {
      "title": titleCtrl.text.trim(),
      "email": emailCtrl.text.trim(),
      "info_email": messageCtrl.text.trim(),
      "contact_number": contactNumberCtrl.text.trim(),
      "category": selectedCategory!,
      "message": messageCtrl.text.trim(),
    };

    try {
      final response = await http.post(url, body: requestBody);

      debugPrint("📤 Request Body: $requestBody");
      debugPrint("📥 Status Code: ${response.statusCode}");
      debugPrint("📥 Raw Response: ${response.body}");

      final result = json.decode(response.body);

      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Your message was submitted successfully!"),
            backgroundColor: Color(0xFF1CC019),
            behavior: SnackBarBehavior.floating,
          ),
        );

        titleCtrl.clear();
        messageCtrl.clear();
        setState(() => selectedCategory = null);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ ${result['message']}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("⚠️ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to connect: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isTablet = w > 600;
    final isDesktop = w > 1024;
    
    double fs(double size) {
      if (isDesktop) return size * 1.3;
      if (isTablet) return size * 1.15;
      return size;
    }
    
    double hp(double percentage) => h * percentage / 100;
    double wp(double percentage) => w * percentage / 100;

    return Scaffold(
      backgroundColor: const Color(0xfff9f9f9),
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout(fs, hp, wp) : _buildMobileTabletLayout(fs, hp, wp, isTablet),
      ),
    );
  }

  Widget _buildCategoryDropdown(double Function(double) fs, double Function(double) hp, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(fs(12)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedCategory,
        decoration: InputDecoration(
          labelText: "Category",
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: fs(13)),
          prefixIcon: Icon(Icons.category, color: Color(0xFF804692), size: fs(20)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(isTablet ? 16 : 14)),
        ),
        items: categories.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(
              category,
              style: TextStyle(fontSize: fs(14), color: Colors.black87),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            selectedCategory = newValue;
          });
        },
        validator: (value) => value == null ? 'Please select a category' : null,
      ),
    );
  }

  Widget _buildMobileForm(double Function(double) fs, double Function(double) hp) {
    return Column(
      children: [
        _buildCategoryDropdown(fs, hp, false),
        SizedBox(height: hp(1.5)),
        
        _buildCustomField(
          label: "Title",
          controller: titleCtrl,
          icon: Icons.title,
          fs: fs,
          validator: (v) => v!.trim().isEmpty ? "Title is required" : null,
        ),
        SizedBox(height: hp(1.5)),
        
        _buildCustomField(
          label: "Email Address",
          controller: emailCtrl,
          icon: Icons.email_outlined,
          fs: fs,
          keyboardType: TextInputType.emailAddress,
          isLoading: isUserDataLoading,
          validator: (v) {
            if (v!.trim().isEmpty) {
              return "Email is required";
            } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
              return "Enter a valid email";
            }
            return null;
          },
        ),
        SizedBox(height: hp(1.5)),
        
        _buildCustomField(
          label: "Contact Number",
          controller: contactNumberCtrl,
          icon: Icons.phone_iphone,
          fs: fs,
          keyboardType: TextInputType.phone,
          isLoading: isUserDataLoading,
          validator: (v) => v!.trim().isEmpty ? "Contact number is required" : null,
        ),
        SizedBox(height: hp(1.5)),
        
        _buildCustomField(
          label: "Your Message",
          controller: messageCtrl,
          icon: Icons.description,
          fs: fs,
          maxLines: 5,
          validator: (v) => v!.trim().isEmpty ? "Message is required" : null,
        ),
      ],
    );
  }

  Widget _buildTabletFormGrid(double Function(double) fs, double Function(double) hp, double Function(double) wp) {
    return Column(
      children: [
        _buildCategoryDropdown(fs, hp, true),
        SizedBox(height: hp(2)),
        
        Row(
          children: [
            Expanded(
              child: _buildCustomField(
                label: "Title",
                controller: titleCtrl,
                icon: Icons.title,
                fs: fs,
                validator: (v) => v!.trim().isEmpty ? "Title is required" : null,
              ),
            ),
            SizedBox(width: wp(2)),
            Expanded(
              child: _buildCustomField(
                label: "Contact Number",
                controller: contactNumberCtrl,
                icon: Icons.phone_iphone,
                fs: fs,
                keyboardType: TextInputType.phone,
                isLoading: isUserDataLoading,
                validator: (v) => v!.trim().isEmpty ? "Contact number is required" : null,
              ),
            ),
          ],
        ),
        SizedBox(height: hp(2)),
        
        _buildCustomField(
          label: "Email Address",
          controller: emailCtrl,
          icon: Icons.email_outlined,
          fs: fs,
          keyboardType: TextInputType.emailAddress,
          isLoading: isUserDataLoading,
          validator: (v) {
            if (v!.trim().isEmpty) {
              return "Email is required";
            } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
              return "Enter a valid email";
            }
            return null;
          },
        ),
        SizedBox(height: hp(2)),
        
        _buildCustomField(
          label: "Your Message",
          controller: messageCtrl,
          icon: Icons.description,
          fs: fs,
          maxLines: 6,
          validator: (v) => v!.trim().isEmpty ? "Message is required" : null,
        ),
      ],
    );
  }

  Widget _buildCustomField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required double Function(double) fs,
    String? Function(String?)? validator,
    bool obscure = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(fs(12)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          TextFormField(
            controller: controller,
            obscureText: obscure,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            enabled: !isLoading,
            style: TextStyle(
              fontSize: fs(14), 
              color: isLoading ? Colors.grey : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: isLoading ? Colors.grey : Colors.grey[600], 
                fontSize: fs(13)
              ),
              prefixIcon: Icon(
                icon, 
                color: isLoading ? Colors.grey : Color(0xFF804692), 
                size: fs(20)
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(14)),
            ),
          ),
          if (isLoading)
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: fs(20),
                height: fs(20),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF804692),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(double Function(double) fs, double Function(double) hp, double Function(double) wp) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: wp(5), vertical: hp(5)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF804692).withOpacity(0.9),
                  Color(0xFF6A3093),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBackButton(fs, true),
                SizedBox(height: hp(4)),
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: wp(25),
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: hp(6)),
                _buildContactInfoSection(fs, hp, true),
              ],
            ),
          ),
        ),
        
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: wp(4), vertical: hp(4)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 400,
                maxWidth: 600,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildContactFormCard(fs, hp, wp, true),
                  SizedBox(height: hp(2)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabletLayout(double Function(double) fs, double Function(double) hp, double Function(double) wp, bool isTablet) {
    return Column(
      children: [
        _buildHeader(fs, wp, isTablet),
        
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? wp(8) : wp(5),
              vertical: hp(2),
            ),
            child: Column(
              children: [
                if (!isTablet) ...[
                  _buildContactInfoCard(fs, hp, wp),
                  SizedBox(height: hp(2)),
                ],
                
                _buildContactFormCard(fs, hp, wp, isTablet),
                
                if (isTablet) ...[
                  SizedBox(height: hp(3)),
                  _buildContactInfoCard(fs, hp, wp),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(double Function(double) fs, double Function(double) wp, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? wp(4) : wp(5),
        vertical: isTablet ? 20 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildBackButton(fs, false),
          SizedBox(width: wp(2)),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: isTablet ? wp(20) : wp(35),
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: wp(8)),
        ],
      ),
    );
  }

  Widget _buildBackButton(double Function(double) fs, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: isDesktop ? Colors.white.withOpacity(0.2) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: isDesktop ? Colors.white : Colors.black87,
          size: fs(18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildContactInfoCard(double Function(double) fs, double Function(double) hp, double Function(double) wp) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(fs(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(fs(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: _buildContactInfoSection(fs, hp, false),
    );
  }

  Widget _buildContactInfoSection(double Function(double) fs, double Function(double) hp, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.contact_support,
              color: isDesktop ? Colors.white : Color(0xFF804692),
              size: fs(20),
            ),
            SizedBox(width: fs(8)),
            Text(
              "Get In Touch",
              style: TextStyle(
                fontSize: fs(18),
                fontWeight: FontWeight.bold,
                color: isDesktop ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: hp(1.5)),
        Text(
          "Have questions or need assistance? We'd love to hear from you. Send us a message and we'll respond as soon as possible.",
          style: TextStyle(
            fontSize: fs(14),
            color: isDesktop ? Colors.white.withOpacity(0.9) : Colors.grey[700],
            height: 1.4,
          ),
        ),
        if (!isDesktop) ...[
          SizedBox(height: hp(2)),
          _buildContactMethods(fs, hp),
        ],
      ],
    );
  }

  Widget _buildContactMethods(double Function(double) fs, double Function(double) hp) {
    return Column(
      children: [
        
        SizedBox(height: hp(1)),
        _buildContactMethod(
          Icons.access_time,
          "Mon - Fri: 9:00 AM - 6:00 PM",
          fs,
        ),
      ],
    );
  }

  Widget _buildContactMethod(IconData icon, String text, double Function(double) fs) {
    return Row(
      children: [
        Icon(icon, size: fs(16), color: Color(0xFF804692)),
        SizedBox(width: fs(8)),
        Text(
          text,
          style: TextStyle(fontSize: fs(13), color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildContactFormCard(double Function(double) fs, double Function(double) hp, double Function(double) wp, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(fs(isTablet ? 24 : 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(fs(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isTablet) ...[
              Row(
                children: [
                  Icon(Icons.message, color: Color(0xFF804692), size: fs(20)),
                  SizedBox(width: fs(8)),
                  Text(
                    "Send us a Message",
                    style: TextStyle(
                      fontSize: fs(18),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: hp(2)),
            ] else ...[
              Center(
                child: Text(
                  "Send us a Message",
                  style: TextStyle(
                    fontSize: fs(22),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: hp(3)),
            ],
            
            if (isTablet) _buildTabletFormGrid(fs, hp, wp),
            if (!isTablet) _buildMobileForm(fs, hp),
            
            SizedBox(height: hp(3)),
            
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 400 : double.infinity,
                ),
                child: SizedBox(
                  height: fs(52),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF804692),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(fs(12)),
                      ),
                      elevation: 2,
                      shadowColor: Color(0xFF804692).withOpacity(0.3),
                    ),
                    onPressed: isLoading ? null : _submitContact,
                    child: isLoading
                        ? SizedBox(
                            height: fs(22),
                            width: fs(22),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ) 
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, size: fs(18)),
                              SizedBox(width: fs(8)),
                              Text(
                                'Submit Message',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: fs(16),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}