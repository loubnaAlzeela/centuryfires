import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/l.dart';

class CouponService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Apply coupon and return discount amount
  Future<double> applyCoupon({
    required String code,
    required double subtotal,
  }) async {
    final now = DateTime.now().toUtc();

    final promo = await _supabase
        .from('promotions')
        .select()
        .eq('promotion_type', 'coupon')
        .ilike('code', code) // case-insensitive
        .eq('is_active', true)
        .maybeSingle();

    if (promo == null) {
      throw Exception(L.t('invalid_coupon'));
    }

    // 🔎 تحقق من تاريخ البداية
    if (promo['start_at'] != null) {
      final start = DateTime.parse(promo['start_at']);
      if (now.isBefore(start)) {
        throw Exception(L.t('coupon_not_started'));
      }
    }

    // 🔎 تحقق من تاريخ الانتهاء
    if (promo['end_at'] != null) {
      final end = DateTime.parse(promo['end_at']);
      if (now.isAfter(end)) {
        throw Exception(L.t('coupon_expired'));
      }
    }

    // 🔎 تحقق من عدد الاستخدام
    if (promo['usage_limit'] != null &&
        promo['usage_limit'] > 0 &&
        promo['used_count'] >= promo['usage_limit']) {
      throw Exception(L.t('coupon_limit_reached'));
    }

    double discount = 0;

    if (promo['discount_type'] == 'percentage' ||
        promo['discount_type'] == 'percent') {
      final percent = (promo['discount_value'] ?? 0).toDouble();
      discount = subtotal * (percent / 100);
    } else if (promo['discount_type'] == 'fixed') {
      discount = (promo['discount_value'] ?? 0).toDouble();
    }

    // 🔒 تطبيق max_discount إذا موجود
    if (promo['max_discount'] != null) {
      final max = (promo['max_discount'] ?? 0).toDouble();
      if (max > 0 && discount > max) {
        discount = max;
      }
    }

    return discount;
  }
}
