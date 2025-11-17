import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class AddressAutocompleteField extends StatefulWidget {
  const AddressAutocompleteField({super.key});

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final TextEditingController _ctrl = TextEditingController();

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

    setState(() => _currentPosition = pos);

    // 👇 Reverse geocode to get country code
    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json');

    final resp = await http.get(uri, headers: {
      'User-Agent': 'MyFlutterApp/1.0 (your-email@example.com)',
    });

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      final countryCode = data['address']?['country_code']?.toString().toUpperCase();
      setState(() {
        _currentCountryCode = countryCode;
        _ctrl.text = data['display_name'] ?? "";
      });
      print("🌍 Current country: $_currentCountryCode");
    }
  }

  /// ✅ Step 2: Fetch address suggestions limited to current country
  Future<List<Map<String, dynamic>>> fetchSuggestions(String query) async {
    await Future.delayed(const Duration(milliseconds: 400)); // debounce

    if (query.isEmpty || _currentCountryCode == null) return [];

    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&countrycodes=${_currentCountryCode!.toLowerCase()}'
        '&format=json&addressdetails=1&limit=6');

    final resp = await http.get(uri, headers: {
      'User-Agent': 'MyFlutterApp/1.0 (your-email@example.com)',
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
    return Scaffold(
      appBar: AppBar(title: const Text("Smart Address Autocomplete")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TypeAheadField<Map<String, dynamic>>(
          controller: _ctrl,
          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Enter your address',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _getUserLocationAndCountry,
                ),
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
              subtitle: Text(sub),
            );
          },
          onSelected: (suggestion) {
            final lat = suggestion['lat']?.toString() ?? "";
            final lon = suggestion['lon']?.toString() ?? "";
            _ctrl.text = suggestion['display_name'] ?? '';
            print("📍 Selected: $lat,$lon");
          },
          emptyBuilder: (context) => const ListTile(
            title: Text('No results found'),
          ),
        ),
      ),
    );
  }
}
