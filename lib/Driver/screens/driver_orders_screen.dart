import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_colors.dart';
import '../../utils/l.dart';
import 'driver_order_details_screen.dart';

class DriverOrdersScreen extends StatefulWidget {
  const DriverOrdersScreen({super.key});

  @override
  State<DriverOrdersScreen> createState() => _DriverOrdersScreenState();
}

class _DriverOrdersScreenState extends State<DriverOrdersScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  RealtimeChannel? _ordersChannel;
  List<Map<String, dynamic>> allOrders = [];
  bool loading = true;
  Position? currentPosition;
  int _tabIndex = 0;

  // ── Animation ──
  late AnimationController _listCtrl;
  Key _listKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _init();
  }

  Future<void> _init() async {
    await _getCurrentLocation();
    await _loadOrders();
    _listenToOrders();
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    _ordersChannel?.unsubscribe();
    super.dispose();
  }

  // ── Load ──
  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() => loading = true);

    final session = supabase.auth.currentSession;
    if (session == null) return;

    try {
      final userRes = await supabase
          .from('users')
          .select('id')
          .eq('auth_id', session.user.id)
          .single();
      final userId = userRes['id'];

      // FIX 1: جلب confirmed فقط بدون status filter إضافي
      final newOrders = await supabase
          .from('driver_available_orders')
          .select('*')
          .eq('status', 'confirmed')
          .order('created_at', ascending: false);

      final activeOrders = await supabase
          .from('driver_order_details_view')
          .select('*')
          .eq('driver_id', userId)
          .eq('status', 'out_for_delivery')
          .order('created_at', ascending: false);

      final doneOrders = await supabase
          .from('driver_order_details_view')
          .select('*')
          .eq('driver_id', userId)
          .eq('status', 'delivered')
          .order('created_at', ascending: false);

      allOrders = List<Map<String, dynamic>>.from([
        ...newOrders,
        ...activeOrders,
        ...doneOrders,
      ]);
    } catch (e) {
      debugPrint('❌ Load orders: $e');
    }

    if (!mounted) return;
    setState(() => loading = false);
    // ── trigger stagger animation بعد التحميل ──
    _listCtrl.forward(from: 0);
  }

  // FIX 2: اسم channel مختلف عن HomeScreen
  void _listenToOrders() {
    _ordersChannel?.unsubscribe();
    _ordersChannel = supabase
        .channel('driver-orders-screen-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) async => await _loadOrders(),
        )
        .subscribe();
  }

  double? _calculateDistance(double? lat, double? lng) {
    if (lat == null || lng == null || currentPosition == null) return null;
    final meters = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      lat,
      lng,
    );
    return meters / 1000.0;
  }

  Future<void> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
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
  }

  // FIX 3: الفلتر فقط بدون إعادة fetch
  List<Map<String, dynamic>> _currentList() {
    if (_tabIndex == 0) {
      return allOrders.where((o) => o['status'] == 'confirmed').toList();
    }
    if (_tabIndex == 1) {
      return allOrders.where((o) => o['status'] == 'out_for_delivery').toList();
    }
    return allOrders.where((o) => o['status'] == 'delivered').toList();
  }

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    final session = supabase.auth.currentSession;
    if (session == null) return;
    try {
      final userRes = await supabase
          .from('users')
          .select('id')
          .eq('auth_id', session.user.id)
          .single();
      await supabase
          .from('orders')
          .update({
            'status': 'out_for_delivery',
            'driver_id': userRes['id'],
            'accepted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', order['id']);

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverOrderDetailsScreen(orderId: order['id']),
        ),
      );
      await _loadOrders();
    } catch (e) {
      debugPrint('❌ Accept order: $e');
    }
  }

  Future<void> _declineOrder(String orderId) async {
    await supabase
        .from('orders')
        .update({'status': 'declined'})
        .eq('id', orderId);
    await _loadOrders();
  }

  String _timeAgo(String createdAt) {
    try {
      final mins = DateTime.now()
          .difference(DateTime.parse(createdAt))
          .inMinutes;
      if (mins <= 0) return '${L.t('before')} 1 ${L.t('min')}';
      if (mins < 60) return '${L.t('before')} $mins ${L.t('min')}';
      final h = (mins / 60).floor();
      return '${L.t('before')} $h ${L.t('hour')}';
    } catch (_) {
      return '';
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'confirmed':
        return L.t('confirmed');
      case 'out_for_delivery':
        return L.t('on_the_way');
      case 'delivered':
        return L.t('delivered');
      default:
        return status;
    }
  }

  // ════════════════════════════════════════════
  //                    BUILD
  // ════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildTabs(),
            const SizedBox(height: 12),
            Expanded(
              child: loading
                  ? Center(child: CircularProgressIndicator(color: primary))
                  : RefreshIndicator(
                      // FIX 4: pull-to-refresh
                      color: primary,
                      onRefresh: _loadOrders,
                      child: Builder(
                        builder: (context) {
                          final list = _currentList();
                          if (list.isEmpty) return _buildEmpty();
                          return ListView.builder(
                            key: _listKey,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: list.length,
                            itemBuilder: (context, i) => _AnimatedCard(
                              index: i,
                              controller: _listCtrl,
                              child: _buildOrderCard(list[i]),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tabs ──
  Widget _buildTabs() {
    final newCount = allOrders.where((o) => o['status'] == 'confirmed').length;
    final activeCount = allOrders
        .where((o) => o['status'] == 'out_for_delivery')
        .length;
    final doneCount = allOrders.where((o) => o['status'] == 'delivered').length;

    return SizedBox(
      height: 60,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _tabItem(0, L.t('new'), newCount),
          const SizedBox(width: 10),
          _tabItem(1, L.t('active'), activeCount),
          const SizedBox(width: 10),
          _tabItem(2, L.t('completed'), doneCount),
        ],
      ),
    );
  }

  Widget _tabItem(int index, String title, int count) {
    final isActive = _tabIndex == index;
    final primary = AppColors.primary(context);
    final text = AppColors.text(context);
    final textOnPrimary = AppColors.textOnPrimary(context);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      // FIX 5: تبديل التاب بدون fetch + trigger animation
      onTap: () {
        setState(() {
          _tabIndex = index;
          _listKey = UniqueKey(); // يعيد بناء الـ list مع animation جديدة
        });
        _listCtrl.forward(from: 0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? primary : AppColors.card(context),
          borderRadius: BorderRadius.circular(999),
          border: isActive
              ? null
              : Border.all(
                  color: text.withValues(alpha: 0.1),
                  width: 1.5,
                ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isActive ? textOnPrimary : text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isActive ? textOnPrimary : AppColors.textGrey(context))
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isActive ? textOnPrimary : text,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty ──
  Widget _buildEmpty() {
    return ListView(
      // مهم لـ pull-to-refresh يشتغل حتى لو فاضي
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 52,
              color: AppColors.textGrey(context),
            ),
            const SizedBox(height: 14),
            Text(
              L.t('no_orders'),
              style: TextStyle(
                color: AppColors.textGrey(context),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Order Card ──
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final primary = AppColors.primary(context);
    final text = AppColors.text(context);
    final textGrey = AppColors.textGrey(context);
    final card = AppColors.card(context);

    final status = (order['status'] ?? '').toString();
    final isNew = status == 'confirmed';
    final isActive = status == 'out_for_delivery';
    final isDone = status == 'delivered';

    final orderNumber = (order['order_number'] ?? 0).toString();
    final customerName = (order['customer_name'] ?? '').toString();
    final area = (order['area'] ?? '').toString();
    final street = (order['street'] ?? '').toString();

    final lat = (order['lat'] as num?)?.toDouble();
    final lng = (order['lng'] as num?)?.toDouble();
    final distanceKm = _calculateDistance(lat, lng);

    // FIX 6: فتح التفاصيل لـ out_for_delivery و delivered
    final canOpen = isActive || isDone;

    // FIX 7: ألوان مميزة لكل حالة
    final Color borderColor = isNew
        ? primary
        : isActive
        ? Colors.orange
        : AppColors.textGrey(context).withValues(alpha: 0.3);

    final Color? bgColor = isNew
        ? null
        : isActive
        ? Colors.orange.withValues(alpha: 0.05)
        : null;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: canOpen
          ? () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DriverOrderDetailsScreen(orderId: order['id']),
                ),
              );
              await _loadOrders();
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: bgColor ?? card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: borderColor.withValues(alpha: isNew ? 1.0 : 0.4),
            width: isNew ? 2 : 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Row ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: text.withValues(alpha: 0.3),
                        width: 1,
                      ),
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusText(status),
                      style: TextStyle(
                        color: borderColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (distanceKm != null)
                    Row(
                      children: [
                        Icon(Icons.near_me_outlined, size: 12, color: textGrey),
                        const SizedBox(width: 3),
                        Text(
                          '${distanceKm.toStringAsFixed(1)} km',
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Time ──
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 13, color: textGrey),
                  const SizedBox(width: 4),
                  Text(
                    _timeAgo((order['created_at'] ?? '').toString()),
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // ── Customer ──
              Text(
                customerName.isEmpty ? L.t('customer') : customerName,
                style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 5),

              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: textGrey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      [street, area]
                          .where((e) => e.trim().isNotEmpty)
                          .join(', ')
                          .ifEmpty(L.t('address_not_available')),
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Buttons (new orders only) ──
              if (isNew) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => _acceptOrder(order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: AppColors.textOnPrimary(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () =>
                              _declineOrder(order['id'].toString()),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textGrey,
                            side: BorderSide(
                              color: textGrey.withValues(alpha: 0.35),
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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

              // ── Active: tap hint ──
              if (isActive) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 13,
                      color: Colors.orange.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      L.t('tap_to_open_details'),
                      style: TextStyle(
                        color: Colors.orange.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

// ── Staggered Card Animation ──
class _AnimatedCard extends StatelessWidget {
  final int index;
  final AnimationController controller;
  final Widget child;

  const _AnimatedCard({
    required this.index,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // كل كارد يبدأ بعد الي قبله بـ 80ms
    final delay = (index * 0.12).clamp(0.0, 0.85);
    final end = (delay + 0.55).clamp(0.0, 1.0);

    final slide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(delay, end, curve: Curves.easeOutCubic),
          ),
        );

    final fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(delay, end, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      ),
    );
  }
}
