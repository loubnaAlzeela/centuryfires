import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/l.dart';

class LoyaltyTierCard extends StatelessWidget {
  final Map<String, dynamic> tier;
  final VoidCallback? onUpdated;

  const LoyaltyTierCard({super.key, required this.tier, this.onUpdated});

  LinearGradient _getGradient(BuildContext context, String name) {
    switch (name.toLowerCase()) {
      case 'bronze':
        return const LinearGradient(
          colors: [Color(0xFFB45309), Color(0xFF7C2D12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'silver':
        return const LinearGradient(
          colors: [Color(0xFF94A3B8), Color(0xFF475569)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'gold':
        return const LinearGradient(
          colors: [Color(0xFFFACC15), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'diamond':
        return const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [
            AppColors.primary(context),
            AppColors.primary(context).withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic = Directionality.of(context) == TextDirection.rtl;

    final String name = isArabic
        ? (tier['name_ar'] ?? '')
        : (tier['name_en'] ?? '');

    final gradient = _getGradient(context, (tier['name_en'] ?? '').toString());

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          /// Decorative Circle
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Icon + Name
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  "${tier['earn_rate']}x ${L.t('points')}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "${L.t('min_points')}: ${tier['min_points']}",
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 16),

                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.2),
                ),

                const SizedBox(height: 16),

                if (tier['free_delivery'] == true)
                  _benefit(L.t('free_delivery')),

                if (tier['priority_support'] == true)
                  _benefit(L.t('priority_support')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
