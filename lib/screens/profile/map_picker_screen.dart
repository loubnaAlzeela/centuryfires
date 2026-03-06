import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../theme/app_colors.dart';
import '../../utils/l.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _center;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;
    setState(() => _center = LatLng(pos.latitude, pos.longitude));
  }

  Future<Map<String, dynamic>?> _reverseGeocode(LatLng location) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse'
          '?format=json'
          '&lat=${location.latitude}'
          '&lon=${location.longitude}';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'centuryfries_app'},
      );

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      return data['address'];
    } catch (e) {
      debugPrint('_reverseGeocode error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary(context);

    if (_center == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(
          L.t('select_location'),
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // ── MAP ──────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center!, zoom: 16),
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,

            // يتتبع مركز الخريطة وهي تتحرك
            onCameraMove: (position) => _center = position.target,
          ),

          // ── PIN ثابت في المنتصف ──────────────────
          const Center(
            child: Icon(Icons.location_on, size: 44, color: Colors.red),
          ),

          // ── CONFIRM BUTTON ───────────────────────
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () async {
                if (_center == null) return;
                final addressData = await _reverseGeocode(_center!);
                if (!mounted) return;
                Navigator.pop(context, {
                  'location': _center,
                  'address': addressData,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: AppColors.textOnPrimary(context),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                L.t('confirm_location'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
