import 'dart:convert';
import 'package:churppy_admin/screens/dashboard_screen.dart';
import 'package:churppy_admin/screens/profile.dart';
import 'package:churppy_admin/screens/reactivate_payment_screen.dart';
import 'package:churppy_admin/screens/select_alert.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'drawer.dart';



// 🔰 NEW: Address Autocomplete Field (From your API code)
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

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() => _currentPosition = pos);

    // 👇 Reverse geocode to get country code
    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json');

    final resp = await http.get(uri, headers: {
      'User-Agent': 'ChurppyApp/1.0',
    });

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      final countryCode = data['address']?['country_code']?.toString().toUpperCase();
      setState(() {
        _currentCountryCode = countryCode;
        widget.controller.text = data['display_name'] ?? "";
      });
    }
  }

  /// ✅ Fetch address suggestions limited to current country
  Future<List<Map<String, dynamic>>> fetchSuggestions(String query) async {
    if (query.isEmpty || _currentCountryCode == null) return [];

    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&countrycodes=${_currentCountryCode!.toLowerCase()}'
        '&format=json&addressdetails=1&limit=6');

    final resp = await http.get(uri, headers: {
      'User-Agent': 'ChurppyApp/1.0',
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
            hintText: "Search address...",
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _getUserLocationAndCountry,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

// 🔰 Reactivation Screen with Address Autocomplete
class ReactivateAlertScreen extends StatefulWidget {
  final Map<String, dynamic> alert;
  final Function(String, String, String, String) onReactivate;

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
    // Pre-fill with current alert data
    _loadCurrentLocation(); // Load real address from coordinates
    
    // Set default dates (today and tomorrow)
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    _firstDayCtrl.text = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    _lastDayCtrl.text = "${tomorrow.year.toString().padLeft(4, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";
    
    // Set default times (current time and +2 hours)
    _timeStartCtrl.text = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";
    _timeEndCtrl.text = "${now.add(const Duration(hours: 2)).hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";
  }

  /// 🔰 NEW: Load real address from coordinates
  Future<void> _loadCurrentLocation() async {
    final location = widget.alert['location']?.toString() ?? '';
    if (location.contains(',')) {
      try {
        final parts = location.split(',');
        if (parts.length == 2) {
          final lat = parts[0].trim();
          final lon = parts[1].trim();
          
          final url = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1'
          );

          final response = await http.get(url, headers: {
            'User-Agent': 'ChurppyApp/1.0'
          });

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final displayName = data['display_name']?.toString();
            if (displayName != null && displayName.isNotEmpty) {
              setState(() {
                _addressCtrl.text = displayName;
              });
            } else {
              _addressCtrl.text = location;
            }
          } else {
            _addressCtrl.text = location;
          }
        } else {
          _addressCtrl.text = location;
        }
      } catch (e) {
        _addressCtrl.text = location;
      }
    } else {
      _addressCtrl.text = location;
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
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

  String? _validateDateTime() {
  if (_firstDayCtrl.text.isEmpty ||
      _lastDayCtrl.text.isEmpty ||
      _timeStartCtrl.text.isEmpty ||
      _timeEndCtrl.text.isEmpty) {
    return null;
  }

  try {
    final startDateTime =
        DateTime.parse("${_firstDayCtrl.text} ${_timeStartCtrl.text}");
    final endDateTime =
        DateTime.parse("${_lastDayCtrl.text} ${_timeEndCtrl.text}");

    final totalDuration = endDateTime.difference(startDateTime);

    // 🟢 Minimum 10 minutes
    if (totalDuration.inMinutes < 10) {
      return "⚠️ Minimum alert duration should be 10 minutes";
    }

    // 🔴 Maximum 72 hours
    if (totalDuration.inHours > 72) {
      return "⚠️ Maximum alert duration should be 72 hours (3 days)";
    }

    return null;
  } catch (e) {
    return "⚠️ Invalid date/time format";
  }
}


void _handleReactivate() {
  // 🔰 Location check
  if (_addressCtrl.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⚠️ Please enter a location")),
    );
    return;
  }

  // 🔰 Duration validation
  final dateTimeError = _validateDateTime();
  if (dateTimeError != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(dateTimeError)),
    );
    return; // STOP HERE
  }

  // Continue to payment page
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  widget.onReactivate(
    _addressCtrl.text,
    _firstDayCtrl.text,
    _lastDayCtrl.text,
    "${_timeStartCtrl.text} to ${_timeEndCtrl.text}",
  );
 Future.delayed(Duration(milliseconds: 100), () {
  if (mounted) {
    setState(() => _isLoading = false);
  }
});}

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
          onPressed: () => Navigator.pop(context),
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
            // Location Section with Autocomplete
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

            // Dates Section
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
                    onTap: () => _pickDate(_firstDayCtrl),
                    decoration: const InputDecoration(
                      hintText: "START DATE",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _lastDayCtrl,
                    readOnly: true,
                    onTap: () => _pickDate(_lastDayCtrl),
                    decoration: const InputDecoration(
                      hintText: "END DATE",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Times Section
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
                    onTap: () => _pickTime(_timeStartCtrl),
                    decoration: const InputDecoration(
                      hintText: "START TIME",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _timeEndCtrl,
                    readOnly: true,
                    onTap: () => _pickTime(_timeEndCtrl),
                    decoration: const InputDecoration(
                      hintText: "END TIME",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            // Validation Error
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
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
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

            // Reactivate Button
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

            // Cancel Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: Text(
                  "CANCEL",
                  style: GoogleFonts.roboto(
                    color: Colors.grey.shade700,
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

class AlertsListScreen extends StatefulWidget {
  final String userId;
  const AlertsListScreen({super.key, required this.userId});

  @override
  State<AlertsListScreen> createState() => _AlertsListScreenState();
}

class _AlertsListScreenState extends State<AlertsListScreen> {
  List<dynamic> _allAlerts = [];
  List<dynamic> _filteredAlerts = [];
  bool _isLoading = true;
  bool _error = false;
  Map<String, bool> _activatingAlerts = {};
  Map<String, bool> _reactivatingAlerts = {};
  Map<String, bool> _favoritingAlerts = {};

  // ✅ Filter states
  String _currentFilter = 'all';

  // ✅ Profile data
  String? profileImage;
  String? firstName;
  String? lastName;
  bool _profileLoading = true;

  // ✅ Favorite alerts storage key
  static const String _favoriteAlertsKey = 'favorite_alerts';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _fetchUserAlerts();
  }

  /// ✅ Load profile data
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString("user_id");

    if (savedUserId != null) {
      await _fetchUserProfile(savedUserId);
    }
  }

  /// ✅ Fetch User Profile
  Future<void> _fetchUserProfile(String uid) async {
    final url = Uri.parse(
        "https://churppy.eurekawebsolutions.com/api/user.php?id=$uid");

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);
        if (result["status"] == "success") {
          final data = result["data"];
          setState(() {
            profileImage = data["image"];
            firstName = data["first_name"];
            lastName = data["last_name"];
            _profileLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _profileLoading = false);
    }
  }

  /// ✅ Fetch User Alerts from API
  Future<void> _fetchUserAlerts() async {
    try {
      final url = Uri.parse(
          "https://churppy.eurekawebsolutions.com/api/user_alerts.php?user_id=${widget.userId}");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // ✅ Load favorites from SharedPreferences and merge with API data
          final List<dynamic> alerts = data['alerts'] ?? [];
          await _loadFavoritesToAlerts(alerts);
          
          setState(() {
            _allAlerts = alerts;
            _applyFilter(_currentFilter);
            _isLoading = false;
            _error = false;
          });
        } else {
          setState(() {
            _error = true;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = true;
        _isLoading = false;
      });
    }
  }

  /// ✅ Load favorites from SharedPreferences and merge with alerts
  Future<void> _loadFavoritesToAlerts(List<dynamic> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteAlertsJson = prefs.getString(_favoriteAlertsKey);
    
    if (favoriteAlertsJson != null) {
      try {
        final Map<String, dynamic> favoriteAlerts = Map<String, dynamic>.from(json.decode(favoriteAlertsJson));
        
        for (var alert in alerts) {
          final alertId = alert['id']?.toString();
          if (alertId != null && favoriteAlerts.containsKey(alertId)) {
            alert['is_favorite'] = favoriteAlerts[alertId] == true ? '1' : '0';
          } else {
            alert['is_favorite'] = '0'; // Default to not favorite
          }
        }
      } catch (e) {
        print('Error loading favorites: $e');
        // If there's an error, set all alerts to not favorite
        for (var alert in alerts) {
          alert['is_favorite'] = '0';
        }
      }
    } else {
      // If no favorites saved, set all alerts to not favorite
      for (var alert in alerts) {
        alert['is_favorite'] = '0';
      }
    }
  }

  /// ✅ Save favorite status to SharedPreferences
  Future<void> _saveFavoriteToPrefs(String alertId, bool isFavorite) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteAlertsJson = prefs.getString(_favoriteAlertsKey);
    
    Map<String, dynamic> favoriteAlerts = {};
    
    if (favoriteAlertsJson != null) {
      try {
        favoriteAlerts = Map<String, dynamic>.from(json.decode(favoriteAlertsJson));
      } catch (e) {
        print('Error parsing favorites: $e');
        favoriteAlerts = {};
      }
    }
    
    if (isFavorite) {
      favoriteAlerts[alertId] = true;
    } else {
      favoriteAlerts.remove(alertId);
    }
    
    await prefs.setString(_favoriteAlertsKey, json.encode(favoriteAlerts));
  }

  /// 🔄 UPDATED: Apply filter to alerts - AUTO DETECT EXPIRED FROM DATES
  void _applyFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      
      // ✅ Auto-detect expired alerts based on dates/times
      final now = DateTime.now();
      List<dynamic> updatedAlerts = List.from(_allAlerts);
      
      for (var alert in updatedAlerts) {
        final currentStatus = alert['status']?.toString() ?? '0';
        final startDate = alert['start_date']?.toString() ?? '';
        final expiryDate = alert['expiry_date']?.toString() ?? '';
        final startTime = alert['start_time']?.toString() ?? '';
        final endTime = alert['end_time']?.toString() ?? '';
        
        // ✅ Agar alert active hai (status 1) aur time khatam ho gaya hai, toh expired mark karein
        if (currentStatus == '1' && _isAlertExpired(startDate, expiryDate, startTime, endTime)) {
          alert['status'] = '2'; // Expired status set karein
          alert['time_left'] = 'Expired'; // Time left update karein
        }
        
        // ✅ Agar alert pending hai (status 0) aur time khatam ho gaya hai, toh expired mark karein
        if (currentStatus == '0' && _isAlertExpired(startDate, expiryDate, startTime, endTime)) {
          alert['status'] = '2'; // Expired status set karein
          alert['time_left'] = 'Expired'; // Time left update karein
        }
      }
      
      _allAlerts = updatedAlerts;
      
      switch (filter) {
        case 'active':
          _filteredAlerts = _allAlerts.where((a) => (a['status']?.toString() ?? '0') == '1').toList();
          break;
        case 'pending':
          _filteredAlerts = _allAlerts.where((a) => (a['status']?.toString() ?? '0') == '0').toList();
          break;
        case 'expired':
          _filteredAlerts = _allAlerts.where((a) => (a['status']?.toString() ?? '0') == '2').toList();
          break;
        case 'favorites':
          _filteredAlerts = _allAlerts.where((a) => (a['is_favorite']?.toString() == '1')).toList();
          break;
        default:
          _filteredAlerts = List.from(_allAlerts);
      }
    });
  }

  /// 🔄 NEW: Check if alert is expired based on dates and times
  bool _isAlertExpired(String startDate, String expiryDate, String startTime, String endTime) {
  try {
    // Clean formats:
    // time format should always be HH:mm:ss
    String cleanedStartTime = startTime.length == 5 ? "$startTime:00" : startTime;
    String cleanedEndTime   = endTime.length == 5 ? "$endTime:00" : endTime;

    // Build valid datetime:
    final startDateTime = DateTime.parse("$startDate".split(' ')[0] + " " + cleanedStartTime);
    final endDateTime   = DateTime.parse("$expiryDate".split(' ')[0] + " " + cleanedEndTime);

    final now = DateTime.now();

    return now.isAfter(endDateTime);
  } catch (e) {
    print("🔥 Corrected DateTime Error: $e");
    return false;
  }
}


  /// ✅ Toggle Favorite Status (Local Only - SharedPreferences)
  Future<void> _toggleFavorite(String alertId, bool isCurrentlyFavorite) async {
    setState(() {
      _favoritingAlerts[alertId] = true;
    });

    try {
      // ✅ Save to SharedPreferences
      await _saveFavoriteToPrefs(alertId, !isCurrentlyFavorite);
      
      // ✅ Update local state
      setState(() {
        final alertIndex = _allAlerts.indexWhere((a) => a['id']?.toString() == alertId);
        if (alertIndex != -1) {
          _allAlerts[alertIndex]['is_favorite'] = isCurrentlyFavorite ? '0' : '1';
          _applyFilter(_currentFilter); // Re-apply current filter
        }
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCurrentlyFavorite ? "❌ Removed from favorites" : "✅ Added to favorites"),
          backgroundColor: isCurrentlyFavorite ? Colors.orange : const Color(0xFF8DC63F),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to update favorite"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _favoritingAlerts.remove(alertId);
      });
    }
  }

  /// ✅ Activate Alert API Call
  Future<void> _activateAlert(String alertId) async {
    setState(() {
      _activatingAlerts[alertId] = true;
    });

    try {
      final url = Uri.parse("https://churppy.eurekawebsolutions.com/api/activate_alert.php");
      
      final response = await http.post(
        url,
        body: {
          'alert_id': alertId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success') {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Alert activated successfully!"),
              backgroundColor: const Color(0xFF8DC63F),
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Refresh the alerts list
          await _fetchUserAlerts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ ${data['message']}"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to activate alert"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _activatingAlerts.remove(alertId);
      });
    }
  }

  /// 🔰 UPDATED: Reactivate Expired Alert with Payment Integration
  Future<void> _reactivateAlert(Map<String, dynamic> alert) async {
    // Show reactivation screen first
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReactivateAlertScreen(
          alert: alert,
          onReactivate: (newLocation, startDate, endDate, timeRange) async {
            // After reactivation details are entered, proceed to payment
            await _processReactivationWithPayment(
              alert,
              newLocation,
              startDate,
              endDate,
              timeRange,
            );
          },
        ),
      ),
    );
  }

  /// 🔰 NEW: Process Reactivation with Payment Integration
  Future<void> _processReactivationWithPayment(
    Map<String, dynamic> alert,
    String newLocation,
    String startDate,
    String endDate,
    String timeRange,
  ) async {
    // Split time range back to separate times
    final times = timeRange.split(' to ');
    final startTime = times.isNotEmpty ? times[0] : '00:00:00';
    final endTime = times.length > 1 ? times[1] : '23:59:59';

    // Prepare alert data for payment
    final alertData = {
      'id': alert['id']?.toString() ?? '',
      'merchant_id': widget.userId,
      'location': newLocation,
      'start_date': startDate,
      'expiry_date': endDate,
      'start_time': startTime,
      'end_time': endTime,
      'alert_type': alert['type']?.toString() ?? 'churppy',
      'title': alert['title']?.toString() ?? '',
      'description': alert['description']?.toString() ?? '',
    };

    // Navigate to payment screen
    await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AlertPaymentScreen(
      alertData: alertData,        // REQUIRED ✔
      onPaymentSuccess: () async {  // REQUIRED ✔
        await _fetchUserAlerts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Alert reactivated successfully!"),
            backgroundColor: Color(0xFF8DC63F),
          ),
        );
      },
    ),
  ),
  
);

  }

  /// 🔰 UPDATED: Convert Coordinates to Complete Real Address Name
  Future<String> _getLocationName(String coordinates) async {
    if (coordinates.isEmpty) {
      return 'Location not set';
    }

    // If coordinates contain comma, it's lat,lon - convert to address
    if (coordinates.contains(',')) {
      try {
        final parts = coordinates.split(',');
        if (parts.length == 2) {
          final lat = parts[0].trim();
          final lon = parts[1].trim();
          
          final url = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1'
          );

          final response = await http.get(url, headers: {
            'User-Agent': 'ChurppyApp/1.0'
          });

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final displayName = data['display_name']?.toString();
            
            if (displayName != null && displayName.isNotEmpty) {
              return displayName;
            }
          }
        }
      } catch (e) {
        print('Location conversion error: $e');
      }
    }
    
    // If it's already an address or conversion failed, return as is
    return coordinates;
  }

  /// ✅ Get Time Left from Backend (No calculation needed now)
  String _getTimeLeftDisplay(Map<String, dynamic> alert) {
    final timeLeft = alert['time_left']?.toString() ?? '';
    final status = alert['status']?.toString() ?? '0';
    
    if (timeLeft.isEmpty) {
      return 'Not set';
    }
    
    // ✅ Backend se jo time_left aa raha hai, wohi display karein
    return timeLeft;
  }

  /// ✅ Status color mapping
  Color _getStatusColor(String status) {
    switch (status) {
      case '1': return const Color(0xFF8DC63F); // Active - Green
      case '0': return Colors.orange; // Pending - Orange
      case '2': return Colors.red; // Expired - Red
      default: return Colors.grey;
    }
  }

  /// ✅ Status text mapping
  String _getStatusText(String status) {
    switch (status) {
      case '1': return 'ACTIVE';
      case '0': return 'PENDING';
      case '2': return 'EXPIRED';
      default: return 'UNKNOWN';
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// 🔰 UPDATED: Top Header with Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                          Image.asset('assets/images/logo.png', width: 100),
                        ],
                      ),
                      _profileLoading
                          ? const CircularProgressIndicator()
                          : GestureDetector(
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
                                          return const Icon(Icons.person, size: 70, color: Colors.grey);
                                        },
                                      ),
                                    )
                                  : const Icon(Icons.person, size: 70, color: Colors.grey),
                            ),
                    ],
                  ),
                ),

                /// 🔰 Page Title
               
                 
              

                /// 🔰 Back Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade300,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
                          onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DashboardScreen(), // Yahan apni screen ka naam do
    ),
  );
},

                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'My Alerts',
                   style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔰 Stats Summary - TAPPABLE FILTERS (INCLUDING FAVORITES)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "FILTER ALERTS",
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _filterItem('Total', _allAlerts.length.toString(), 'all', Icons.list_alt),
                            _filterItem('Active', _allAlerts.where((a) => (a['status']?.toString() ?? '0') == '1').length.toString(), 'active', Icons.check_circle),
                            _filterItem('Pending', _allAlerts.where((a) => (a['status']?.toString() ?? '0') == '0').length.toString(), 'pending', Icons.schedule),
                            _filterItem('Expired', _allAlerts.where((a) => (a['status']?.toString() ?? '0') == '2').length.toString(), 'expired', Icons.cancel),
                            _filterItem('Favorites', _allAlerts.where((a) => (a['is_favorite']?.toString() == '1')).length.toString(), 'favorites', Icons.favorite),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// 🔰 Current Filter Indicator
                if (_currentFilter != 'all')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getFilterColor(_currentFilter).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getFilterColor(_currentFilter).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getFilterIcon(_currentFilter), size: 16, color: _getFilterColor(_currentFilter)),
                          const SizedBox(width: 6),
                          Text(
                            "Showing ${_currentFilter.toUpperCase()} alerts (${_filteredAlerts.length})",
                            style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600, color: _getFilterColor(_currentFilter)),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _applyFilter('all'),
                            child: Icon(Icons.close, size: 16, color: _getFilterColor(_currentFilter)),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                /// 🔰 Alerts List
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _error
                          ? _buildErrorState()
                          : _filteredAlerts.isEmpty
                              ? _buildEmptyState()
                              : _buildAlertsList(),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔰 Filter Item Widget
  Widget _filterItem(String title, String count, String filter, IconData icon) {
    final isSelected = _currentFilter == filter;
    final color = _getFilterColor(filter);
    
    return GestureDetector(
      onTap: () => _applyFilter(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: isSelected ? 1.5 : 0),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 4),
            Text(count, style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title, style: GoogleFonts.roboto(fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? color : Colors.black54)),
          ],
        ),
      ),
    );
  }

  /// 🔰 Get filter color
  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'active': return const Color(0xFF8DC63F);
      case 'pending': return Colors.orange;
      case 'expired': return Colors.red;
      case 'favorites': return Colors.pink;
      default: return Color(0xFF804692);
    }
  }

  /// 🔰 Get filter icon
  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'active': return Icons.check_circle;
      case 'pending': return Icons.schedule;
      case 'expired': return Icons.cancel;
      case 'favorites': return Icons.favorite;
      default: return Icons.list_alt;
    }
  }

  /// 🔰 Loading State
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8DC63F))),
          const SizedBox(height: 16),
          Text("Loading your alerts...", style: GoogleFonts.roboto(fontSize: 16, color: Colors.black54)),
        ],
      ),
    );
  }

  /// 🔰 Error State
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text("Failed to load alerts", style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          Text("Please check your connection and try again", style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchUserAlerts,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8DC63F), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("Try Again", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// 🔰 Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/bell_churppy.png', height: 100, width: 100),
          const SizedBox(height: 24),
          Text(_currentFilter == 'all' ? "No Alerts Found" : "No ${_currentFilter.toUpperCase()} Alerts", style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 12),
          Text(_currentFilter == 'all' ? "You haven't created any alerts yet" : "You don't have any ${_currentFilter} alerts", style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SelectAlertScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8DC63F), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("Create Alert", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// 🔰 Alerts List
  Widget _buildAlertsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        itemCount: _filteredAlerts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final alert = _filteredAlerts[index];
          return _alertCard(alert);
        },
      ),
    );
  }

  /// 🔰 PROFESSIONAL ALERT CARD WITH FAVORITE & REACTIVATE FUNCTIONALITY
  Widget _alertCard(Map<String, dynamic> alert) {
    final status = alert['status']?.toString() ?? '0';
    final title = alert['title']?.toString() ?? 'No Title';
    final description = alert['description']?.toString() ?? 'No Description';
    final location = alert['location']?.toString() ?? '';
    final alertId = alert['id']?.toString() ?? 'N/A';
    final isFavorite = alert['is_favorite']?.toString() == '1';
    
    // ✅ Backend se time_left directly use karein
    final timeLeft = _getTimeLeftDisplay(alert);

    final statusColor = _getStatusColor(status);
    final isPending = status == '0';
    final isActive = status == '1';
    final isExpired = status == '2';

    return FutureBuilder<String>(
      future: _getLocationName(location),
      builder: (context, snapshot) {
        final displayLocation = snapshot.data ?? 'Loading location...';

        return Container(
          margin: const EdgeInsets.only(bottom: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade200, 
              width: 1.5
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// 🔰 Status Header with Favorite Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: statusColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    /// 🔰 Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusText(status),
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    /// 🔰 Favorite Button
                    if (_favoritingAlerts[alertId] == true)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => _toggleFavorite(alertId, isFavorite),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isFavorite ? Colors.pink.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isFavorite ? Colors.pink : Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: isFavorite ? Colors.pink : Colors.grey,
                          ),
                        ),
                      ),
                    
                    const SizedBox(width: 12),
                    
                    /// 🔰 Alert ID
                    Text(
                      "#$alertId",
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              /// 🔰 Card Content with Ample Padding
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔰 Title and Description with Clear Separation
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: statusColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.campaign_rounded,
                                size: 18,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    description,
                                    style: GoogleFonts.roboto(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    /// 🔰 Divider for Clear Separation
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade100,
                            Colors.grey.shade300,
                            Colors.grey.shade100,
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    /// 🔰 Location and Time Details in Organized Layout
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ Location - REAL ADDRESS
                        _detailRow(
                          Icons.location_on_outlined,
                          "Location",
                          displayLocation,
                          Colors.blue.shade600,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // ✅ Time Left (backend se directly)
                        if (timeLeft.isNotEmpty && timeLeft != 'Not set' && !isPending)
                          _detailRow(
                            Icons.access_time_filled,
                            isExpired ? "Expired" : "Time Left",
                            timeLeft,
                            isExpired ? Colors.red : const Color(0xFF8DC63F),
                          ),
                      ],
                    ),
                    
                    /// 🔰 Action Buttons based on Alert Status
                    if (isPending || isExpired) ...[
                      const SizedBox(height: 20),
                      if (isPending)
                        _buildActionButton(
                          "ACTIVATE ALERT",
                          Icons.play_arrow_rounded,
                          const Color(0xFF8DC63F),
                          _activatingAlerts[alertId] == true,
                          () => _activateAlert(alertId),
                        ),
                      
                      if (isExpired)
                        _buildActionButton(
                          "REACTIVATE ALERT",
                          Icons.refresh_rounded,
                          Color(0xFF8DC63F),
                          _reactivatingAlerts[alertId] == true,
                          () => _reactivateAlert(alert),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔰 Action Button Widget
  Widget _buildActionButton(String text, IconData icon, Color color, bool isLoading, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔰 Professional Detail Row Widget
  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}