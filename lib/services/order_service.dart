import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../utils/language_controller.dart';

class ReorderItem {
  final String mealId;
  final String? mealSizeId;
  final int quantity;
  final List<String> addonIds;

  ReorderItem({
    required this.mealId,
    required this.quantity,
    this.mealSizeId,
    required this.addonIds,
  });
}

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // ✅ جلب الطلبات + النقاط + اسم وصورة أول وجبة
  // =====================================================
  Future<List<OrderModel>> getMyOrders() async {
    // 1️⃣ Auth
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) {
      throw Exception('Not authenticated');
    }

    // 🧠 Snapshot للغة (حل race condition)
    final bool isArabic = LanguageController.ar;

    // 2️⃣ user_id
    final userRow = await _supabase
        .from('users')
        .select('id')
        .eq('auth_id', authId)
        .maybeSingle();

    if (userRow == null) {
      throw Exception('User not found');
    }

    final String userId = userRow['id']?.toString() ?? '';
    if (userId.isEmpty) {
      throw Exception('Invalid user ID');
    }

    // 3️⃣ orders (limit للحماية)
    final List<dynamic> orders = await _supabase
        .from('orders')
        .select('id, total, status, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    if (orders.isEmpty) return [];

    final List<String> orderIds = orders
        .map((o) => o['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    if (orderIds.isEmpty) return [];

    // 4️⃣ loyalty points
    final List<dynamic> pointsRows = await _supabase
        .from('loyalty_points_log')
        .select('order_id, points')
        .eq('user_id', userId)
        .inFilter('order_id', orderIds);

    final Map<String, int> pointsMap = {
      for (final p in pointsRows)
        p['order_id']?.toString() ?? '': ((p['points'] as num?)?.toInt() ?? 0)
            .clamp(0, 100000),
    };

    // 5️⃣ order_items (meal_id فقط) + منع التكرار
    final List<dynamic> orderItems = await _supabase
        .from('order_items')
        .select('order_id, meal_id')
        .inFilter('order_id', orderIds);

    final Map<String, Set<String>> orderMealsMap = {};
    for (final row in orderItems) {
      final String oid = row['order_id']?.toString() ?? '';
      final String mid = row['meal_id']?.toString() ?? '';
      if (oid.isEmpty || mid.isEmpty) continue;

      orderMealsMap.putIfAbsent(oid, () => <String>{}).add(mid);
    }

    // 6️⃣ meals
    final mealIds = orderMealsMap.values.expand((e) => e).toSet().toList();

    final List<dynamic> meals = mealIds.isEmpty
        ? []
        : await _supabase
              .from('meals')
              .select('id, name_en, name_ar, image_url')
              .inFilter('id', mealIds);

    final Map<String, Map<String, dynamic>> mealsMap = {
      for (final m in meals) m['id']?.toString() ?? '': m,
    };

    // 7️⃣ build OrderModel
    return orders.map<OrderModel>((o) {
      final String orderId = o['id']?.toString() ?? '';
      final mealIdsForOrder = orderMealsMap[orderId] ?? <String>{};

      String? title;
      String? imageUrl;

      // 🔍 أول meal موجود فعلياً
      for (final mealId in mealIdsForOrder) {
        final meal = mealsMap[mealId];
        if (meal != null) {
          title = (isArabic ? meal['name_ar'] : meal['name_en'])?.toString();
          imageUrl = _validateImageUrl(meal['image_url']);
          if (title != null && title.isNotEmpty) break;
        }
      }

      return OrderModel(
        id: orderId,
        total: double.tryParse(o['total']?.toString() ?? '0') ?? 0.0,
        status: o['status']?.toString() ?? 'pending',
        createdAt:
            DateTime.tryParse(o['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        points: pointsMap[orderId] ?? 0,
        title: title,
        imageUrl: imageUrl,
        itemsCount: mealIdsForOrder.length,
      );
    }).toList();
  }

  // =====================================================
  // 🔁 Re-Order (تحسينات أمان بسيطة فقط)
  // =====================================================
  Future<List<ReorderItem>> getReorderItems(String orderId) async {
    if (orderId.trim().isEmpty) {
      throw Exception('Invalid order ID');
    }

    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) throw Exception('Not authenticated');

    final userRow = await _supabase
        .from('users')
        .select('id')
        .eq('auth_id', authId)
        .maybeSingle();

    if (userRow == null) throw Exception('User not found');
    final myUserId = userRow['id']?.toString() ?? '';

    final order = await _supabase
        .from('orders')
        .select('id, user_id, status')
        .eq('id', orderId)
        .maybeSingle();

    if (order == null) throw Exception('Order not found');
    if (order['user_id']?.toString() != myUserId) {
      throw Exception('Unauthorized');
    }
    if (order['status']?.toString() != 'delivered') {
      throw Exception('Order not delivered');
    }

    final List<dynamic> items = await _supabase
        .from('order_items')
        .select('id, meal_id, meal_size_id, quantity')
        .eq('order_id', orderId);

    if (items.isEmpty) return [];

    final List<String> itemIds = items
        .map((e) => e['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    final List<dynamic> addonsRows = itemIds.isEmpty
        ? []
        : await _supabase
              .from('order_item_addons')
              .select('order_item_id, addon_id')
              .inFilter('order_item_id', itemIds);

    final Map<String, List<String>> addonsMap = {};
    for (final row in addonsRows) {
      final String itemId = row['order_item_id']?.toString() ?? '';
      final String addonId = row['addon_id']?.toString() ?? '';
      if (itemId.isEmpty || addonId.isEmpty) continue;

      addonsMap.putIfAbsent(itemId, () => []).add(addonId);
    }

    return items.map<ReorderItem>((row) {
      return ReorderItem(
        mealId: row['meal_id']?.toString() ?? '',
        mealSizeId: row['meal_size_id']?.toString(),
        quantity: ((row['quantity'] as num?)?.toInt() ?? 1).clamp(1, 99),
        addonIds: addonsMap[row['id']?.toString() ?? ''] ?? [],
      );
    }).toList();
  }

  // =====================================================
  // 🔒 Image URL validation
  // =====================================================
  String? _validateImageUrl(dynamic url) {
    final value = url?.toString().trim();
    if (value == null || value.isEmpty) return null;
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      return null;
    }
    return value;
  }
}
