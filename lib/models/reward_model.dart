class RewardModel {
  final String id;

  final String titleAr;
  final String titleEn;

  final String? descriptionAr;
  final String? descriptionEn;

  final int pointsRequired;
  final bool isActive;
  final DateTime createdAt;
  final String? promotionId;

  RewardModel({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    required this.pointsRequired,
    required this.isActive,
    required this.createdAt,
    this.promotionId,
  });

  /// 🔹 من Supabase → Dart (AR / EN)
  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'] as String,

      titleAr: (json['title_ar'] ?? '').toString(),
      titleEn: (json['title_en'] ?? '').toString(),

      descriptionAr: json['description_ar']?.toString(),
      descriptionEn: json['description_en']?.toString(),

      pointsRequired: (json['points_required'] as num).toInt(),
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      promotionId: json['promotion_id']?.toString(),
    );
  }

  /// 🔹 اختيار العنوان حسب اللغة
  String displayTitle(bool isArabic) {
    return isArabic ? titleAr : titleEn;
  }

  /// 🔹 اختيار الوصف حسب اللغة
  String? displayDescription(bool isArabic) {
    return isArabic ? descriptionAr : descriptionEn;
  }

  /// 🔹 List Helper
  static List<RewardModel> fromList(List<dynamic> list) {
    return list.map((item) => RewardModel.fromJson(item)).toList();
  }
}
