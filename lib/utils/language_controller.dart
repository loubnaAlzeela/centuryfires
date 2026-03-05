import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController {
  // 🔹 المصدر الوحيد للحقيقة
  static final ValueNotifier<bool> isArabic = ValueNotifier<bool>(false);

  // 🔹 تحميل اللغة عند تشغيل التطبيق
  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('lang_ar') ?? false;
    isArabic.value = saved;
  }

  // 🔹 تغيير اللغة + حفظها
  static Future<void> setArabic(bool value) async {
    if (isArabic.value == value) return; // ⛔ لا تعيد نفس القيمة

    isArabic.value = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lang_ar', value);
  }

  // 🔹 اختصار مفيد
  static bool get ar => isArabic.value;
}
