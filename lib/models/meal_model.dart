class MealModel {
  final String id;
  final String categoryId;

  final String nameAr;
  final String nameEn;

  final String? descriptionAr;
  final String? descriptionEn;

  final String? image;
  final double basePrice;

  final bool isActive;
  final bool isRecommended;
  final bool isPopular;

  MealModel({
    required this.id,
    required this.categoryId,
    required this.nameAr,
    required this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    this.image,
    required this.basePrice,
    required this.isActive,
    required this.isRecommended,
    required this.isPopular,
  });

  factory MealModel.fromMap(Map<String, dynamic> map) {
    return MealModel(
      id: map['id'].toString(),
      categoryId: map['category_id'].toString(),

      // ✅ مصدر واحد فقط
      nameAr: (map['name_ar'] ?? '').toString(),
      nameEn: (map['name_en'] ?? '').toString(),

      descriptionAr: map['description_ar']?.toString(),
      descriptionEn: map['description_en']?.toString(),

      image: map['image_url']?.toString(),
      basePrice: (map['base_price'] as num?)?.toDouble() ?? 0.0,

      isActive: map['is_active'] == true,
      isRecommended: map['is_recommended'] == true,
      isPopular: map['is_popular'] == true,
    );
  }

  // 🔑 نقطة واحدة لكل التطبيق
  String displayName(bool isArabic) {
    return isArabic ? nameAr : nameEn;
  }

  String? displayDescription(bool isArabic) {
    return isArabic ? descriptionAr : descriptionEn;
  }
}
