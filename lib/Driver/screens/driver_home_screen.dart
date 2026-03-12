import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';
import '../../utils/l.dart';
import '../../utils/language_controller.dart';
import 'driver_order_details_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  bool isOnline = false;
  bool hasActiveOrder = false;
  bool _loading = true;

  String driverName = '';
  String vehicleType = '';
  int todayOrders = 0;
  int pendingOrdersCount = 0;

  Map<String, dynamic>? activeOrderDetails;
  Position? currentPosition;

  StreamSubscription<Position>? _positionStream;
  RealtimeChannel? _ordersChannel;
  RealtimeChannel? _usersChannel;

  // ── Pulse Animation ──
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.28,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _init();
    _listenToOrders();
    _listenToUsers();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _stopTracking();
    _ordersChannel?.unsubscribe();
    _usersChannel?.unsubscribe();
    super.dispose();
  }

  void _setPulse() {
    if (isOnline) {
      _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  Future<void> _init() async {
    if (!_loading) setState(() => _loading = true);
    final locFuture = _getCurrentLocation();
    await _loadDriverData();
    await locFuture;
    if (mounted) setState(() => _loading = false);
  }

  void _listenToOrders() {
    _ordersChannel?.unsubscribe();
    _ordersChannel = supabase
        .channel('home-orders-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) async => await _loadDriverData(),
        )
        .subscribe();
  }

  void _listenToUsers() {
    _usersChannel?.unsubscribe();
    _usersChannel = supabase
        .channel('home-users-realtime')
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

    // Profile
    try {
      final userRes = await supabase
          .from('users')
          .select('id, name')
          .eq('auth_id', session.user.id)
          .single();
      final String userId = userRes['id'].toString();
      driverName = (userRes['name'] ?? '').toString();

      final driverRes = await supabase
          .from('driver_profiles')
          .select('vehicle_type, is_active, status, total_orders')
          .eq('id', userId)
          .single();

      vehicleType = (driverRes['vehicle_type'] ?? '').toString();
      todayOrders = (driverRes['total_orders'] ?? 0) as int;

      final dbOnline = (driverRes['status'] == 'online');

      isOnline = dbOnline;
      _setPulse();

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Driver profile: $e');
    }

    // Active Order
    try {
      final userRes = await supabase
          .from('users')
          .select('id')
          .eq('auth_id', session.user.id)
          .single();
      final String userId = userRes['id'].toString();

      final activeRes = await supabase
          .from('driver_order_details_view')
          .select('*')
          .eq('driver_id', userId)
          .inFilter('status', const [
            'accepted',
            'picked_up',
            'out_for_delivery',
            'on_the_way',
          ])
          .maybeSingle();

      activeOrderDetails = activeRes;
      hasActiveOrder = activeOrderDetails != null;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Active order: $e');
    }

    // Pending count only (no full list on home)
    try {
      final pending = await supabase
          .from('driver_available_orders')
          .select('id')
          .eq('status', 'confirmed');
      pendingOrdersCount = (pending as List).length;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Pending count: $e');
    }
  }

  Future<void> _toggleStatus(bool value) async {
    setState(() => isOnline = value);
    _setPulse();

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
      _setPulse();
    }
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  Future<void> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied)
      perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever)
      return;
    try {
      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
    } catch (e) {
      currentPosition = await Geolocator.getLastKnownPosition();
    }
    if (mounted) setState(() {});
  }

  Future<void> _call(String phone) async {
    if (phone.trim().isEmpty) return;
    final Uri url = Uri.parse("tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _launchGoogleMaps(double lat, double lng) async {
    final Uri url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════
  //                       BUILD
  // ════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.bg(context);
    final primary = AppColors.primary(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: primary,
          onRefresh: _init,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildStatusHero(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 24),
              if (hasActiveOrder) ...[
                _buildSectionLabel(L.t('active_order')),
                const SizedBox(height: 10),
                _buildActiveOrderCard(),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final text = AppColors.text(context);
    final textGrey = AppColors.textGrey(context);
    final card = AppColors.card(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${L.t('hello')}, $driverName 👋',
                style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(_vehicleIcon(vehicleType), size: 13, color: textGrey),
                  const SizedBox(width: 4),
                  Text(
                    _vehicleLabel(vehicleType),
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: card, shape: BoxShape.circle),
          child: Icon(Icons.notifications_none, color: text, size: 20),
        ),
      ],
    );
  }

  Widget _buildStatusHero() {
    final text = AppColors.text(context);
    final textGrey = AppColors.textGrey(context);
    final card = AppColors.card(context);
    final Color onColor = Colors.green;
    final Color activeColor = isOnline ? onColor : textGrey;

    return GestureDetector(
      onTap: () => _toggleStatus(!isOnline),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: isOnline ? Colors.green.withValues(alpha: 0.07) : card,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isOnline
                ? Colors.green.withValues(alpha: 0.45)
                : textGrey.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // Pulsing icon
            Stack(
              alignment: Alignment.center,
              children: [
                if (isOnline)
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Transform.scale(
                      scale: _pulseAnim.value,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withValues(alpha: 0.09),
                        ),
                      ),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeColor.withValues(alpha: 0.12),
                    border: Border.all(color: activeColor, width: 2.5),
                  ),
                  child: Icon(
                    isOnline
                        ? Icons.bolt_rounded
                        : Icons.power_settings_new_rounded,
                    color: activeColor,
                    size: 34,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              isOnline ? L.t('ready_for_orders') : L.t('not_ready'),
              style: TextStyle(
                color: text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 6),

            if (!isOnline)
              Text(
                L.t('tap_to_start'),
                style: TextStyle(color: textGrey, fontSize: 13),
              ),

            const SizedBox(height: 22),

            // Animated toggle pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 80,
              height: 34,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isOnline
                    ? Colors.green.withValues(alpha: 0.15)
                    : textGrey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isOnline
                      ? Colors.green.withValues(alpha: 0.4)
                      : textGrey.withValues(alpha: 0.25),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    alignment: isOnline
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? Colors.green : textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard(
          value: '$todayOrders',
          label: L.t('successful_deliveries'),
          icon: Icons.check_circle_outline_rounded,
          color: Colors.green,
        ),
        const SizedBox(width: 16),
        _statCard(
          value: '$pendingOrdersCount',
          label: L.t('pending_orders'),
          icon: Icons.inbox_outlined,
          color: Colors.orange,
          highlight: pendingOrdersCount > 0,
        ),
      ],
    );
  }

  Widget _statCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    bool highlight = false,
    bool mono = false,
  }) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: highlight
              ? Colors.orange.withValues(alpha: 0.1)
              : AppColors.card(context),
          borderRadius: BorderRadius.circular(20),
          border: highlight
              ? Border.all(color: Colors.orange.withValues(alpha: 0.35))
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: AppColors.text(context),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: mono ? 2 : 0,
                fontFeatures: mono
                    ? [const FontFeature.tabularFigures()]
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textGrey(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) => Text(
    label,
    style: TextStyle(
      color: AppColors.text(context),
      fontWeight: FontWeight.w900,
      fontSize: 16,
    ),
  );

  Widget _buildActiveOrderCard() {
    final primary = AppColors.primary(context);
    final text = AppColors.text(context);
    final textGrey = AppColors.textGrey(context);
    final card = AppColors.card(context);
    final isArabic = LanguageController.isArabic.value;

    final o = activeOrderDetails;
    if (o == null) return const SizedBox();

    final orderId = o['id'];
    final orderNum = o['order_number']?.toString() ?? '';
    final customerName = (o['customer_name'] ?? '').toString();
    final phone = (o['customer_phone'] ?? o['phone'] ?? '').toString();
    final status = (o['status'] ?? '').toString();
    final area = (o['area'] ?? '').toString();
    final street = (o['street'] ?? '').toString();
    final bool toRestaurant = status == 'accepted';

    final String destName = toRestaurant
        ? (isArabic
              ? (o['name_ar'] ?? L.t('restaurant')).toString()
              : (o['name_en'] ?? L.t('restaurant')).toString())
        : (customerName.isEmpty ? L.t('customer') : customerName);

    final String address = toRestaurant
        ? (o['restaurant_address'] ?? '').toString()
        : [street, area].where((e) => e.trim().isNotEmpty).join(', ');

    final double? lat = (o['lat'] as num?)?.toDouble();
    final double? lng = (o['lng'] as num?)?.toDouble();

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primary, width: 2),
      ),
      child: Column(
        children: [
          // Colored top bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  toRestaurant
                      ? Icons.restaurant_rounded
                      : Icons.delivery_dining_rounded,
                  color: AppColors.textOnPrimary(context),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  toRestaurant ? L.t('pickup_from') : L.t('deliver_to'),
                  style: TextStyle(
                    color: AppColors.textOnPrimary(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                if (orderNum.isNotEmpty)
                  Text(
                    '  •  ORD-$orderNum',
                    style: TextStyle(
                      color: AppColors.textOnPrimary(
                        context,
                      ).withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destName,
                  style: TextStyle(
                    color: text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: textGrey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DriverOrderDetailsScreen(orderId: orderId),
                            ),
                          ).then((_) => _init()),
                          icon: Icon(
                            Icons.open_in_new,
                            color: AppColors.textOnPrimary(context),
                            size: 16,
                          ),
                          label: Text(
                            L.t('open'),
                            style: TextStyle(
                              color: AppColors.textOnPrimary(context),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _iconBtn(icon: Icons.phone, onTap: () => _call(phone)),
                    if (lat != null && lng != null) ...[
                      const SizedBox(width: 8),
                      _iconBtn(
                        icon: Icons.navigation_rounded,
                        onTap: () => _launchGoogleMaps(lat, lng),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) {
    final primary = AppColors.primary(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          border: Border.all(color: primary.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: primary, size: 20),
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
}
