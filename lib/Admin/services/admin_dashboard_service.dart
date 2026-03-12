import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardStats {
  final int todayOrders;
  final int activeOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int driversOnline;
  final double revenue;

  const AdminDashboardStats({
    required this.todayOrders,
    required this.activeOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.driversOnline,
    required this.revenue,
  });

  // ✅ تحسين إضافي مفيد
  AdminDashboardStats copyWith({
    int? todayOrders,
    int? activeOrders,
    int? completedOrders,
    int? cancelledOrders,
    int? driversOnline,
    double? revenue,
  }) {
    return AdminDashboardStats(
      todayOrders: todayOrders ?? this.todayOrders,
      activeOrders: activeOrders ?? this.activeOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      cancelledOrders: cancelledOrders ?? this.cancelledOrders,
      driversOnline: driversOnline ?? this.driversOnline,
      revenue: revenue ?? this.revenue,
    );
  }
}

class AdminDashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AdminDashboardStats> fetchStats() async {
    try {
      final now = DateTime.now().toUtc();
      final startOfDay = DateTime.utc(now.year, now.month, now.day);
      final startOfMonth = DateTime.utc(now.year, now.month, 1);
      final startOfNextMonth = DateTime.utc(
        now.year,
        now.month + 1,
        1,
      ); // أبسط وأأمن

      final results = await Future.wait([
        // 0 - today orders
        _supabase
            .from('orders')
            .select('id')
            .gte('created_at', startOfDay.toIso8601String()),

        // 1 - active orders
        _supabase.from('orders').select('id').inFilter('status', [
          'pending',
          'confirmed',
          'preparing',
          'out_for_delivery',
        ]),

        // 2 - completed
        _supabase.from('orders').select('id').eq('status', 'delivered'),

        // 3 - cancelled
        _supabase.from('orders').select('id').eq('status', 'cancelled'),

        // 4 - revenue this month
        _supabase
            .from('orders')
            .select('total')
            .eq('status', 'delivered')
            .gte('created_at', startOfMonth.toIso8601String())
            .lt('created_at', startOfNextMonth.toIso8601String()),

        // 5 - drivers online
        _supabase.from('driver_profiles').select('id').eq('status', 'online'),
      ]);

      final revenue = (results[4] as List).fold<double>(
        0,
        (sum, row) => sum + (((row as Map)['total'] as num?)?.toDouble() ?? 0),
      );

      return AdminDashboardStats(
        todayOrders: (results[0] as List).length,
        activeOrders: (results[1] as List).length,
        completedOrders: (results[2] as List).length,
        cancelledOrders: (results[3] as List).length,
        driversOnline: (results[5] as List).length,
        revenue: revenue,
      );
    } catch (e) {
      debugPrint('fetchStats error: $e');

      // ✅ لا نكسر التطبيق إذا فشل الاتصال
      return const AdminDashboardStats(
        todayOrders: 0,
        activeOrders: 0,
        completedOrders: 0,
        cancelledOrders: 0,
        driversOnline: 0,
        revenue: 0,
      );
    }
  }
}
