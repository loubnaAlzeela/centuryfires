import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.dark);

  static const _key = 'theme_mode';

  /// تحميل الثيم عند تشغيل التطبيق
  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key);

    if (isDark != null) {
      themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  /// تبديل الثيم + حفظه
  static Future<void> toggle(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isDark);
  }
}
