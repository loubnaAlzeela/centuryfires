import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/cart_controller.dart';

class CheckoutService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// =====================================================
  /// 🧾 PLACE ORDER (FINAL – FIXED ADDONS)
  /// =====================================================
  Future<String> placeOrder({
    required String userId,
    required String addressId,
    String? notes,
  }) async {
    // =============================
    // 1️⃣ Ensure cart loaded
    // =============================
    await CartController.instance.loadCart();
    final lines = CartController.instance.lines;

    if (lines.isEmpty) {
      throw Exception('Cart is empty');
    }

    // =============================
    // 2️⃣ Build items payload (CORRECT)
    // =============================
    final items = lines.map((line) {
      // 🔹 build addons with price (IMPORTANT)
      final addons = <Map<String, dynamic>>[];

      for (int i = 0; i < line.addonIds.length; i++) {
        addons.add({'addon_id': line.addonIds[i]});
      }

      return {
        'meal_id': line.mealId, // uuid
        'meal_size_id': line.mealSizeId, // null OR uuid
        'quantity': line.quantity,
        'unit_price': line.price,
        'addons': addons.isEmpty ? null : addons,
      };
    }).toList();

    final total = lines.fold<double>(0, (sum, l) => sum + l.total);

    // =============================
    // 3️⃣ Call Supabase RPC
    // =============================
    try {
      final res = await _supabase.rpc(
        'place_order',
        params: {
          'p_user_id': userId,
          'p_total': total,
          'p_notes': notes,
          'p_address_id': addressId,
          'p_items': items,
        },
      );

      final orderId = res.toString();

      // =============================
      // 4️⃣ Clear cart AFTER success
      // =============================
      await CartController.instance.clear();

      return orderId;
    } catch (e) {
      rethrow;
    }
  }
}
