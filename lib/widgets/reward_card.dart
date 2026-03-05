import 'package:flutter/material.dart';
import '../models/reward_model.dart';
import '../theme/app_colors.dart';
import '../utils/l.dart';

class RewardCard extends StatelessWidget {
  final RewardModel reward;
  final int userPoints;
  final bool isRedeemed;
  final VoidCallback? onRedeem;

  const RewardCard({
    super.key,
    required this.reward,
    required this.userPoints,
    required this.isRedeemed,
    this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final bool canRedeem = userPoints >= reward.pointsRequired && !isRedeemed;

    final bool isArabic = Directionality.of(context) == TextDirection.rtl;

    final String title = reward.displayTitle(isArabic);
    final String? description = reward.displayDescription(isArabic);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canRedeem ? AppColors.primary(context) : Colors.grey.shade700,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + status chip
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text(context),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _StatusChip(isRedeemed: isRedeemed, canRedeem: canRedeem),
            ],
          ),

          if (description != null && description.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textGrey(context),
                  height: 1.2,
                ),
              ),
            ),

          const SizedBox(height: 14),

          // points + action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PointsBadge(points: reward.pointsRequired),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: canRedeem ? onRedeem : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canRedeem
                        ? AppColors.primary(context)
                        : Colors.grey.shade800,
                    foregroundColor: AppColors.textOnPrimary(context),
                    disabledForegroundColor: Colors.white70,
                    disabledBackgroundColor: Colors.grey.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    elevation: 0,
                  ),
                  child: Text(
                    isRedeemed
                        ? L.t('reward_redeemed_status')
                        : canRedeem
                        ? L.t('reward_redeem')
                        : L.t('reward_locked'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),

          // hint line
          if (!isRedeemed && !canRedeem)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '${(reward.pointsRequired - userPoints).clamp(0, 1 << 31)} ${L.t('reward_more_points')}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isRedeemed;
  final bool canRedeem;

  const _StatusChip({required this.isRedeemed, required this.canRedeem});

  @override
  Widget build(BuildContext context) {
    final String text = isRedeemed
        ? L.t('reward_done')
        : canRedeem
        ? L.t('reward_ready')
        : L.t('reward_locked');

    final Color bg = isRedeemed
        ? Colors.green.withValues(alpha: 0.18)
        : canRedeem
        ? AppColors.primary(context).withValues(alpha: 0.18)
        : Colors.grey.withValues(alpha: 0.18);

    final Color fg = isRedeemed
        ? Colors.greenAccent
        : canRedeem
        ? AppColors.primary(context)
        : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  final int points;

  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Text(
        '$points ${L.t('reward_pts')}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.text(context),
        ),
      ),
    );
  }
}
