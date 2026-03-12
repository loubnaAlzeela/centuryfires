import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOrdersService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ✅ تجنب تكرار select string
  static const String _orderSelect = '''
    id,
    order_number,
    status,
    subtotal,
    driver_fee,
    discount,
    discount_coupon,
    discount_big_order,
    applied_coupon_code,
    total,
    payment_method,
    payment_provider,
    created_at,
    user_id,
    users (
      id,
      name,
      phone,
      email
    ),
    order_items (
      quantity,
      unit_price,
      total_price,
      notes,
      meals (
        name_en,
        name_ar
      )
    )
  ''';

  Future<List<Map<String, dynamic>>> getOrders({String? status}) async {
    try {
      var query = _supabase.from('orders').select(_orderSelect);

      final response = status != null
          ? await query
                .eq('status', status)
                .order('created_at', ascending: false)
          : await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('getOrders error: $e');
      return [];
    }
  }

  Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': status})
          .eq('id', orderId);

      return true;
    } catch (e) {
      debugPrint('updateOrderStatus error: $e');
      return false;
    }
  }
}
