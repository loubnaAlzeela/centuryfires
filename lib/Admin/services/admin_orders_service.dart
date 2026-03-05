import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOrdersService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ✅ تجنب تكرار select string
  static const String _orderSelect = '''
    id,
    status,
    total,
    created_at,
    users (
      name
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
