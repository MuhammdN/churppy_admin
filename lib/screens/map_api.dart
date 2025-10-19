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

  /// Fetch suggestions from Nominatim API
  Future<List<Map<String, dynamic>>> fetchSuggestions(String query) async {
    await Future.delayed(const Duration(milliseconds: 400)); // debounce

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

  /// Get current location and save lat,lon
  Future<void> useCurrentLocation() async {
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

    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // 👇 lat,lon store karo
    setState(() {
      _ctrl.text = "${pos.latitude},${pos.longitude}";
    });

    print("Current Location: ${pos.latitude},${pos.longitude}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Address Autocomplete")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TypeAheadField<Map<String, dynamic>>(
          controller: _ctrl,
          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Enter Address',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: useCurrentLocation,
                ),
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

            // 👇 lat,lon textfield me store karo
            _ctrl.text = "$lat,$lon";

            print("Selected LatLon: $lat,$lon");
          },
          emptyBuilder: (context) =>
          const ListTile(title: Text('No results')),
        ),
      ),
    );
  }
}
