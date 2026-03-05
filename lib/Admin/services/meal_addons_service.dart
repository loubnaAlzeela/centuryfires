import 'package:supabase_flutter/supabase_flutter.dart';

class MealAddonsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ================= GET ADDONS WITH LINK STATE =================
  Future<List<Map<String, dynamic>>> getAddons({
    required String mealId,
    required String type,
    bool includeInactive = false,
  }) async {
    final List<dynamic> addonsRaw;

    if (includeInactive) {
      addonsRaw = await _supabase
          .from('addons')
          .select()
          .eq('type', type)
          .order('sort_order', ascending: true);
    } else {
      addonsRaw = await _supabase
          .from('addons')
          .select()
          .eq('type', type)
          .eq('is_active', true)
          .order('sort_order', ascending: true);
    }

    final linkedRaw = await _supabase
        .from('meal_addons')
        .select('addon_id')
        .eq('meal_id', mealId);

    final linkedIds = List<Map<String, dynamic>>.from(
      linkedRaw,
    ).map((e) => e['addon_id']).toSet();

    final addons = List<Map<String, dynamic>>.from(addonsRaw);

    return addons
        .map((addon) => {...addon, 'linked': linkedIds.contains(addon['id'])})
        .toList();
  }

  // ================= CREATE ADDON =================
  Future<String> createAddon({
    required String nameEn,
    required String nameAr,
    required double price,
    required String type,
  }) async {
    try {
      final res = await _supabase
          .from('addons')
          .insert({
            'addon_name_en': nameEn,
            'addon_name_ar': nameAr,
            'price': price,
            'type': type,
            'is_active': true,
          })
          .select('id')
          .single();

      return res['id'].toString();
    } catch (e) {
      throw Exception('Failed to create addon: $e');
    }
  }

  // ================= CREATE + ATTACH =================
  Future<void> createAndAttach({
    required String mealId,
    required String nameEn,
    required String nameAr,
    required double price,
    required String type,
  }) async {
    final addonId = await createAddon(
      nameEn: nameEn,
      nameAr: nameAr,
      price: price,
      type: type,
    );

    await attach(mealId: mealId, addonId: addonId);
  }

  // ================= UPDATE ADDON =================
  Future<void> updateAddon({
    required String addonId,
    required String nameEn,
    required String nameAr,
    required double price,
  }) async {
    try {
      await _supabase
          .from('addons')
          .update({
            'addon_name_en': nameEn,
            'addon_name_ar': nameAr,
            'price': price,
          })
          .eq('id', addonId);
    } catch (e) {
      throw Exception('Failed to update addon: $e');
    }
  }

  // ================= SOFT DELETE ADDON =================
  Future<void> deleteAddon(String id) async {
    try {
      await _supabase
          .from('addons')
          .update({'is_active': false}) // 👈 بدل الحذف الفعلي
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to disable addon: $e');
    }
  }

  //=================Restore addon ========================
  Future<void> restoreAddon(String id) async {
    await _supabase.from('addons').update({'is_active': true}).eq('id', id);
  }

  // ================= ATTACH =================
  Future<void> attach({required String mealId, required String addonId}) async {
    try {
      await _supabase.from('meal_addons').insert({
        'meal_id': mealId,
        'addon_id': addonId,
      });
    } catch (e) {
      throw Exception('Failed to attach addon: $e');
    }
  }

  // ================= DETACH =================
  Future<void> detach(String mealId, String addonId) async {
    try {
      await _supabase
          .from('meal_addons')
          .delete()
          .eq('meal_id', mealId)
          .eq('addon_id', addonId);
    } catch (e) {
      throw Exception('Failed to detach addon: $e');
    }
  }
}
