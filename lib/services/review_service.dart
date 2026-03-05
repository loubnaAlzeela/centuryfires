import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewService {
  final SupabaseClient _client = Supabase.instance.client;

  // =======================
  // Internal user id
  // =======================
  Future<String> _getInternalUserId() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final data = await _client
        .from('users')
        .select('id')
        .eq('auth_id', user.id)
        .single();

    return data['id'] as String;
  }

  // =======================
  // Meals to review (per order)
  // =======================
  Future<List<Map<String, dynamic>>> getMealsToReview() async {
    final userId = await _getInternalUserId();

    final data = await _client
        .from('meals_to_review')
        .select('order_id, meal_id, meal_name_ar, meal_name_en')
        .eq('user_id', userId);

    return (data as List)
        .map(
          (e) => {
            'order_id': e['order_id'].toString(),
            'meal_id': e['meal_id'].toString(),
            'meal_name_ar': e['meal_name_ar'] ?? '',
            'meal_name_en': e['meal_name_en'] ?? '',
          },
        )
        .toList();
  }

  // =======================
  // Submit review (per order)
  // =======================
  Future<void> submitMealReview({
    required String orderId,
    required String mealId,
    required int rating,
    String? comment,
  }) async {
    final userId = await _getInternalUserId();

    final res = await _client.from('reviews').insert({
      'order_id': orderId,
      'meal_id': mealId,
      'user_id': userId,
      'rating': rating,
      'comment': (comment ?? '').trim().isEmpty ? null : comment!.trim(),
    }).select();

    print("INSERT REVIEW RESPONSE: $res");
  }

  Future<List<Map<String, dynamic>>> getMyReviews() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final data = await _client
        .from('my_reviews_with_replies')
        .select()
        .eq('auth_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }
}
