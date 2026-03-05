import 'package:flutter/material.dart';
import '../utils/l.dart';

class LoyaltyCard extends StatelessWidget {
  final String tier;
  final int points;
  final int orders;

  final int currentTierMinPoints;
  final int nextTierPoints;
  final String nextTierName;

  final Gradient gradient;

  const LoyaltyCard({
    super.key,
    required this.tier,
    required this.points,
    required this.orders,
    required this.currentTierMinPoints,
    required this.nextTierPoints,
    required this.nextTierName,
    required this.gradient,
  });

  // ================= PROGRESS =================

  double _calculateProgress() {
    if (nextTierPoints <= currentTierMinPoints) {
      return 1.0;
    }

    final earned = (points - currentTierMinPoints).clamp(0, 999999);
    final required = (nextTierPoints - currentTierMinPoints).clamp(1, 999999);

    return (earned / required).clamp(0.0, 1.0);
  }

  int _progressPercent(double progress) =>
      (progress * 100).clamp(0, 100).round();

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final bool isMaxTier = nextTierPoints <= currentTierMinPoints;

    final double progress = _calculateProgress();
    final int percent = _progressPercent(progress);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Header =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    L.t('loyalty_status'),
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$tier ${L.t('member')}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.card_giftcard, color: Colors.black, size: 26),
            ],
          ),

          const SizedBox(height: 20),

          // ===== Stats =====
          Row(
            children: [
              _statBox(points.toString(), L.t('points')),
              const SizedBox(width: 12),
              _statBox(orders.toString(), L.t('orders')),
            ],
          ),

          const SizedBox(height: 18),

          // ===== Progress =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isMaxTier
                    ? L.t('loyalty_completed')
                    : '${L.t('progress_to')} $nextTierName',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                isMaxTier ? '100%' : '$percent%',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.black.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // ================= STAT BOX =================

  Widget _statBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
