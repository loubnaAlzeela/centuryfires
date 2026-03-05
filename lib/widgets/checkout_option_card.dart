import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

class CheckoutOptionCard extends StatelessWidget {
  final String title;

  const CheckoutOptionCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppButton(
      type: AppButtonType.card,
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.text(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.circle_outlined, color: AppColors.textGrey(context)),
          ],
        ),
      ),
    );
  }
}
