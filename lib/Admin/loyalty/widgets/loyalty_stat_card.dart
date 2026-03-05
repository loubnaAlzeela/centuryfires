import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class LoyaltyStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? accentColor;

  const LoyaltyStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor,
  });

  static final Map<IconData, Color> _defaultColors = {
    Icons.group: Color(0xFFFACC15),
    Icons.diamond: Color(0xFF38BDF8),
    Icons.star: Color(0xFFF59E0B),
    Icons.card_giftcard: Color(0xFF22C55E),
  };

  @override
  Widget build(BuildContext context) {
    final accent =
        accentColor ?? _defaultColors[icon] ?? AppColors.primary(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Icon + Value Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 18),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 22, // أصغر وأكثر مرونة
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// 🔹 Title
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: AppColors.textGrey(context)),
          ),
        ],
      ),
    );
  }
}
