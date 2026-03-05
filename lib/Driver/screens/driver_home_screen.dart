import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'driver_order_details_screen.dart';
import '../../theme/app_colors.dart';
import '../../utils/l.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final supabase = Supabase.instance.client;

  bool isOnline = false;

  // tracking
  StreamSubscription<Position>? _positionStream;
  RealtimeChannel? _locationChannel;
  final MapController _mapController = MapController();
  String driverName = '';
  String vehicleType = '';

  int todayOrders = 0;
  double rating = 0;
  double earnings = 0;
  RealtimeChannel? _ordersChannel;
  List<LatLng> routePoints = [];

  double? activeClientLat;
  double? activeClientLng;
  bool hasActiveOrder = false;

  List<Map<String, dynamic>> newOrders = [];

  Position? currentPosition;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
    _listenToDriverLocation();
    _listenToOrders();
  }

  @override
  void dispose() {
    _stopTracking();
    _ordersChannel?.unsubscribe();
    _locationChannel?.unsubscribe();
    super.dispose();
  }

  // ================= REALTIME: LISTEN DRIVER LOCATION =================
  void _listenToDriverLocation() {
    // يمنع تكرار نفس القناة لو انعمل hot-reload
    _locationChannel?.unsubscribe();

    _locationChannel = supabase
        .channel('driver-location')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'driver_locations',
          callback: (payload) {
            final latRaw = payload.newRecord['lat'];
            final lngRaw = payload.newRecord['lng'];

            final double? lat = latRaw == null
                ? null
                : (latRaw as num).toDouble();
            final double? lng = lngRaw == null
                ? null
                : (lngRaw as num).toDouble();

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
          },
        )
        .subscribe();
  }

  Future<void> _init() async {
    setState(() => _loading = true);

    await _getCurrentLocation();
    await _loadDriverData();

    if (!mounted) return;
    setState(() => _loading = false);
  }

  double _calculateDistanceKm(double lat, double lng) {
    if (currentPosition == null) return 0;

    final meters = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      lat,
      lng,
    );

    return meters / 1000.0;
  }

  Future<List<LatLng>> _fetchRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '$startLng,$startLat;$endLng,$endLat'
        '?overview=full&geometries=geojson';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);

    final coords = data['routes'][0]['geometry']['coordinates'] as List;

    return coords
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
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
      final created = DateTime.parse(createdAt);
      final mins = DateTime.now().difference(created).inMinutes;
      if (mins <= 0) return '1 ${L.t('min_ago')}';
      return '$mins ${L.t('min_ago')}';
    } catch (_) {
      return '';
    }
  }

  //=========== Realtime orders ==============
  void _listenToOrders() {
    _ordersChannel?.unsubscribe();

    _ordersChannel = supabase
        .channel('orders-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) async {
            print("Realtime update received");
            await _loadDriverData();
          },
        )
        .subscribe();
  }

  // ================= LOAD DATA =================
  Future<void> _loadDriverData() async {
    final session = supabase.auth.currentSession;
    if (session == null) return;

    // 1) users row
    final userRes = await supabase
        .from('users')
        .select('id, name')
        .eq('auth_id', session.user.id)
        .single();

    final String userId = (userRes['id']).toString();
    driverName = (userRes['name'] ?? '').toString();

    // 2) driver profile
    final driverRes = await supabase
        .from('driver_profiles')
        .select('vehicle_type, rating, total_orders, is_active')
        .eq('id', userId)
        .single();

    vehicleType = (driverRes['vehicle_type'] ?? '').toString();
    rating = ((driverRes['rating'] ?? 0) as num).toDouble();
    todayOrders = (driverRes['total_orders'] ?? 0) as int;
    isOnline = (driverRes['is_active'] ?? false) as bool;

    // 3) earnings today
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

    // 4) available orders (VIEW)
    final ordersRes = await supabase
        .from('driver_available_orders')
        .select('*')
        .eq('status', 'confirmed')
        .order('created_at', ascending: false)
        .limit(3);

    newOrders = List<Map<String, dynamic>>.from(ordersRes as List);

    if (!mounted) return;
    setState(() {});
  }

  // ================= TOGGLE STATUS =================
  Future<void> _toggleStatus(bool value) async {
    // ✅ 1) حدثي UI فوراً
    setState(() => isOnline = value);

    final session = supabase.auth.currentSession;
    if (session == null) return;

    try {
      final userRes = await supabase
          .from('users')
          .select('id')
          .eq('auth_id', session.user.id)
          .single();

      final String userId = userRes['id'].toString();

      await supabase
          .from('driver_profiles')
          .update({'status': value ? 'online' : 'offline'})
          .eq('id', userId);
      if (!value) {
        _stopTracking();
      }
    } catch (e) {
      // ❌ لو فشل رجعي الحالة
      setState(() => isOnline = !value);
      print("Toggle failed: $e");
    }
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  // ================= ACCEPT ORDER =================
  Future<void> _acceptOrder(String orderId, Map<String, dynamic> order) async {
    final session = supabase.auth.currentSession;
    if (session == null) return;

    final userRes = await supabase
        .from('users')
        .select('id')
        .eq('auth_id', session.user.id)
        .single();

    final String userId = (userRes['id']).toString();

    // ✅ 1️⃣ جيب موقع العميل أولاً قبل ما يختفي من الـ view
    final orderRes = await supabase
        .from('driver_available_orders')
        .select('lat, lng')
        .eq('id', orderId)
        .maybeSingle();

    if (orderRes == null) {
      return;
    }

    activeClientLat = (orderRes['lat'] as num?)?.toDouble();
    activeClientLng = (orderRes['lng'] as num?)?.toDouble();

    if (activeClientLat == null || activeClientLng == null) {
      return;
    }

    // ✅ 2️⃣ الآن حدث الطلب
    await supabase
        .from('orders')
        .update({
          'status': 'out_for_delivery',
          'driver_id': userId,
          'accepted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);

    hasActiveOrder = true;

    if (currentPosition == null) return;

    // ✅ 3️⃣ احسب المسار
    routePoints.clear();
    routePoints = await _fetchRoute(
      currentPosition!.latitude,
      currentPosition!.longitude,
      activeClientLat!,
      activeClientLng!,
    );

    if (!mounted) return;
    setState(() {});
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverOrderDetailsScreen(orderId: orderId),
      ),
    );
  }

  // ================= DECLINE ORDER =================
  Future<void> _declineOrder(String orderId) async {
    await supabase
        .from('orders')
        .update({'status': 'declined'})
        .eq('id', orderId);
    await _loadDriverData();
  }

  // ================= DRIVER LOCATION =================
  Future<void> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return;
    }

    currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;
    setState(() {});
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final text = AppColors.text(context);
    final bg = AppColors.bg(context);
    final card = AppColors.card(context);
    final primary = AppColors.primary(context);
    final textGrey = AppColors.textGrey(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              // ================= HEADER =================
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

                        // 🔔 Bell + Badge
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

              // ================= KPI =================
              // ================= SMART DRIVER PANEL =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primary(context),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasActiveOrder
                            ? Icons.local_shipping
                            : Icons.inventory_2_outlined,
                        size: 28,
                        color: AppColors.primary(context),
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
                                color: AppColors.text(context),
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
                                color: AppColors.text(context),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasActiveOrder)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DriverOrderDetailsScreen(
                                  orderId: newOrders.isNotEmpty
                                      ? newOrders.first['id']
                                      : '',
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary(context),
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

              // ================= MAP =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: textGrey.withValues(alpha: 0.25)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: currentPosition == null
                        ? Center(
                            child: _loading
                                ? CircularProgressIndicator(
                                    color: AppColors.primary(context),
                                  )
                                : Text(
                                    L.t('loading'),
                                    style: TextStyle(
                                      color: AppColors.textGrey(context),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          )
                        : FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: routePoints.isNotEmpty
                                  ? routePoints.first
                                  : LatLng(
                                      currentPosition!.latitude,
                                      currentPosition!.longitude,
                                    ),
                              initialZoom: 15,
                            ),

                            children: [
                              // ================= TILE =================
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.example.flutter_application_1',
                              ),

                              // ================= MARKERS =================
                              MarkerLayer(
                                markers: [
                                  // Driver marker
                                  Marker(
                                    point: LatLng(
                                      currentPosition!.latitude,
                                      currentPosition!.longitude,
                                    ),
                                    width: 40,
                                    height: 40,
                                    child: Icon(
                                      Icons.delivery_dining,
                                      color: Colors.redAccent,
                                    ),
                                  ),

                                  // Client marker
                                  if (activeClientLat != null &&
                                      activeClientLng != null)
                                    Marker(
                                      point: LatLng(
                                        activeClientLat!,
                                        activeClientLng!,
                                      ),
                                      width: 40,
                                      height: 40,
                                      child: Icon(
                                        Icons.location_on,
                                        color: AppColors.error(context),
                                      ),
                                    ),
                                ],
                              ),

                              // ================= ROUTE =================
                              if (routePoints.isNotEmpty)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: routePoints,
                                      strokeWidth: 4,
                                      color: AppColors.primary(context),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= NEW ORDERS =================
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
                          color: AppColors.primary(context),
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
                    final createdAt = (order['created_at'] ?? '').toString();

                    final double? lat = order['lat'] == null
                        ? null
                        : (order['lat'] as num).toDouble();
                    final double? lng = order['lng'] == null
                        ? null
                        : (order['lng'] as num).toDouble();

                    double? km;
                    if (lat != null && lng != null && currentPosition != null) {
                      km = _calculateDistanceKm(lat, lng);
                    }

                    final orderId = (order['id']).toString();

                    return _newOrderCard(
                      context,
                      orderNumber: (order['order_number'] ?? 0) as int,
                      customerName: (order['customer_name'] ?? '').toString(),
                      area: (order['area'] ?? '').toString(),
                      street: (order['street'] ?? '').toString(),
                      createdAt: createdAt,
                      distanceKm: km,

                      // ✅ Tap preview route
                      onTap: (lat != null && lng != null)
                          ? () => _previewRouteToClient(lat, lng)
                          : null,

                      // ✅ Accept will navigate (بنعدلها تحت)
                      onAccept: () => _acceptOrder(orderId, order),
                      onDecline: () => _declineOrder(orderId),
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

  // ================= WIDGETS =================

  IconData _vehicleIcon(String raw) {
    final v = raw.toLowerCase().trim();

    if (v == 'motorcycle' || v == 'bike') {
      return Icons.two_wheeler;
    } else if (v == 'car') {
      return Icons.directions_car;
    } else if (v == 'bicycle') {
      return Icons.pedal_bike;
    } else {
      return Icons.local_shipping;
    }
  }

  Widget _dot({required Color color}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

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

    final timeAgo = _timeAgoText(createdAt);

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
            // ===== TOP ROW =====
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
                  timeAgo,
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

  Future<void> _previewRouteToClient(double lat, double lng) async {
    if (currentPosition == null) return;

    // نخزن العميل الحالي
    activeClientLat = lat;
    activeClientLng = lng;

    // نجيب المسار
    routePoints = await _fetchRoute(
      currentPosition!.latitude,
      currentPosition!.longitude,
      lat,
      lng,
    );

    if (!mounted) return;
    setState(() {});
    if (routePoints.isNotEmpty) {
      _mapController.move(routePoints.first, 15);
    }
  }
}
