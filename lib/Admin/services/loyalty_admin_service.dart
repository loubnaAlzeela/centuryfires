import 'package:supabase_flutter/supabase_flutter.dart';

class LoyaltyAdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===============================
  // 📊 STATS
  // ===============================

  Future<int> getTotalMembers() async {
    final data = await _supabase.from('users').select('id');
    return data.length;
  }

  Future<int> getDiamondMembers() async {
    final diamondTier = await _supabase
        .from('loyalty_tiers')
        .select('id')
        .eq('name_en', 'diamond')
        .maybeSingle();

    if (diamondTier == null) return 0;

    final data = await _supabase
        .from('user_loyalty')
        .select('user_id')
        .eq('tier_id', diamondTier['id']);

    return data.length;
  }

  Future<int> getTotalPointsIssued() async {
    final data = await _supabase.from('loyalty_points_log').select('points');

    int total = 0;
    for (var row in data) {
      total += (row['points'] as int);
    }
    return total;
  }

  // ===============================
  // 🏆 TIERS
  // ===============================

  Future<List<Map<String, dynamic>>> getTiers() async {
    final data = await _supabase
        .from('loyalty_tiers')
        .select()
        .order('tier_order', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> updateTier({
    required String id,
    required int minPoints,
    required double earnRate,
    required bool freeDelivery,
    required bool prioritySupport,
  }) async {
    await _supabase
        .from('loyalty_tiers')
        .update({
          'min_points': minPoints,
          'earn_rate': earnRate,
          'free_delivery': freeDelivery,
          'priority_support': prioritySupport,
        })
        .eq('id', id);
  }

  // ===============================
  // ⚙️ SETTINGS
  // ===============================

  Future<Map<String, dynamic>?> getSettings() async {
    return await _supabase
        .from('loyalty_settings')
        .select()
        .eq('is_active', true)
        .maybeSingle();
  }

  Future<void> updateSettings({
    required int currencyStep,
    required int basePoints,
    required bool birthdayEnabled,
  }) async {
    await _supabase
        .from('loyalty_settings')
        .update({
          'currency_step': currencyStep,
          'base_points': basePoints,
          'birthday_bonus_enabled': birthdayEnabled,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('is_active', true);
  }

  Future<int> getTotalPointsRedeemed() async {
    // إذا كان هناك خطأ بالصلاحيات أو الاستعلام، دعه يظهر بدلاً من أن يرجع 0 في الصمت
    final res = await _supabase.from('reward_redemptions').select('points_spent');
    
    int total = 0;
    for (var row in res) {
      if (row['points_spent'] != null) {
        total += (row['points_spent'] as num).toInt();
      }
    }

    // إذا كان المجموع 0 (ممكن العمود مضاف حديثاًوكل القيم الماضية بداخله NULL)
    // نرجع للجدول القديم كخطة بديلة حتى لا تكون الشاشة فارغة
    if (total == 0) {
      final fallbackRes = await _supabase
          .from('loyalty_points_log')
          .select('points')
          .lt('points', 0);
      for (var row in fallbackRes) {
        if (row['points'] != null) {
          total += (row['points'] as num).toInt().abs();
        }
      }
    }

    return total;
  }
}
