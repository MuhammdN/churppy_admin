import 'dart:convert';
import 'package:churppy_admin/screens/profile.dart';
import 'package:churppy_admin/screens/select_alert.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'drawer.dart';

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
  Map<String, bool> _activatingAlerts = {}; // Track activating alerts

  // ✅ Filter states
  String _currentFilter = 'all';

  // ✅ Profile data
  String? profileImage;
  String? firstName;
  String? lastName;
  bool _profileLoading = true;

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
          setState(() {
            _allAlerts = data['alerts'] ?? [];
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

  /// ✅ Apply filter to alerts - AUTO DETECT EXPIRED FROM BACKEND
  void _applyFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      
      // ✅ Backend se time_left check karke automatically expired detect karein
      final now = DateTime.now();
      List<dynamic> updatedAlerts = List.from(_allAlerts);
      
      for (var alert in updatedAlerts) {
        final timeLeft = alert['time_left']?.toString() ?? '';
        final currentStatus = alert['status']?.toString() ?? '0';
        
        // ✅ Agar backend se "Expired" aa raha hai aur status active hai, toh update karein
        if (timeLeft.toLowerCase().contains('expired') && currentStatus == '1') {
          alert['status'] = '2'; // Expired status set karein
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
        default:
          _filteredAlerts = List.from(_allAlerts);
      }
    });
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

  /// ✅ Convert Coordinates to Complete Address Name
  Future<String> _getLocationName(String coordinates) async {
    if (coordinates.isEmpty || !coordinates.contains(',')) {
      return 'Location not set';
    }

    try {
      final parts = coordinates.split(',');
      if (parts.length != 2) return coordinates;
      
      final lat = parts[0].trim();
      final lon = parts[1].trim();
      
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1'
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'ChurppyApp/1.0'
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // ✅ COMPLETE ADDRESS BANAYEIN
        final address = data['address'];
        final displayName = data['display_name']?.toString() ?? '';
        
        // Priority: display_name use karein (complete address)
        if (displayName.isNotEmpty) {
          return displayName;
        }
        
        // Agar display_name nahi hai toh manually build karein
        List<String> addressParts = [];
        
        if (address['house_number'] != null) addressParts.add(address['house_number']);
        if (address['road'] != null) addressParts.add(address['road']);
        if (address['neighbourhood'] != null) addressParts.add(address['neighbourhood']);
        if (address['suburb'] != null) addressParts.add(address['suburb']);
        if (address['city'] != null) addressParts.add(address['city']);
        if (address['state'] != null) addressParts.add(address['state']);
        if (address['postcode'] != null) addressParts.add(address['postcode']);
        if (address['country'] != null) addressParts.add(address['country']);
        
        if (addressParts.isNotEmpty) {
          return addressParts.join(', ');
        }
        
        return coordinates; // Fallback to original coordinates
      }
    } catch (e) {
      print('Location conversion error: $e');
    }
    
    return coordinates; // Return original if conversion fails
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
      case '1': return const Color(0xFF8DC63F);
      case '0': return Colors.orange;
      case '2': return Colors.red;
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

  /// ✅ Format date
  String _formatDate(String date) {
    if (date.isEmpty) return 'Not set';
    try {
      if (date.contains('-')) {
        final parts = date.split('-');
        if (parts.length == 3) {
          return '${parts[1]}/${parts[2]}/${parts[0]}';
        }
      }
      return date;
    } catch (e) {
      return date;
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
                /// 🔰 Top Header
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'My Alerts',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

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
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Back to Dashboard",
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔰 Stats Summary - TAPPABLE FILTERS
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            Text(count, style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title, style: GoogleFonts.roboto(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? color : Colors.black54)),
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
      default: return Colors.purple;
    }
  }

  /// 🔰 Get filter icon
  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'active': return Icons.check_circle;
      case 'pending': return Icons.schedule;
      case 'expired': return Icons.cancel;
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
    MaterialPageRoute(
      builder: (context) => SelectAlertScreen(),
    ),
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
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final alert = _filteredAlerts[index];
          return _alertCard(alert);
        },
      ),
    );
  }

  /// 🔰 PROFESSIONAL ALERT CARD WITH ALL FEATURES
  Widget _alertCard(Map<String, dynamic> alert) {
    final status = alert['status']?.toString() ?? '0';
    final title = alert['title']?.toString() ?? 'No Title';
    final description = alert['description']?.toString() ?? 'No Description';
    final location = alert['location']?.toString() ?? '';
    final alertId = alert['id']?.toString() ?? 'N/A';
    
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
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              /// 🔰 Glass Background Effect
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.85),
                    ],
                  ),
                ),
              ),

              /// 🔰 Main Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// 🔰 Compact Header with Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.08),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        /// 🔰 Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getStatusText(status),
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        /// 🔰 Alert ID
                        Text(
                          "#$alertId",
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  /// 🔰 Card Body
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// 🔰 Title and Description
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.campaign_rounded,
                                size: 16,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.roboto(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    description,
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        /// 🔰 Location and Time Details
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            // ✅ Location - COMPLETE ADDRESS
                            _compactDetailChip(
                              Icons.location_on_outlined,
                              displayLocation,
                              Colors.blue,
                            ),
                            
                            // ✅ Time Left (backend se directly)
                            if (timeLeft.isNotEmpty && timeLeft != 'Not set' && !isPending)
                              _compactDetailChip(
                                Icons.access_time_filled,
                                timeLeft,
                                isExpired ? Colors.red : const Color(0xFF8DC63F),
                              ),
                          ],
                        ),
                        
                        /// 🔰 Activate Button for Pending Alerts
                        if (isPending) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF8DC63F),
                                  const Color(0xFF8DC63F).withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8DC63F).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _activatingAlerts[alertId] == true ? null : () => _activateAlert(alertId),
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (_activatingAlerts[alertId] == true)
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    else
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                                          const SizedBox(width: 6),
                                          Text(
                                            "ACTIVATE ALERT",
                                            style: GoogleFonts.roboto(
                                              fontSize: 12,
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
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔰 Compact Detail Chip Widget
  Widget _compactDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text.length > 25 ? '${text.substring(0, 25)}...' : text,
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}