import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;


import 'drawer.dart';

/// 🔰 Model jo data next screen pe le jaega
class AlertModel {
  final String merchantId;
  final String title;
  final String description;
  final String location;
  final String startDate;
  final String expiryDate;
  final String startTime;
  final String endTime;
  final int radius;
  final File? image;

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
    this.image,
  });
}

/// 🔰 AddressAutocompleteField widget
class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;

  const AddressAutocompleteField({super.key, required this.controller});

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  Future<List<Map<String, dynamic>>> fetchSuggestions(String query) async {
    if (query.isEmpty) return [];

    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=6');

    final resp = await http.get(uri, headers: {
      'User-Agent': 'MyFlutterApp/1.0 (your-email@example.com)' // required
    });

    if (resp.statusCode == 200) {
      final List data = json.decode(resp.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
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
            hintStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(width: 2, color: Colors.black),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
      },
      suggestionsCallback: fetchSuggestions,
      itemBuilder: (context, suggestion) {
        final address = suggestion['address'] ?? {};
        final sub = [
          address['road'],
          address['neighbourhood'],
          address['suburb'],
          address['city'],
          address['state'],
          address['country']
        ].where((e) => e != null).join(", ");

        return ListTile(
          title: Text(suggestion['display_name'] ?? ''),
          subtitle: Text(sub),
        );
      },
      onSelected: (suggestion) {
        final lat = suggestion['lat']?.toString() ?? "";
        final lon = suggestion['lon']?.toString() ?? "";
        widget.controller.text = "$lat,$lon";
        debugPrint("Selected LatLon: $lat,$lon");
      },
      emptyBuilder: (context) =>
      const ListTile(title: Text('No results found')),
    );
  }
}

class ChurppyAlertScreen extends StatefulWidget {
  const ChurppyAlertScreen({super.key});

  @override
  State<ChurppyAlertScreen> createState() => _ChurppyAlertScreenState();
}

class _ChurppyAlertScreenState extends State<ChurppyAlertScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String? userId;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController();
  final _firstDayCtrl = TextEditingController();
  final _lastDayCtrl = TextEditingController();
  final _startTimeCtrl = TextEditingController();
  final _endTimeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString("user_id");
    setState(() => userId = savedUserId);
    print("✅ Logged-in User ID (ChurppyAlertScreen): $savedUserId");
  }

  Future<void> _pickFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _pickFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  bool _isValidDate(String date) {
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    return regex.hasMatch(date);
  }

  bool _isValidTime(String time) {
    final regex = RegExp(r'^\d{2}:\d{2}:\d{2}$');
    return regex.hasMatch(time);
  }

  /// 🔰 Calendar picker
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

  /// 🔰 Time picker
  Future<void> _pickTime(TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      String formatted =
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00";
      controller.text = formatted;
    }
  }

  void _goToReview() {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ User ID not found")),
      );
      return;
    }

    if (!_isValidDate(_firstDayCtrl.text) ||
        !_isValidDate(_lastDayCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Date format must be YYYY-MM-DD")),
      );
      return;
    }

    if (!_isValidTime(_startTimeCtrl.text) ||
        !_isValidTime(_endTimeCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Time format must be HH:MM:SS")),
      );
      return;
    }

    if (_radiusCtrl.text.isEmpty || int.tryParse(_radiusCtrl.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Enter valid radius (integer)")),
      );
      return;
    }

    final alert = AlertModel(
      merchantId: userId!,
      title: _titleCtrl.text,
      description: _descCtrl.text,
      location: _locationCtrl.text,
      startDate: _firstDayCtrl.text,
      expiryDate: _lastDayCtrl.text,
      startTime: _startTimeCtrl.text,
      endTime: _endTimeCtrl.text,
      radius: int.parse(_radiusCtrl.text),
      image: _selectedImage,
    );

    // Navigator.push(
    //   context,
    //   // MaterialPageRoute(builder: (context) => ReviewChurppyScreen(alert: alert)),
    // );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final maxCardW = w.clamp(320.0, 480.0);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: ChurppyDrawer(),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCardW),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),

                 /// 🔰 Alert Banner (with onTap Navigation)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    // onTap: _sendChurppyAlert,
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
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _stepText("STEP 1", "Alert Title"),
                        _inputField("Churppy Alert", controller: _titleCtrl),

                        _stepText("", "Description"),
                        _inputField("Write description...",
                            controller: _descCtrl,
                            height: 70,
                            alignTop: true),

                        _stepText("", "Image"),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _pickFromCamera,
                                  child: _uploadButton("Take Photo"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _pickFromGallery,
                                  child: _uploadButton("Upload"),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_selectedImage != null)
                          Padding(
                            padding: const EdgeInsets.all(22),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_selectedImage!,
                                  height: 150, fit: BoxFit.cover),
                            ),
                          ),

                        _stepText("", "ENTER LOCATION"),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 6),
                          child: SizedBox(
                            height: 50,
                            child: AddressAutocompleteField(
                              controller: _locationCtrl,
                            ),
                          ),
                        ),

                        _stepText("", "Radius (in Kilo meters)"),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 6),
                          child: SizedBox(
                            height: 50,
                            child: TextField(
                              controller: _radiusCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "Enter radius",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(
                                      width: 2, color: Colors.black),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                        ),

                        _stepText("STEP 2", "ENTER DAY(S) OF OPERATION"),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 6),
                                child: TextField(
                                  controller: _firstDayCtrl,
                                  readOnly: true,
                                  onTap: () => _pickDate(_firstDayCtrl),
                                  decoration: InputDecoration(
                                    hintText: "FIRST DAY (YYYY-MM-DD)",
                                    hintStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                          width: 2, color: Colors.black),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 6),
                                child: TextField(
                                  controller: _lastDayCtrl,
                                  readOnly: true,
                                  onTap: () => _pickDate(_lastDayCtrl),
                                  decoration: InputDecoration(
                                    hintText: "LAST DAY (YYYY-MM-DD)",
                                    hintStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                          width: 2, color: Colors.black),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        _stepText("STEP 3", "ENTER HOURS OF OPERATION"),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 6),
                                child: TextField(
                                  controller: _startTimeCtrl,
                                  readOnly: true,
                                  onTap: () => _pickTime(_startTimeCtrl),
                                  decoration: InputDecoration(
                                    hintText: "START (HH:MM:SS)",
                                    hintStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),


                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                          width: 2, color: Colors.black),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 6),
                                child: TextField(
                                  controller: _endTimeCtrl,
                                  readOnly: true,
                                  onTap: () => _pickTime(_endTimeCtrl),
                                  decoration: InputDecoration(
                                    hintText: "END (HH:MM:SS)",
                                    hintStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),

                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                          width: 2, color: Colors.black),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Image.asset('assets/icons/menu.png',
                      width: 50, height: 50),
                ),
              ),
              const SizedBox(width: 1),
              Image.asset('assets/images/logo.png', width: 100),
            ],
          ),
          ClipOval(
            child: Image.asset('assets/images/truck.png',
                width: 70, height: 70, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  Widget _stepText(String step, String desc) {
    return Padding(
      padding: const EdgeInsets.only(left: 22, right: 22, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (step.isNotEmpty)
            Text(step, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (step.isNotEmpty) const SizedBox(height: 2),
          Text(desc,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _inputField(
      String hint, {
        TextEditingController? controller,
        double fontSize = 13,
        bool isBold = false,
        double height = 40,
        bool alignTop = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
      child: SizedBox(
        height: height,
        child: TextField(
          controller: controller,
          maxLines: alignTop ? null : 1,
          textAlign: alignTop ? TextAlign.start : TextAlign.center,
          decoration: InputDecoration(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(width: 2, color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  Widget _uploadButton(String text) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
