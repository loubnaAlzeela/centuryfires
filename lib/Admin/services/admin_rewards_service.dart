import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRewardsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getRewards() async {
    final data = await _supabase
        .from('rewards')
        .select()
        .order('points_required', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getCoupons() async {
    final res = await _supabase
        .from('promotions')
        .select('id, title_en, title_ar, code')
        .eq('promotion_type', 'coupon');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> updateReward({
    required String id,
    required String titleAr,
    required String titleEn,
    required String descAr,
    required String descEn,
    required int points,
    required bool isActive,
    String? promotionId,
  }) async {
    final payload = <String, dynamic>{
      'title_ar': titleAr,
      'title_en': titleEn,
      'description': descEn,
      'description_ar': descAr,
      'description_en': descEn,
      'points_required': points,
      'is_active': isActive,
    };
    if (promotionId != null && promotionId.isNotEmpty) {
      payload['promotion_id'] = promotionId;
    } else {
      payload['promotion_id'] = null;
    }
    await _supabase.from('rewards').update(payload).eq('id', id);
  }

  Future<void> createReward({
    required String titleAr,
    required String titleEn,
    required String descAr,
    required String descEn,
    required int points,
    required bool isActive,
    String? promotionId,
  }) async {
    final payload = <String, dynamic>{
      'title_ar': titleAr,
      'title_en': titleEn,
      'description': descEn,
      'description_ar': descAr,
      'description_en': descEn,
      'points_required': points,
      'is_active': isActive,
    };
    if (promotionId != null && promotionId.isNotEmpty) {
      payload['promotion_id'] = promotionId;
    }
    await _supabase.from('rewards').insert(payload);
  }

  Future<void> deleteReward(String id) async {
    await _supabase.from('rewards').delete().eq('id', id);
  }
}
