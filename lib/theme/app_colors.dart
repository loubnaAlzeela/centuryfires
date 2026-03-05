import 'package:flutter/material.dart';

class AppColors {
  // خلفية الشاشة
  static Color bg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0E0E0E)
        : const Color(0xFFFFFFFF);
  }

  // كروت / Containers
  static Color card(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFF2F2F2);
  }

  // اللون الأساسي (براند)
  static Color primary(BuildContext context) {
    return const Color(0xFFFFC107);
  }

  // نص أساسي (العناوين)
  static Color text(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black; // 👈 هون المهم
  }

  // نص ثانوي / رمادي
  static Color textGrey(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9E9E9E)
        : const Color(0xFF616161);
  }

  // نص خفيف جدًا (labels / hints)
  static Color textHint(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF777777)
        : const Color(0xFF9E9E9E);
  }

  static Color textOnPrimary(BuildContext context) {
    // لون النص فوق اللون الأساسي (الأصفر)
    return Colors.black;
  }

  static Color error(BuildContext context) {
    return const Color(0xFFE53935); // Red
  }
}
