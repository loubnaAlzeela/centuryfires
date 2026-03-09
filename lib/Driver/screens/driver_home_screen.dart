import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../utils/l.dart';
import 'driver_order_details_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final supabase = Supabase.instance.client;

  final Completer<GoogleMapController> _mapCompleter = Completer();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  bool isOnline = false;
  bool hasActiveOrder = false;
  bool _loading = true;

  String driverName = '';
  String vehicleType = '';
  int todayOrders = 0;
  double rating = 0;
  double earnings = 0;

  double? activeClientLat;
  double? activeClientLng;

  List<Map<String, dynamic>> newOrders = [];
  Position? currentPosition;

  StreamSubscription<Position>? _positionStream;
  RealtimeChannel? _ordersChannel;
  RealtimeChannel? _locationChannel;
  RealtimeChannel? _usersChannel; // ← جديد

  @override
  void initState() {
    super.initState();
    _init();
    _listenToDriverLocation();
    _listenToOrders();
    _listenToUsers(); // ← جديد
  }

  @override
  void dispose() {
    _stopTracking();
    _ordersChannel?.unsubscribe();
    _locationChannel?.unsubscribe();
    _usersChannel?.unsubscribe(); // ← جديد
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    await _getCurrentLocation();
    await _loadDriverData();
    if (mounted) setState(() => _loading = false);
  }

  void _moveTo(LatLng pos, {double zoom = 15}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: zoom)),
    );
  }

  void _buildMarkers() {
    final Set<Marker> markers = {};
    if (currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(
            currentPosition!.latitude,
            currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: driverName.isEmpty ? 'Driver' : driverName,
          ),
        ),
      );
    }
    if (activeClientLat != null && activeClientLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('client'),
          position: LatLng(activeClientLat!, activeClientLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Customer'),
        ),
      );
    }
    if (mounted) setState(() => _markers = markers);
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
                width: 4,
                color: AppColors.primary(context),
              ),
            };
    });
  }

  void _listenToDriverLocation() {
    _locationChannel?.unsubscribe();
    _locationChannel = supabase
        .channel('driver-location')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'driver_locations',
          callback: (payload) {
            final double? lat = (payload.newRecord['lat'] as num?)?.toDouble();
            final double? lng = (payload.newRecord['lng'] as num?)?.toDouble();
            if (lat == null || lng == null) return;
            if (!mounted) return;
            setState(() {
              currentPosition = Position(
                latitude: lat,
                longitude: lng,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                heading: 0,
                speed: 0,
                speedAccuracy: 0,
                altitudeAccuracy: 0,
                headingAccuracy: 0,
              );
            });
            _buildMarkers();
          },
        )
        .subscribe();
  }

  void _listenToOrders() {
    _ordersChannel?.unsubscribe();
    _ordersChannel = supabase
        .channel('orders-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) async => await _loadDriverData(),
        )
        .subscribe();
  }

  // ← جديد: يسمع لتغييرات جدول users ويحدّث الاسم تلقائياً
  void _listenToUsers() {
    _usersChannel?.unsubscribe();
    _usersChannel = supabase
        .channel('users-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          callback: (_) async => await _loadDriverData(),
        )
        .subscribe();
  }

  Future<void> _loadDriverData() async {
    final session = supabase.auth.currentSession;
    if (session == null) return;

    final userRes = await supabase
        .from('users')
        .select('id, name')
        .eq('auth_id', session.user.id)
        .single();

    final String userId = userRes['id'].toString();
    driverName = (userRes['name'] ?? '').toString();

    final driverRes = await supabase
        .from('driver_profiles')
        .select('vehicle_type, rating, total_orders, is_active')
        .eq('id', userId)
        .single();

    vehicleType = (driverRes['vehicle_type'] ?? '').toString();
    rating = ((driverRes['rating'] ?? 0) as num).toDouble();
    todayOrders = (driverRes['total_orders'] ?? 0) as int;
    isOnline = (driverRes['is_active'] ?? false) as bool;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final earningsRes = await supabase
        .from('orders')
        .select('total')
        .eq('driver_id', userId)
        .eq('status', 'completed')
        .gte('created_at', startOfDay.toIso8601String());

    earnings = (earningsRes as List).fold<double>(
      0.0,
      (sum, item) => sum + ((item['total'] ?? 0) as num).toDouble(),
    );

    final ordersRes = await supabase
        .from('driver_available_orders')
        .select('*')
        .eq('status', 'confirmed')
        .order('created_at', ascending: false)
        .limit(3);

    newOrders = List<Map<String, dynamic>>.from(ordersRes as List);

    if (mounted) setState(() {});
  }

  Future<void> _toggleStatus(bool value) async {
    setState(() => isOnline = value);
    final session = supabase.auth.currentSession;
    if (session == null) return;
    try {
      final userRes = await supabase
          .from('users')
          .select('id')
          .eq('auth_id', session.user.id)
          .single();
      await supabase
          .from('driver_profiles')
          .update({'status': value ? 'online' : 'offline'})
          .eq('id', userRes['id'].toString());
      if (!value) _stopTracking();
    } catch (e) {
      setState(() => isOnline = !value);
    }
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  Future<void> _acceptOrder(String orderId, Map<String, dynamic> order) async {
    final session = supabase.auth.currentSession;
    if (session == null) return;

    final userRes = await supabase
        .from('users')
        .select('id')
        .eq('auth_id', session.user.id)
        .single();
    final String userId = userRes['id'].toString();

    final orderRes = await supabase
        .from('driver_available_orders')
        .select('lat, lng')
        .eq('id', orderId)
        .maybeSingle();

    if (orderRes == null) return;

    activeClientLat = (orderRes['lat'] as num?)?.toDouble();
    activeClientLng = (orderRes['lng'] as num?)?.toDouble();
    if (activeClientLat == null || activeClientLng == null) return;

    await supabase
        .from('orders')
        .update({
          'status': 'out_for_delivery',
          'driver_id': userId,
          'accepted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);

    hasActiveOrder = true;

    if (currentPosition != null) {
      final points = await _fetchRoute(
        currentPosition!.latitude,
        currentPosition!.longitude,
        activeClientLat!,
        activeClientLng!,
      );
      _buildPolyline(points);
    }

    _buildMarkers();
    if (mounted) setState(() {});

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverOrderDetailsScreen(orderId: orderId),
      ),
    );
  }

  Future<void> _declineOrder(String orderId) async {
    await supabase
        .from('orders')
        .update({'status': 'declined'})
        .eq('id', orderId);
    await _loadDriverData();
  }

  Future<void> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return;
    }

    try {
      // ✅ FIX: إضافة مهلة زمنية (Timeout) لتجنب التعليق اللانهائي عند تسجيل الدخول
      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
    } catch (e) {
      // في حال فشل أو تأخر الحصول على الموقع الحالي، نجلب آخر موقع معروف
      currentPosition = await Geolocator.getLastKnownPosition();
    }

    if (mounted) setState(() {});
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
      debugPrint('_fetchRoute error: $e');
      return [];
    }
  }

  double _calculateDistanceKm(double lat, double lng) {
    if (currentPosition == null) return 0;
    return Geolocator.distanceBetween(
          currentPosition!.latitude,
          currentPosition!.longitude,
          lat,
          lng,
        ) /
        1000.0;
  }

  Future<void> _previewRouteToClient(double lat, double lng) async {
    if (currentPosition == null) return;
    activeClientLat = lat;
    activeClientLng = lng;
    final points = await _fetchRoute(
      currentPosition!.latitude,
      currentPosition!.longitude,
      lat,
      lng,
    );
    _buildPolyline(points);
    _buildMarkers();
    if (points.isNotEmpty) _moveTo(points.first);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppColors.text(context);
    final bg = AppColors.bg(context);
    final card = AppColors.card(context);
    final primary = AppColors.primary(context);
    final grey = AppColors.textGrey(context);

    final mapInitialPos = CameraPosition(
      target: currentPosition != null
          ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
          : const LatLng(25.2048, 55.2708),
      zoom: 15,
    );

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              // ── HEADER ──
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: card.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person_outline, color: text),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${L.t('hello')}, $driverName',
                                style: TextStyle(
                                  color: AppColors.bg(context),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    _vehicleIcon(vehicleType),
                                    size: 14,
                                    color: AppColors.bg(
                                      context,
                                    ).withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _vehicleLabel(vehicleType),
                                    style: TextStyle(
                                      color: AppColors.bg(
                                        context,
                                      ).withValues(alpha: 0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              color: AppColors.bg(context),
                              size: 24,
                            ),
                            if (newOrders.isNotEmpty)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.error(context),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: isOnline,
                          onChanged: _toggleStatus,
                          activeThumbColor: AppColors.textOnPrimary(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.bg(context).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _dot(
                            color: isOnline
                                ? AppColors.textOnPrimary(context)
                                : AppColors.textOnPrimary(
                                    context,
                                  ).withValues(alpha: 0.55),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOnline
                                ? L.t('ready_for_orders')
                                : L.t('not_ready'),
                            style: TextStyle(
                              color: AppColors.bg(context),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── KPI PANEL ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: primary, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasActiveOrder
                            ? Icons.local_shipping
                            : Icons.inventory_2_outlined,
                        size: 28,
                        color: primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasActiveOrder
                                  ? L.t('active_delivery')
                                  : L.t('todays_orders'),
                              style: TextStyle(
                                color: text,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasActiveOrder
                                  ? L.t('delivery_in_progress')
                                  : '$todayOrders',
                              style: TextStyle(
                                color: text,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasActiveOrder)
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DriverOrderDetailsScreen(
                                orderId: newOrders.isNotEmpty
                                    ? newOrders.first['id']
                                    : '',
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: AppColors.textOnPrimary(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            L.t('open'),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── MAP ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: grey.withValues(alpha: 0.25)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: currentPosition == null
                        ? Center(
                            child: _loading
                                ? CircularProgressIndicator(color: primary)
                                : Text(
                                    L.t('loading'),
                                    style: TextStyle(
                                      color: grey,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          )
                        : GoogleMap(
                            initialCameraPosition: mapInitialPos,
                            mapType: MapType.normal,
                            myLocationEnabled: false,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            markers: _markers,
                            polylines: _polylines,
                            onMapCreated: (controller) {
                              if (!_mapCompleter.isCompleted) {
                                _mapCompleter.complete(controller);
                              }
                              _mapController = controller;
                              _buildMarkers();
                            },
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── NEW ORDERS ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        L.t('new_orders'),
                        style: TextStyle(
                          color: text,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (_loading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primary,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: newOrders.map((order) {
                    final double? lat = (order['lat'] as num?)?.toDouble();
                    final double? lng = (order['lng'] as num?)?.toDouble();
                    double? km;
                    if (lat != null && lng != null) {
                      km = _calculateDistanceKm(lat, lng);
                    }
                    return _newOrderCard(
                      context,
                      orderNumber: (order['order_number'] ?? 0) as int,
                      customerName: (order['customer_name'] ?? '').toString(),
                      area: (order['area'] ?? '').toString(),
                      street: (order['street'] ?? '').toString(),
                      createdAt: (order['created_at'] ?? '').toString(),
                      distanceKm: km,
                      onTap: (lat != null && lng != null)
                          ? () => _previewRouteToClient(lat, lng)
                          : null,
                      onAccept: () =>
                          _acceptOrder(order['id'].toString(), order),
                      onDecline: () => _declineOrder(order['id'].toString()),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _vehicleIcon(String raw) {
    final v = raw.toLowerCase().trim();
    if (v == 'motorcycle' || v == 'bike') return Icons.two_wheeler;
    if (v == 'car') return Icons.directions_car;
    if (v == 'bicycle') return Icons.pedal_bike;
    return Icons.local_shipping;
  }

  String _vehicleLabel(String raw) {
    final v = raw.toLowerCase().trim();
    if (v == 'motorcycle' || v == 'bike') return L.t('vehicle_motorcycle');
    if (v == 'car') return L.t('vehicle_car');
    if (v == 'bicycle') return L.t('vehicle_bicycle');
    return raw.isEmpty ? '' : raw;
  }

  String _timeAgoText(String createdAt) {
    try {
      final mins = DateTime.now()
          .difference(DateTime.parse(createdAt))
          .inMinutes;
      if (mins <= 0) return '1 ${L.t('min_ago')}';
      return '$mins ${L.t('min_ago')}';
    } catch (_) {
      return '';
    }
  }

  Widget _dot({required Color color}) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _newOrderCard(
    BuildContext context, {
    required int orderNumber,
    required String customerName,
    required String area,
    required String street,
    required String createdAt,
    required double? distanceKm,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
    VoidCallback? onTap,
  }) {
    final primary = AppColors.primary(context);
    final text = AppColors.text(context);
    final textGrey = AppColors.textGrey(context);
    final card = AppColors.card(context);

    final distanceText = (distanceKm == null || distanceKm <= 0)
        ? '— km'
        : '${distanceKm.toStringAsFixed(1)} km';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: primary, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: text),
                  ),
                  child: Text(
                    'ORD-$orderNumber',
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _timeAgoText(createdAt),
                  style: TextStyle(
                    color: textGrey,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    distanceText,
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              customerName.isEmpty ? L.t('customer') : customerName,
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: textGrey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    [street, area].where((e) => e.trim().isNotEmpty).join(', '),
                    style: TextStyle(
                      color: textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: isOnline ? onAccept : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: AppColors.textOnPrimary(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        L.t('accept'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary, width: 1.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        L.t('decline'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
