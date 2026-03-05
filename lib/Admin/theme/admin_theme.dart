import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AdminTheme {
  static ThemeData theme(BuildContext context) {
    return ThemeData(
      brightness: Theme.of(context).brightness,

      scaffoldBackgroundColor: AppColors.bg(context),
      primaryColor: AppColors.primary(context),

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary(context),
        brightness: Theme.of(context).brightness,
        background: AppColors.bg(context),
        surface: AppColors.card(context),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.text(context)),
        titleTextStyle: TextStyle(
          color: AppColors.text(context),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.card(context),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.text(context),
        ),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.text(context)),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.textGrey(context)),
      ),

      iconTheme: IconThemeData(color: AppColors.text(context)),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary(context),
          foregroundColor: AppColors.textOnPrimary(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
