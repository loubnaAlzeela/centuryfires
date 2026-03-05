import '../utils/language_controller.dart';

class LoyaltyTierModel {
  final String name;
  final int minPoints;
  final double earnRate;
  final bool freeDelivery;
  final bool prioritySupport;

  LoyaltyTierModel({
    required this.name,
    required this.minPoints,
    required this.earnRate,
    required this.freeDelivery,
    required this.prioritySupport,
  });

  factory LoyaltyTierModel.fromMap(Map<String, dynamic> map) {
    final String resolvedName =
        (LanguageController.ar ? map['name_ar'] : map['name_en'])?.toString() ??
        'UNKNOWN';

    return LoyaltyTierModel(
      name: resolvedName,
      minPoints: (map['min_points'] as num?)?.toInt() ?? 0,
      earnRate: (map['earn_rate'] as num?)?.toDouble() ?? 1.0,
      freeDelivery: map['free_delivery'] ?? false,
      prioritySupport: map['priority_suppc'] ?? false, // انتبه للاسم بالجدول
    );
  }
}
