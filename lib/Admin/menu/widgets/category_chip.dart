import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary(context)
                  : AppColors.card(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.primary(context)
                    : AppColors.textGrey(context),
              ),
            ),
            child: Text(
              label,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: selected ? Colors.black : AppColors.textGrey(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
