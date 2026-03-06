import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../services/driver_tracking_service.dart';

class DriverMapScreen extends StatefulWidget {
  final String orderId;
  final String driverUserId;
  final double customerLat;
  final double customerLng;

  const DriverMapScreen({
    super.key,
    required this.orderId,
    required this.driverUserId,
    required this.customerLat,
    required this.customerLng,
  });

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  final supabase = Supabase.instance.client;

  final Completer<GoogleMapController> _mapCompleter = Completer();
  GoogleMapController? _mapController;

  LatLng? driverLocation;
  StreamSubscription<Position>? _positionStream;

  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  bool _starting = true;

  @override
  void initState() {
    super.initState();
    _startAll();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.card(context)),
    );
  }

  // ─────────────────────────────────────────
  //  MARKERS helper
  // ─────────────────────────────────────────
  void _buildMarkers({LatLng? driver}) {
    final customer = LatLng(widget.customerLat, widget.customerLng);

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('customer'),
        position: customer,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Customer'),
      ),
    };

    if (driver != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driver,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'You'),
        ),
      );
    }

    if (mounted) setState(() => _markers = markers);
  }

  // ─────────────────────────────────────────
  //  MOVE CAMERA
  // ─────────────────────────────────────────
  Future<void> _moveTo(LatLng pos, {double zoom = 16}) async {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: zoom)),
    );
  }

  // ─────────────────────────────────────────
  //  START ALL
  // ─────────────────────────────────────────
  Future<void> _startAll() async {
    setState(() => _starting = true);

    // GPS on?
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _showMsg('Location is OFF - please enable GPS');
      await Geolocator.openLocationSettings();
      if (mounted) setState(() => _starting = false);
      return;
    }

    // Permission?
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _showMsg('Location permission denied');
      if (mounted) setState(() => _starting = false);
      return;
    }

    // Update order status
    try {
      await supabase
          .from('orders')
          .update({
            'status': 'out_for_delivery',
            'accepted_at': DateTime.now().toIso8601String(),
            'driver_id': widget.driverUserId,
          })
          .eq('id', widget.orderId);
    } catch (e) {
      debugPrint('orders update error: $e');
    }

    // First position
    try {
      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 10),
      );

      final nowLoc = LatLng(p.latitude, p.longitude);
      if (mounted) setState(() => driverLocation = nowLoc);

      _buildMarkers(driver: nowLoc);
      _moveTo(nowLoc);

      await supabase.from('driver_locations').upsert({
        'order_id': widget.orderId,
        'driver_id': widget.driverUserId,
        'lat': p.latitude,
        'lng': p.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'order_id');
    } catch (e) {
      debugPrint('FIRST UPSERT ERROR: $e');
      _showMsg('Tracking start failed: $e');
    }

    // Background tracking
    try {
      await DriverTrackingService.start(
        orderId: widget.orderId,
        driverUserId: widget.driverUserId,
      );
    } catch (e) {
      debugPrint('background start error: $e');
    }

    // UI tracking
    await _startUiTracking();

    if (mounted) setState(() => _starting = false);
  }

  // ─────────────────────────────────────────
  Future<void> _startUiTracking() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      final nowLoc = LatLng(p.latitude, p.longitude);
      if (mounted) setState(() => driverLocation = nowLoc);

      _buildMarkers(driver: nowLoc);
      _moveTo(nowLoc);

      final points = await _fetchRoute(
        p.latitude,
        p.longitude,
        widget.customerLat,
        widget.customerLng,
      );
      _buildPolyline(points);

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 5,
            ),
          ).listen((pos) async {
            final liveLoc = LatLng(pos.latitude, pos.longitude);
            if (mounted) setState(() => driverLocation = liveLoc);

            _buildMarkers(driver: liveLoc);
            _moveTo(liveLoc);

            // Upsert موقع السائق في Supabase
            await supabase.from('driver_locations').upsert({
              'order_id': widget.orderId,
              'driver_id': widget.driverUserId,
              'lat': pos.latitude,
              'lng': pos.longitude,
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'order_id');

            final liveRoute = await _fetchRoute(
              pos.latitude,
              pos.longitude,
              widget.customerLat,
              widget.customerLng,
            );
            _buildPolyline(liveRoute);
          });
    } catch (e) {
      debugPrint('UI TRACK ERROR: $e');
    }
  }

  // ─────────────────────────────────────────
  //  ROUTE
  // ─────────────────────────────────────────
  Future<List<LatLng>> _fetchRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '$startLng,$startLat;$endLng,$endLat'
          '?overview=full&geometries=geojson';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return [];

      final coords = routes[0]['geometry']['coordinates'] as List;
      return coords
          .map(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList();
    } catch (e) {
      debugPrint('FETCH ROUTE ERROR: $e');
      return [];
    }
  }

  void _buildPolyline(List<LatLng> points) {
    if (!mounted) return;
    setState(() {
      _polylines = points.isEmpty
          ? {}
          : {
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                width: 5,
                color: Colors.deepOrange,
              ),
            };
    });
  }

  // ─────────────────────────────────────────
  //  STOP
  // ─────────────────────────────────────────
  Future<void> _stopAll() async {
    try {
      await DriverTrackingService.stop();
    } catch (_) {}
    await _positionStream?.cancel();
    _positionStream = null;
  }

  // ─────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary(context);
    final text = AppColors.text(context);

    final initialPosition = CameraPosition(
      target: LatLng(widget.customerLat, widget.customerLng),
      zoom: 15,
    );

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialPosition,
            mapType: MapType.normal,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapCompleter.complete(controller);
              _mapController = controller;
            },
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primary,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.textOnPrimary(context),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  if (_starting)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        'Starting...',
                        style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: AppColors.card(context),
                    child: IconButton(
                      icon: Icon(
                        Icons.stop_circle,
                        color: AppColors.error(context),
                      ),
                      onPressed: _stopAll,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
