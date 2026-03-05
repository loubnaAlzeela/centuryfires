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

    return (res as List)
        .map((e) => OrderViewModel.fromMap(e as Map<String, dynamic>))
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
      return OrderViewModel.fromMap(res);
    }
    return null;
  }
}
