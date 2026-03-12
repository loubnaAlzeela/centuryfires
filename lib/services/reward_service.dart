import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reward_model.dart';

class RewardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /* bool get _isArabic =>
      _supabase.auth.currentSession?.user.userMetadata?['lang'] == 'ar';*/

  /// 🔹 جلب كل المكافآت الفعالة (AR / EN)
  Future<List<RewardModel>> getRewards() async {
    final res = await _supabase
        .from('rewards')
        .select('''
        id,
        points_required,
        is_active,
        title_ar,
        title_en,
        description_ar,
        description_en,
        created_at,
        promotion_id
      ''')
        .eq('is_active', true)
        .order('points_required', ascending: true);

    return RewardModel.fromList(res);
  }

  /// 🔹 جلب user_id الداخلي (users.id)
  Future<String> _getInternalUserId() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) {
      throw Exception('User not authenticated');
    }

    final userData = await _supabase
        .from('users')
        .select('id')
        .eq('auth_id', authUser.id)
        .single();

    return userData['id'];
  }

  /// 🔹 جلب المكافآت المصروفة للمستخدم الحالي
  Future<List<String>> getRedeemedRewardIds() async {
    final userId = await _getInternalUserId();

    final res = await _supabase
        .from('reward_redemptions')
        .select('reward_id')
        .eq('user_id', userId);

    return res.map<String>((e) => e['reward_id'] as String).toList();
  }

  /// 🔹 التحقق إذا المكافأة مصروفة
  Future<bool> isRewardRedeemed(String rewardId) async {
    final userId = await _getInternalUserId();

    final res = await _supabase
        .from('reward_redemptions')
        .select('id')
        .eq('user_id', userId)
        .eq('reward_id', rewardId)
        .maybeSingle();

    return res != null;
  }

  /// 🔹 صرف المكافأة (RPC — آمن)
  Future<void> redeemReward(String rewardId) async {
    await _supabase.rpc('redeem_reward_v2', params: {'p_reward_id': rewardId});
  }

  /// 🔹 جلب كود الكوبون المرتبط بالمكافأة
  Future<String?> getCouponCodeForReward(String promotionId) async {
    try {
      final promo = await _supabase
          .from('promotions')
          .select('code')
          .eq('id', promotionId)
          .maybeSingle();

      if (promo != null && promo['code'] != null) {
        return promo['code'] as String;
      }
    } catch (e) {
      // ignore
    }
    return null;
  }
}
