class CategoryModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.imageUrl,
    required this.sortOrder,
    required this.isActive,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      imageUrl: json['image_url'] as String?,
      sortOrder: (json['sort_order'] ?? 0) as int,
      isActive: (json['is_active'] ?? true) as bool,
    );
  }

  String displayName(bool isArabic) {
    return isArabic ? nameAr : nameEn;
  }
}
