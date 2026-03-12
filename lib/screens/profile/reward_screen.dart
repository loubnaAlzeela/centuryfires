import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/reward_service.dart';
import '../../models/reward_model.dart';
import '../../widgets/reward_progress_card.dart';
import '../../widgets/reward_card.dart';
import '../../theme/app_colors.dart';
import '../../utils/l.dart';
import '../../utils/language_controller.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  final supabase = Supabase.instance.client;
  final RewardService _rewardService = RewardService();

  bool _loading = true;

  int _points = 0;
  String _tierName = 'BRONZE';
  int _nextTierPoints = 250;
  String _nextTierName = 'SILVER';

  List<RewardModel> _rewards = [];
  List<String> _redeemedIds = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final userData = await supabase
          .from('users')
          .select('id')
          .eq('auth_id', authUser.id)
          .single();

      final userId = userData['id'];

      // ✅ FIXED JOIN
      final loyaltyData = await supabase
          .from('user_loyalty')
          .select('points, loyalty_tiers(name_ar, name_en, min_points)')
          .eq('user_id', userId)
          .maybeSingle();

      int points = 0;
      String tierName = 'BRONZE';
      int nextTierPoints = 250;
      String nextTierName = 'SILVER';

      if (loyaltyData != null) {
        points = (loyaltyData['points'] as num?)?.toInt() ?? 0;

        final tier = loyaltyData['loyalty_tiers'];

        if (tier != null) {
          final currentTierMin = (tier['min_points'] as num?)?.toInt() ?? 0;

          tierName =
              (LanguageController.ar ? tier['name_ar'] : tier['name_en'])
                  ?.toString()
                  .toUpperCase() ??
              'UNKNOWN';

          // ✅ FIXED NEXT TIER
          final nextTier = await supabase
              .from('loyalty_tiers')
              .select('name_ar, name_en, min_points')
              .gt('min_points', currentTierMin)
              .order('min_points', ascending: true)
              .limit(1)
              .maybeSingle();

          if (nextTier != null) {
            nextTierName =
                (LanguageController.ar
                        ? nextTier['name_ar']
                        : nextTier['name_en'])
                    ?.toString()
                    .toUpperCase() ??
                tierName;

            nextTierPoints =
                (nextTier['min_points'] as num?)?.toInt() ?? currentTierMin;
          } else {
            // أعلى فئة
            nextTierName = tierName;
            nextTierPoints = currentTierMin;
          }
        }
      }

      final rewards = await _rewardService.getRewards();
      final redeemed = await _rewardService.getRedeemedRewardIds();

      if (!mounted) return;

      setState(() {
        _points = points;
        _tierName = tierName;
        _nextTierPoints = nextTierPoints;
        _nextTierName = nextTierName;
        _rewards = rewards;
        _redeemedIds = redeemed;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError();
    }
  }

  Future<void> _redeemReward(RewardModel reward) async {
    try {
      await _rewardService.redeemReward(reward.id);
      await _loadData();

      if (!mounted) return;

      // إذا المكافأة مرتبطة بكوبون، نعرض الكود للمستخدم
      if (reward.promotionId != null && reward.promotionId!.isNotEmpty) {
        final couponCode = await _rewardService.getCouponCodeForReward(reward.promotionId!);
        if (couponCode != null && mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.card(context),
              title: Row(
                children: [
                  Icon(Icons.card_giftcard, color: AppColors.primary(context)),
                  const SizedBox(width: 8),
                  Text(L.t('reward_redeemed'), style: TextStyle(color: AppColors.text(context), fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    L.t('coupon_code_info'),
                    style: TextStyle(color: AppColors.textGrey(context), fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary(context).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary(context)),
                    ),
                    child: SelectableText(
                      couponCode,
                      style: TextStyle(
                        color: AppColors.primary(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(L.t('ok'), style: TextStyle(color: AppColors.primary(context))),
                ),
              ],
            ),
          );
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L.t('reward_redeemed'))),
      );
    } catch (_) {
      _showError();
    }
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(L.t('err_general'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(L.t('rewards')), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  RewardProgressCard(
                    currentPoints: _points,
                    currentTier: _tierName,
                    nextTierPoints: _nextTierPoints,
                    nextTier: _nextTierName,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    L.t('available_rewards'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._rewards.map((reward) {
                    final isRedeemed = _redeemedIds.contains(reward.id);

                    return RewardCard(
                      reward: reward,
                      userPoints: _points,
                      isRedeemed: isRedeemed,
                      onRedeem: () => _redeemReward(reward),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
