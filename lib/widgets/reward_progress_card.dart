import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/l.dart';

class RewardProgressCard extends StatelessWidget {
  final int currentPoints;
  final int nextTierPoints;
  final String currentTier;
  final String nextTier;

  const RewardProgressCard({
    super.key,
    required this.currentPoints,
    required this.nextTierPoints,
    required this.currentTier,
    required this.nextTier,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (currentPoints / nextTierPoints).clamp(0.0, 1.0);

    final int remainingPoints = nextTierPoints - currentPoints;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _tierGradient(context, currentTier),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Tier
          Text(
            '$currentTier ${L.t('reward_tier')}',
            style: TextStyle(
              color: AppColors.textOnPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          // 🔹 Points
          Text(
            '$currentPoints ${L.t('reward_pts')}',
            style: TextStyle(
              color: AppColors.textOnPrimary(context),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // 🔹 Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.textOnPrimary(
                context,
              ).withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.textOnPrimary(context),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 🔹 Hint
          Text(
            remainingPoints > 0
                ? '$remainingPoints ${L.t('reward_points_away')} $nextTier'
                : '${L.t('reward_reached')} $nextTier 🎉',
            style: TextStyle(
              color: AppColors.textOnPrimary(context).withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Gradient حسب الـ Tier (مبني على AppColors)
  LinearGradient _tierGradient(BuildContext context, String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return const LinearGradient(
          colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
        );
      case 'silver':
        return const LinearGradient(
          colors: [Color(0xFFB0BEC5), Color(0xFF78909C)],
        );
      case 'gold':
        return const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
        );
      case 'diamond':
        return const LinearGradient(
          colors: [Color(0xFF7E57C2), Color(0xFF4527A0)],
        );
      default:
        // fallback على لون البراند
        return LinearGradient(
          colors: [
            AppColors.primary(context),
            AppColors.primary(context).withValues(alpha: 0.85),
          ],
        );
    }
  }
}
