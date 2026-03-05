import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminReviewService {
  final SupabaseClient _client = Supabase.instance.client;

  // ============================
  // Fetch all reviews
  // ============================
  Future<List<Map<String, dynamic>>> fetchAllReviews() async {
    try {
      final data = await _client
          .from('meals_with_reviews')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('fetchAllReviews error: $e');
      return [];
    }
  }

  // ============================
  // Filter locally (rating <= 2)
  // ============================
  List<Map<String, dynamic>> filterNeedsAttention(
    List<Map<String, dynamic>> reviews,
  ) {
    return reviews
        .where(
          (r) => (r['rating'] as num?) != null && (r['rating'] as num) <= 2,
        )
        .toList();
  }

  // ============================
  // Calculate statistics locally
  // ============================
  Map<String, dynamic> calculateStats(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) {
      return {
        'avgFood': null,
        'avgDriver': null, // TODO: implement driver rating
        'positive': 0,
        'needsAttention': 0,
      };
    }

    double total = 0;
    int positive = 0;
    int needsAttention = 0;

    for (final r in reviews) {
      final rating = (r['rating'] as num?)?.toDouble() ?? 0.0;

      total += rating;

      if (rating >= 4) positive++;
      if (rating <= 2) needsAttention++;
    }

    return {
      'avgFood': (total / reviews.length).toStringAsFixed(1),
      'avgDriver': null, // TODO: implement driver rating
      'positive': positive,
      'needsAttention': needsAttention,
    };
  }

  // ============================
  // Reply to review
  // ============================
  Future<bool> replyToReview({
    required String reviewId,
    required String reply,
  }) async {
    try {
      await _client
          .from('reviews')
          .update({
            'admin_reply': reply,
            'admin_replied_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reviewId);

      return true;
    } catch (e) {
      debugPrint('replyToReview error: $e');
      return false;
    }
  }
}
