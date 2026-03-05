import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/meal_model.dart';
import '../utils/meal_list_type.dart';

class MealService {
  final SupabaseClient _client = Supabase.instance.client;

  // =========================
  // Home (Recommended / Popular)
  // =========================
  Future<List<MealModel>> getMealsByType(MealListType type) async {
    var query = _client.from('meals').select().eq('is_active', true);

    if (type == MealListType.recommended) {
      query = query.eq('is_recommended', true);
    } else if (type == MealListType.popular) {
      query = query.eq('is_popular', true);
    }

    final data = await query.order('sort_order');

    return (data as List)
        .map((e) => MealModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // =========================
  // All meals (Menu - All tab)
  // =========================
  Future<List<MealModel>> getAllMeals() async {
    final data = await _client
        .from('meals')
        .select()
        .eq('is_active', true)
        .order('sort_order');

    return (data as List)
        .map((e) => MealModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // =========================
  // Meals by category (Menu tabs)
  // =========================
  Future<List<MealModel>> getMealsByCategory(String? categoryId) async {
    var query = _client.from('meals').select().eq('is_active', true);

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    final data = await query.order('sort_order');

    return (data as List)
        .map((e) => MealModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // =========================
  // Meal by ID (Re-Order)
  // =========================
  Future<MealModel> getMealById(String mealId) async {
    final data = await _client
        .from('meals')
        .select()
        .eq('id', mealId)
        .maybeSingle();

    if (data == null) {
      throw Exception('Meal not found');
    }

    return MealModel.fromMap(Map<String, dynamic>.from(data));
  }
}
