import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../services/driver_tracking_service.dart';

class DriverMapScreen extends StatefulWidget {
  final String orderId;
  final String driverUserId; // users.id (internal id)
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

  LatLng? driverLocation;
  StreamSubscription<Position>? _positionStream;
  final MapController _mapController = MapController();

  List<LatLng> routePoints = [];
  bool _starting = true;

  @override
  void initState() {
    super.initState();
    _startAll();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startAll() async {
    debugPrint("🔥 START ALL CALLED");
    setState(() => _starting = true);

    void showMsg(String msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.card(context)),
      );
    }

    // 0) GPS ON؟
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      showMsg('Location is OFF - please enable GPS');
      await Geolocator.openLocationSettings();
      if (mounted) setState(() => _starting = false);
      return;
    }

    // 0.5) Permission؟
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      showMsg('Location permission denied');
      if (mounted) setState(() => _starting = false);
      return;
    }

    // 1) Update order (مرة واحدة)
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

    // ✅ 1.5) Create first row فوراً + حط موقع السائق على الخريطة
    try {
      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 10),
      );

      final nowLoc = LatLng(p.latitude, p.longitude);

      if (mounted) setState(() => driverLocation = nowLoc);
      _mapController.move(nowLoc, 16);
      debugPrint("========== DRIVER DEBUG ==========");
      debugPrint("widget.driverUserId = ${widget.driverUserId}");
      debugPrint("auth.uid = ${supabase.auth.currentUser?.id}");
      debugPrint("==================================");

      await supabase.from('driver_locations').upsert({
        'order_id': widget.orderId,
        'driver_id': widget.driverUserId,
        'lat': p.latitude,
        'lng': p.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'order_id');

      // ✅ تأكيد سريع: هل انكتب؟
      final check = await supabase
          .from('driver_locations')
          .select('order_id,driver_id,lat,lng,updated_at')
          .eq('order_id', widget.orderId)
          .maybeSingle();

      debugPrint('driver_locations check: $check');
      if (check == null) {
        showMsg('Row not created (RLS/Insert blocked)');
      }
    } catch (e) {
      debugPrint('FIRST UPSERT ERROR: $e');
      showMsg('Tracking start failed: $e');
    }

    // 2) Background tracking (اختياري)
    try {
      await DriverTrackingService.start(
        orderId: widget.orderId,
        driverUserId: widget.driverUserId,
      );
    } catch (e) {
      debugPrint('background start error: $e');
    }

    // 3) UI tracking
    await _startUiTracking();

    if (mounted) setState(() => _starting = false);
  }

  Future<void> _startUiTracking() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      final nowLoc = LatLng(p.latitude, p.longitude);

      if (!mounted) return;

      setState(() {
        driverLocation = nowLoc;
      });

      _mapController.move(nowLoc, 16);

      // رسم المسار
      final points = await _fetchRoute(
        p.latitude,
        p.longitude,
        widget.customerLat,
        widget.customerLng,
      );

      if (!mounted) return;

      setState(() {
        routePoints = points;
      });

      // الآن نفعّل التتبع الحي
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 5,
            ),
          ).listen((pos) async {
            final liveLoc = LatLng(pos.latitude, pos.longitude);

            if (!mounted) return;

            setState(() {
              driverLocation = liveLoc;
            });

            _mapController.move(liveLoc, 16);

            final liveRoute = await _fetchRoute(
              pos.latitude,
              pos.longitude,
              widget.customerLat,
              widget.customerLng,
            );

            if (!mounted) return;

            setState(() {
              routePoints = liveRoute;
            });
          });
    } catch (e) {
      debugPrint("UI TRACK ERROR: $e");
    }
  }

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

      debugPrint("ROUTE STATUS: ${response.statusCode}");

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
      debugPrint("FETCH ROUTE ERROR: $e");
      return [];
    }
  }

  Future<void> _stopAll() async {
    try {
      await DriverTrackingService.stop();
    } catch (_) {}

    await _positionStream?.cancel();
    _positionStream = null;
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary(context);
    final bg = AppColors.bg(context);
    final text = AppColors.text(context);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.customerLat, widget.customerLng),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://a.tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.centuryfries.app',
              ),

              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // الظل تحت
                    Polyline(
                      points: routePoints,
                      strokeWidth: 8,
                      color: AppColors.text(context).withValues(alpha: 0.25),
                    ),

                    // الخط الأساسي فوق
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4,
                      color: Colors.deepOrange,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(widget.customerLat, widget.customerLng),
                    width: 40,
                    height: 40,
                    child: Icon(Icons.location_on, size: 40, color: Colors.red),
                  ),
                  if (driverLocation != null)
                    Marker(
                      point: driverLocation!,
                      width: 38,
                      height: 38,
                      child: Icon(
                        Icons.delivery_dining,
                        size: 36,
                        color: Colors.blueAccent,
                      ),
                    ),
                ],
              ),
            ],
          ),

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
                      onPressed: () async => _stopAll(),
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
