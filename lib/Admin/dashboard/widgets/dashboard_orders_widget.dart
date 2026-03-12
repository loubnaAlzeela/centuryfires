import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_colors.dart';
import 'dashboard_order_row.dart';
import '../../../utils/l.dart';

class DashboardOrdersWidget extends StatefulWidget {
  const DashboardOrdersWidget({super.key});

  @override
  State<DashboardOrdersWidget> createState() => _DashboardOrdersWidgetState();
}

class _DashboardOrdersWidgetState extends State<DashboardOrdersWidget> {
  final SupabaseClient _supabase = Supabase.instance.client;

  late final RealtimeChannel _ordersChannel;

  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  String? _latestOrderId;

  late Timer _timer;

  static const List<String> _vipTiers = ['Diamond', 'Gold'];

  @override
  void initState() {
    super.initState();
    _fetchRecentOrders();
    _listenToNewOrders();

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  // ================= REALTIME =================

  void _listenToNewOrders() {
    _ordersChannel = _supabase.channel('orders_channel_widget');

    _ordersChannel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            final newId = payload.newRecord['id']?.toString();
            if (newId != null) {
              _handleNewOrder(newId);
            }
          },
        )
        .subscribe();
  }

  void _handleNewOrder(String newId) {


    setState(() {
      _latestOrderId = newId;
    });

    _fetchRecentOrders();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _latestOrderId = null;
        });
      }
    });
  }


  // ================= DATA =================

  Future<void> _fetchRecentOrders() async {
    try {
      final ordersRes = await _supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false)
          .limit(5);

      final fetchedOrders = List<Map<String, dynamic>>.from(ordersRes);

      if (fetchedOrders.isNotEmpty) {
        final userIds = fetchedOrders
            .map((o) => o['user_id'])
            .where((id) => id != null)
            .toSet()
            .toList();

        final usersRes = await _supabase
            .from('users')
            .select('id, name')
            .inFilter('id', userIds);

        final users = List<Map<String, dynamic>>.from(usersRes);
        final usersMap = {for (var u in users) u['id']: u['name']};

        final loyaltyRes = await _supabase
            .from('user_loyalty')
            .select('user_id, loyalty_tiers(name_en)')
            .inFilter('user_id', userIds);

        final loyalty = List<Map<String, dynamic>>.from(loyaltyRes);

        final loyaltyMap = {
          for (var l in loyalty) l['user_id']: l['loyalty_tiers']?['name_en'],
        };

        for (var o in fetchedOrders) {
          o['customer_name'] = usersMap[o['user_id']] ?? L.t('guest');
          o['tier'] = loyaltyMap[o['user_id']];
        }
      }

      if (mounted) {
        setState(() {
          orders = fetchedOrders;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('_fetchRecentOrders error: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _card(
        context,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (orders.isEmpty) {
      return _card(
        context,
        child: Text(
          L.t('no_recent_orders'),
          style: TextStyle(color: AppColors.textGrey(context)),
        ),
      );
    }

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.t('recent_orders'),
            style: TextStyle(
              color: AppColors.text(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(orders.length, (index) {
            final o = orders[index];
            final isLast = index == orders.length - 1;

            final createdAt = DateTime.parse(o['created_at']);
            final diff = DateTime.now().difference(createdAt);

            final isNew = o['id']?.toString() == _latestOrderId;

            bool isLate = false;
            Color? lateColor;

            if (o['status'] == 'pending' && diff.inMinutes > 5) {
              isLate = true;
              lateColor = Colors.orange;
            }

            if (o['status'] == 'preparing' && diff.inMinutes > 20) {
              isLate = true;
              lateColor = Colors.red;
            }

            final tier = o['tier'];
            final isVIP = tier != null && _vipTiers.contains(tier);

            final customerName = o['customer_name'] ?? L.t('guest');

            return Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isNew ? Colors.green.withValues(alpha: 0.08) : null,
                    border: isLate
                        ? Border.all(color: lateColor!, width: 2)
                        : isNew
                        ? Border.all(color: Colors.green, width: 1.5)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DashboardOrderRow(
                    orderId: isVIP ? '$customerName ⭐' : customerName,
                    // ✅ pass raw status — DashboardOrderRow handles
                    // normalization and L.t() translation internally
                    status: o['status'] ?? '',
                    time: _timeAgo(createdAt),
                  ),
                ),
                if (!isLast) const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return L.t('just_now');
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${L.t('min_ago')}';
    if (diff.inHours < 24) return '${diff.inHours} ${L.t('h_ago')}';
    return '${diff.inDays} ${L.t('d_ago')}';
  }

  @override
  void dispose() {
    _timer.cancel();
    _supabase.removeChannel(_ordersChannel);
    super.dispose();
  }
}
