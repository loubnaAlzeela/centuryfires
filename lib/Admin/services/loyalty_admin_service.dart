import 'package:supabase_flutter/supabase_flutter.dart';

class LoyaltyAdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===============================
  // 📊 STATS
  // ===============================

  Future<int> getTotalMembers() async {
    final data = await _supabase.from('user_loyalty').select('user_id');
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
    final data = await _supabase
        .from('loyalty_points_log')
        .select('points')
        .lt('points', 0);

    int total = 0;
    for (var row in data) {
      total += (row['points'] as int).abs();
    }

    return total;
  }
}
