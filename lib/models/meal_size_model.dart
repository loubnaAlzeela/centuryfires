class MealSizeModel {
  final String id;
  final String mealId;
  final String name; // fallback
  final String? nameAr;
  final String? nameEn;
  final num price;
  final bool isDefault;
  final bool isActive;

  MealSizeModel({
    required this.id,
    required this.mealId,
    required this.name,
    this.nameAr,
    this.nameEn,
    required this.price,
    required this.isDefault,
    required this.isActive,
  });

  factory MealSizeModel.fromMap(Map<String, dynamic> map) {
    return MealSizeModel(
      id: map['id'].toString(),
      mealId: map['meal_id'].toString(),
      name: (map['size_name'] ?? '').toString(),
      nameAr: map['size_name_ar']?.toString(),
      nameEn: map['size_name_en']?.toString(),
      price: map['price'] ?? 0,
      isDefault: (map['is_default'] ?? false) == true,
      isActive: (map['is_active'] ?? true) == true,
    );
  }

  String displayName(bool isArabic) {
    if (isArabic && nameAr != null && nameAr!.isNotEmpty) {
      return nameAr!;
    }
    if (!isArabic && nameEn != null && nameEn!.isNotEmpty) {
      return nameEn!;
    }
    return name; // fallback
  }
}
