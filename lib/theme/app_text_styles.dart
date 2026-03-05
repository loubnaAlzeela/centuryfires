import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // ====== Titles ======

  static const TextStyle screenTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ====== Body text ======

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: Colors.white,
  );

  static TextStyle bodyGrey(BuildContext context) {
  return TextStyle(
    fontSize: 14,
    color: AppColors.textGrey(context),
  );
}


  // ====== Profile / Menu items ======

  static const TextStyle listTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static TextStyle listSubtitle(BuildContext context) {
  return TextStyle(
    fontSize: 13,
    color: AppColors.textGrey(context),
  );
}

  // ====== Loyalty card ======

  static const TextStyle loyaltyLabel = TextStyle(
    fontSize: 13,
    color: Colors.black54,
  );

  static const TextStyle loyaltyValue = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle loyaltyTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  // ====== Buttons ======

  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static const TextStyle buttonDanger = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.redAccent,
  );
}
