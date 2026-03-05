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

class _DriverOrdersScreenState extends State<DriverOrdersScreen> {
  final supabase = Supabase.instance.client;

  RealtimeChannel? _ordersChannel;
  //bool _isLoading = false;
  List<Map<String, dynamic>> allOrders = [];
  bool loading = true;
  Position? currentPosition;
  int _tabIndex = 0; // 0=new, 1=active, 2=done

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _getCurrentLocation();
    await _loadOrders();
    _listenToOrders();
  }

  @override
  void dispose() {
    _ordersChannel?.unsubscribe();
    super.dispose();
  }

  // ================= LOAD =================
  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() => loading = true);

    final session = supabase.auth.currentSession;
    if (session == null) return;

    final userRes = await supabase
        .from('users')
        .select('id')
        .eq('auth_id', session.user.id)
        .single();

    final userId = userRes['id'];

    List data = [];

    // 🔥 NEW
    final newOrders = await supabase
        .from('driver_available_orders')
        .select('*')
        .order('created_at', ascending: false);

    // 🔥 ACTIVE
    // 🔥 ACTIVE (الأحدث فوق)
    final activeOrders = await supabase
        .from('driver_order_details_view') // ✅ الفيو اللي فيها العنوان
        .select('*')
        .eq('driver_id', userId)
        .eq('status', 'out_for_delivery')
        .order('created_at', ascending: false);

    final doneOrders = await supabase
        .from('driver_order_details_view') // ✅ الفيو اللي فيها العنوان
        .select('*')
        .eq('driver_id', userId)
        .eq('status', 'delivered')
        .order('created_at', ascending: false);

    data = [...newOrders, ...activeOrders, ...doneOrders];

    allOrders = List<Map<String, dynamic>>.from(data);

    if (!mounted) return;
    setState(() => loading = false);
  }

  // ================= REALTIME =================
  void _listenToOrders() {
    _ordersChannel?.unsubscribe();

    _ordersChannel = supabase
        .channel('orders-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) async {
            await _loadOrders();
          },
        )
        .subscribe();
  }

  //================ Calculate Distance =========================
  double? _calculateDistance(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (currentPosition == null) return null;

    final meters = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      lat,
      lng,
    );

    return meters / 1000.0;
  }

  //===========================================
  Future<void> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ================= FILTER =================
  List<Map<String, dynamic>> _currentList() {
    if (_tabIndex == 0) {
      return allOrders.where((o) => o['status'] == 'confirmed').toList();
    }
    if (_tabIndex == 1) {
      return allOrders.where((o) => o['status'] == 'out_for_delivery').toList();
    }
    return allOrders.where((o) => o['status'] == 'delivered').toList();
  }

  // ================= ACCEPT =================
  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    final session = supabase.auth.currentSession;
    if (session == null) return;

    try {
      // 🔥 جيب الـ internal user id تبع جدول users
      final userRes = await supabase
          .from('users')
          .select('id')
          .eq('auth_id', session.user.id)
          .single();

      final userId = userRes['id'];

      // 🔥 حدث الطلب
      await supabase
          .from('orders')
          .update({
            'status': 'out_for_delivery',
            'driver_id': userId,
            'accepted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', order['id']);

      if (!mounted) return;

      // 🔥 روح عالتفاصيل وانتظر الرجوع
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverOrderDetailsScreen(
            orderId: order['id'], // UUID
          ),
        ),
      );

      // 🔥 بعد ما يرجع من التفاصيل اعمل refresh
      await _loadOrders();
    } catch (e) {
      debugPrint('Accept order error: $e');
    }
  }

  // ================= DECLINE =================
  Future<void> _declineOrder(String orderId) async {
    await supabase
        .from('orders')
        .update({'status': 'declined'})
        .eq('id', orderId);

    await _loadOrders();
  }

  // ================= TABS =================
  Widget _tabs() {
    final newCount = allOrders.where((o) => o['status'] == 'confirmed').length;

    final activeCount = allOrders
        .where((o) => o['status'] == 'out_for_delivery')
        .length;

    final doneCount = allOrders.where((o) => o['status'] == 'delivered').length;

    return SizedBox(
      height: 54,
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
      onTap: () async {
        if (_tabIndex == index) return;

        setState(() {
          _tabIndex = index;
        });

        await _loadOrders();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? primary : AppColors.card(context),
          borderRadius: BorderRadius.circular(999),
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

  // ================= STATUS TEXT =================
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

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _tabs(),
            const SizedBox(height: 12),
            Expanded(
              child: loading
                  ? Center(child: CircularProgressIndicator(color: primary))
                  : Builder(
                      builder: (context) {
                        final currentList = _currentList();

                        if (currentList.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 48,
                                  color: AppColors.textGrey(context),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  L.t('no_orders'),
                                  style: TextStyle(
                                    color: AppColors.textGrey(context),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: currentList.length,
                          itemBuilder: (context, i) {
                            return _orderCard(context, order: currentList[i]);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= ORDER CARD =================
  Widget _orderCard(
    BuildContext context, {
    required Map<String, dynamic> order,
  }) {
    final primary = AppColors.primary(context);
    final text = AppColors.text(context);
    final textGrey = AppColors.textGrey(context);
    final card = AppColors.card(context);

    final orderNumber = (order['order_number'] ?? 0).toString().padLeft(3, '0');
    final customerName = (order['customer_name'] ?? '').toString();
    final area = (order['area'] ?? '').toString();
    final status = (order['status'] ?? '').toString();

    final lat = (order['lat'] as num?)?.toDouble();
    final lng = (order['lng'] as num?)?.toDouble();
    final distanceKm = _calculateDistance(lat, lng);

    final canOpenDetails =
        status == 'out_for_delivery' || status == 'completed';

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: canOpenDetails
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
            // ================= TOP ROW =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _statusText(status),
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

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
                    distanceKm == null
                        ? '— km'
                        : '${distanceKm.toStringAsFixed(1)} km',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ================= CUSTOMER =================
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
                    area.isEmpty ? L.t('address_not_available') : area,
                    style: TextStyle(
                      color: textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // ================= BUTTONS =================
            if (status == 'confirmed') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineOrder(order['id'].toString()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        L.t('decline'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptOrder(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: AppColors.textOnPrimary(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        L.t('accept'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
