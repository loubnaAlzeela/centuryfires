import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_colors.dart';
import '../../utils/l.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _center;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // هل GPS مفعّل
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    // تحقق من الصلاحية
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final current = LatLng(pos.latitude, pos.longitude);

    if (!mounted) return;

    setState(() {
      _center = current;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_center == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(
          L.t('select_location'),
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: AppColors.primary(context),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center!,
              initialZoom: 16,
              onPositionChanged: (position, _) {
                _center = position.center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=1j7K6ihnUiwsRHOf7LLA',
                userAgentPackageName: 'com.centuryfries.app',
              ),

              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          const Center(
            child: Icon(Icons.location_on, size: 40, color: Colors.red),
          ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () async {
                final addressData = await _reverseGeocode(_center!);

                Navigator.pop(context, {
                  'location': _center,
                  'address': addressData,
                });
              },
              child: Text(L.t('confirm_location')),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _reverseGeocode(LatLng location) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json'
        '&lat=${location.latitude}'
        '&lon=${location.longitude}';

    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'your_app_name'},
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    return data['address'];
  }
}
