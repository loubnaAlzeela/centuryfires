import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SectionTitle extends StatelessWidget {
  final String title, subtitle;
  const SectionTitle({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 18)),
          Text(subtitle, style:  TextStyle(color: AppColors.textGrey(context), fontSize: 12)),
        ],
      ),
    );
  }
}
