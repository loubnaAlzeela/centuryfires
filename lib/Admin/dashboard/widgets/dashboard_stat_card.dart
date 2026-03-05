import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Icon + Value (same row)
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20, // أصغر شوي
              ),

              const SizedBox(width: 10),

              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text(context),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// 🔹 Title below
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textGrey(context), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
