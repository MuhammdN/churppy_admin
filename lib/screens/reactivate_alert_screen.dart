import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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

  Future<void> _getUserLocationAndCountry() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;
    setState(() => _currentPosition = pos);

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json',
    );

    final resp = await http.get(uri, headers: {
      'User-Agent': 'ChurppyApp/1.0',
    });

    if (resp.statusCode == 200 && mounted) {
      final data = json.decode(resp.body);
      final countryCode =
          data['address']?['country_code']?.toString().toUpperCase();

      setState(() {
        _currentCountryCode = countryCode;
        widget.controller.text = data['display_name'] ?? "";
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchSuggestions(String query) async {
    if (query.isEmpty || _currentCountryCode == null) return [];

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query)}'
      '&countrycodes=${_currentCountryCode!.toLowerCase()}'
      '&format=json&addressdetails=1&limit=6',
    );

    final resp = await http.get(uri, headers: {
      'User-Agent': 'ChurppyApp/1.0',
    });

    if (resp.statusCode == 200) {
      final List data = json.decode(resp.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
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
            hintText: "Search address...",
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _getUserLocationAndCountry,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        );
      },
      suggestionsCallback: fetchSuggestions,
      itemBuilder: (context, suggestion) {
        final address = suggestion['address'] ?? {};
        final sub = [
          address['road'],
          address['suburb'],
          address['city'],
          address['state']
        ].where((e) => e != null).join(", ");

        return ListTile(
          title: Text(suggestion['display_name'] ?? ''),
          subtitle: Text(sub.isNotEmpty ? sub : ''),
        );
      },
      onSelected: (suggestion) {
        widget.controller.text = suggestion['display_name'] ?? '';
      },
      emptyBuilder: (context) => const ListTile(
        title: Text('No results found'),
      ),
    );
  }
}

class ReactivateAlertScreen extends StatefulWidget {
  final Map<String, dynamic> alert;
  final Future<bool> Function(String, String, String, String) onReactivate;

  const ReactivateAlertScreen({
    super.key,
    required this.alert,
    required this.onReactivate,
  });

  @override
  State<ReactivateAlertScreen> createState() => _ReactivateAlertScreenState();
}

class _ReactivateAlertScreenState extends State<ReactivateAlertScreen> {
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _firstDayCtrl = TextEditingController();
  final TextEditingController _lastDayCtrl = TextEditingController();
  final TextEditingController _timeStartCtrl = TextEditingController();
  final TextEditingController _timeEndCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();

    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    _firstDayCtrl.text =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    _lastDayCtrl.text =
        "${tomorrow.year.toString().padLeft(4, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";

    _timeStartCtrl.text =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";
    _timeEndCtrl.text =
        "${now.add(const Duration(hours: 2)).hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";
  }

  Future<void> _loadCurrentLocation() async {
    final location = widget.alert['location']?.toString() ?? '';

    if (location.contains(',')) {
      try {
        final parts = location.split(',');
        if (parts.length == 2) {
          final lat = parts[0].trim();
          final lon = parts[1].trim();

          final url = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1',
          );

          final response = await http.get(url, headers: {
            'User-Agent': 'ChurppyApp/1.0',
          });

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final displayName = data['display_name']?.toString();

            if (displayName != null && displayName.isNotEmpty) {
              _addressCtrl.text = displayName;
            } else {
              _addressCtrl.text = location;
            }
          } else {
            _addressCtrl.text = location;
          }
        } else {
          _addressCtrl.text = location;
        }
      } catch (_) {
        _addressCtrl.text = location;
      }
    } else {
      _addressCtrl.text = location;
    }

    if (mounted) setState(() {});
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text =
          "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final now = DateTime.now();
      final dt =
          DateTime(now.year, now.month, now.day, picked.hour, picked.minute);

      controller.text =
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00";
      setState(() {});
    }
  }

  String? _validateDateTime() {
    if (_firstDayCtrl.text.isEmpty ||
        _lastDayCtrl.text.isEmpty ||
        _timeStartCtrl.text.isEmpty ||
        _timeEndCtrl.text.isEmpty) {
      return "⚠️ Please complete all date and time fields";
    }

    try {
      final startDateTime =
          DateTime.parse("${_firstDayCtrl.text} ${_timeStartCtrl.text}");
      final endDateTime =
          DateTime.parse("${_lastDayCtrl.text} ${_timeEndCtrl.text}");

      final totalDuration = endDateTime.difference(startDateTime);

      if (endDateTime.isBefore(startDateTime) ||
          endDateTime.isAtSameMomentAs(startDateTime)) {
        return "⚠️ End time must be after start time";
      }

      if (totalDuration.inMinutes < 10) {
        return "⚠️ Minimum alert duration should be 10 minutes";
      }

      if (totalDuration.inHours > 72) {
        return "⚠️ Maximum alert duration should be 72 hours (3 days)";
      }

      return null;
    } catch (_) {
      return "⚠️ Invalid date/time format";
    }
  }

  Future<void> _handleReactivate() async {
    FocusScope.of(context).unfocus();

    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please enter a location"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final dateTimeError = _validateDateTime();
    if (dateTimeError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dateTimeError),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.onReactivate(
        _addressCtrl.text.trim(),
        _firstDayCtrl.text,
        _lastDayCtrl.text,
        "${_timeStartCtrl.text} to ${_timeEndCtrl.text}",
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, true);
      } 
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Failed to process reactivation";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _firstDayCtrl.dispose();
    _lastDayCtrl.dispose();
    _timeStartCtrl.dispose();
    _timeEndCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', width: 100, height: 30),
            const SizedBox(width: 10),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset("assets/images/bell_churppy.png", height: 70),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Reactivate Alert",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.purple.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Update Alert Details",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Current Plan: Single Use",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "UPDATE LOCATION",
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            AddressAutocompleteField(controller: _addressCtrl),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  "UPDATE DATES",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.calendar_today, size: 18, color: Colors.red),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstDayCtrl,
                    readOnly: true,
                    onTap: _isLoading ? null : () => _pickDate(_firstDayCtrl),
                    decoration: const InputDecoration(
                      hintText: "START DATE",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _lastDayCtrl,
                    readOnly: true,
                    onTap: _isLoading ? null : () => _pickDate(_lastDayCtrl),
                    decoration: const InputDecoration(
                      hintText: "END DATE",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  "UPDATE TIMES",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.access_time, size: 18, color: Colors.red),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _timeStartCtrl,
                    readOnly: true,
                    onTap: _isLoading ? null : () => _pickTime(_timeStartCtrl),
                    decoration: const InputDecoration(
                      hintText: "START TIME",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _timeEndCtrl,
                    readOnly: true,
                    onTap: _isLoading ? null : () => _pickTime(_timeEndCtrl),
                    decoration: const InputDecoration(
                      hintText: "END TIME",
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.roboto(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleReactivate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8DC63F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        "REACTIVATE ALERT",
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: Text(
                  "CANCEL",
                  style: GoogleFonts.roboto(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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