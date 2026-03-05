import 'package:supabase_flutter/supabase_flutter.dart';

class MealsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMeals({String? categoryId}) async {
    var query = _supabase
        .from('meals')
        .select('''
        id,
        name_en,
        name_ar,
        description_en,
        description_ar,
        base_price,
        image_url,
        category_id
        ''')
        .eq('is_active', true);

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    final data = await query.order(
      'sort_order',
      ascending: true,
      nullsFirst: false,
    );

    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getMealById(String mealId) async {
    final data = await _supabase
        .from('meals')
        .select('''
        id,
        name_en,
        name_ar,
        description_en,
        description_ar,
        base_price,
        image_url,
        category_id
        ''')
        .eq('id', mealId)
        .maybeSingle();

    if (data == null) {
      throw Exception("Meal not found");
    }

    return Map<String, dynamic>.from(data);
  }

  Future<void> updateMeal({
    required String id,
    required String nameEn,
    required String nameAr,
    required String descEn,
    required String descAr,
    required double price,
    String? categoryId,
  }) async {
    final res = await _supabase
        .from('meals')
        .update({
          'name_en': nameEn,
          'name_ar': nameAr,
          'description_en': descEn,
          'description_ar': descAr,
          'base_price': price,
          if (categoryId != null) 'category_id': categoryId,
        })
        .eq('id', id)
        .select()
        .maybeSingle();

    if (res == null) {
      throw Exception("Meal update failed");
    }
  }

  Future<String> insertMeal({
    required String nameEn,
    required String nameAr,
    required String descriptionEn,
    required String descriptionAr,
    required num basePrice,
    String? categoryId,
  }) async {
    final response = await _supabase
        .from('meals')
        .insert({
          'name_en': nameEn,
          'name_ar': nameAr,
          'description_en': descriptionEn,
          'description_ar': descriptionAr,
          'base_price': basePrice,
          'category_id': categoryId,
          'is_active': true,
        })
        .select('id')
        .single();

    return response['id'].toString();
  }

  Future<void> deleteMeal(String mealId) async {
    await _supabase.from('meals').update({'is_active': false}).eq('id', mealId);
  }
}
