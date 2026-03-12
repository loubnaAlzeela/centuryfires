import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_view_model.dart';

class OrderViewService {
  final supabase = Supabase.instance.client;

  Future<List<OrderViewModel>> getMyOrdersWithAddress() async {
    final session = supabase.auth.currentSession;
    if (session == null) return [];

    final res = await supabase
        .from('customer_orders_view')
        .select('*')
        .eq('customer_auth_id', session.user.id)
        .order('created_at', ascending: false);

    // Fetch the correct driver_fee from the orders table directly since the view lacks it
    final orderIds = (res as List).map((e) => e['id']).toList();
    
    if (orderIds.isNotEmpty) {
      final ordersRes = await supabase
          .from('orders')
          .select('id, driver_fee, discount_coupon, discount_big_order, applied_coupon_code')
          .inFilter('id', orderIds);
          
      final Map<String, Map<String, dynamic>> extraMap = {
        for (var o in ordersRes) o['id'].toString(): o
      };

      for (var row in res) {
        final extra = extraMap[row['id'].toString()];
        if (extra != null) {
          row['driver_fee'] = extra['driver_fee'];
          row['discount_coupon'] = extra['discount_coupon'];
          row['discount_big_order'] = extra['discount_big_order'];
          row['applied_coupon_code'] = extra['applied_coupon_code'];
        }
      }
    }

    return res
        .map((e) => OrderViewModel.fromMap(e))
        .toList();
  }

  // ✅ لجلب تفاصيل طلب واحد (للـ Tracking screen)
  Future<OrderViewModel?> getOrderById(String orderId) async {
    final session = supabase.auth.currentSession;
    if (session == null) return null;

    final res = await supabase
        .from('customer_orders_view')
        .select('*')
        .eq('id', orderId)
        .eq('customer_auth_id', session.user.id)
        .maybeSingle();

    if (res is Map<String, dynamic>) {
      // Fetch driver_fee from orders
      try {
        final orderRow = await supabase
            .from('orders')
            .select('driver_fee, discount_coupon, discount_big_order, applied_coupon_code')
            .eq('id', orderId)
            .maybeSingle();
        if (orderRow != null) {
          res['driver_fee'] = orderRow['driver_fee'];
          res['discount_coupon'] = orderRow['discount_coupon'];
          res['discount_big_order'] = orderRow['discount_big_order'];
          res['applied_coupon_code'] = orderRow['applied_coupon_code'];
        }
      } catch (_) {}

      return OrderViewModel.fromMap(res);
    }
    return null;
  }
}
