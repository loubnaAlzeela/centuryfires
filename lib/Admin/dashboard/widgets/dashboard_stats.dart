import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/admin_dashboard_service.dart';
import 'dashboard_stat_card.dart';
import '../../../utils/l.dart';
import '../../navigation/admin_page.dart';

class DashboardStats extends StatefulWidget {
  final void Function(AdminPage)? onNavigate;
  const DashboardStats({super.key, this.onNavigate});

  @override
  State<DashboardStats> createState() => _DashboardStatsState();
}

class _DashboardStatsState extends State<DashboardStats> {
  late Future<AdminDashboardStats> _statsFuture;
  RealtimeChannel? _dashboardChannel;

  @override
  void initState() {
    super.initState();
    _refresh();
    _listenToEvents();
  }

  void _listenToEvents() {
    _dashboardChannel = Supabase.instance.client
        .channel('admin_dashboard_stats_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) {
            if (mounted) _refresh();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'driver_profiles',
          callback: (_) {
            if (mounted) _refresh();
          },
        )
        .subscribe();
  }

  void _refresh() {
    setState(() {
      _statsFuture = AdminDashboardService().fetchStats();
    });
  }

  @override
  void dispose() {
    _dashboardChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminDashboardStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    L.t('error_general'),
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _refresh, child: Text(L.t('retry'))),
                ],
              ),
            ),
          );
        }

        final stats = snapshot.data!;
        final width = MediaQuery.of(context).size.width;
        final crossAxisCount = width >= 900 ? 4 : 2;

        final items = _buildItems(stats, context);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: width >= 900 ? 1.25 : 1.1,
          ),
          itemBuilder: (context, index) => items[index],
        );
      },
    );
  }

  List<DashboardStatCard> _buildItems(
    AdminDashboardStats stats,
    BuildContext context,
  ) {
    final navigate = widget.onNavigate;
    return [
      // 🟡 Today's Orders
      DashboardStatCard(
        title: L.t('todays_orders'),
        value: stats.todayOrders.toString(),
        icon: Icons.receipt_long,
        color: Colors.amber,
        onTap: navigate != null ? () => navigate(AdminPage.orders) : null,
      ),

      // 🔵 Active Orders
      DashboardStatCard(
        title: L.t('active_orders'),
        value: stats.activeOrders.toString(),
        icon: Icons.timelapse,
        color: Colors.blue,
        onTap: navigate != null ? () => navigate(AdminPage.orders) : null,
      ),

      // 🟢 Completed
      DashboardStatCard(
        title: L.t('completed_orders'),
        value: stats.completedOrders.toString(),
        icon: Icons.check_circle,
        color: Colors.green,
        onTap: navigate != null ? () => navigate(AdminPage.orders) : null,
      ),

      // 🔴 Cancelled
      DashboardStatCard(
        title: L.t('cancelled_orders'),
        value: stats.cancelledOrders.toString(),
        icon: Icons.cancel,
        color: Colors.red,
        onTap: navigate != null ? () => navigate(AdminPage.orders) : null,
      ),

      // 🟣 Revenue
      DashboardStatCard(
        title: L.t('revenue_this_month'),
        value: "${L.t('currency')} ${stats.revenue.toStringAsFixed(2)}",
        icon: Icons.payments,
        color: Colors.purple,
      ),

      // 🟠 Drivers Online
      DashboardStatCard(
        title: L.t('drivers_online'),
        value: stats.driversOnline.toString(),
        icon: Icons.delivery_dining,
        color: Colors.orange,
        onTap: navigate != null ? () => navigate(AdminPage.drivers) : null,
      ),
    ];
  }
}
