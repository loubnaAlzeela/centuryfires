class AddonModel {
  final String id;

  final String name; // fallback عام
  final String? nameAr;
  final String? nameEn;

  final num price;
  final bool isActive;

  final String type; // 🔥 extra / removal

  AddonModel({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    required this.price,
    required this.isActive,
    required this.type,
  });

  factory AddonModel.fromMap(Map<String, dynamic> map) {
    return AddonModel(
      id: map['id']?.toString() ?? '',

      // fallback لو ما في عمود name
      name: (map['name'] ?? map['addon_name_en'] ?? map['addon_name_ar'] ?? '')
          .toString(),

      nameAr: map['addon_name_ar']?.toString(),
      nameEn: map['addon_name_en']?.toString(),

      price: (map['price'] as num?) ?? 0,

      isActive: map['is_active'] == null ? true : map['is_active'] == true,

      // 🔥 مهم جداً
      type: (map['type'] ?? 'extra').toString(),
    );
  }

  /// اختيار الاسم حسب اللغة
  String displayName(bool isArabic) {
    if (isArabic) {
      if (nameAr != null && nameAr!.isNotEmpty) return nameAr!;
      if (nameEn != null && nameEn!.isNotEmpty) return nameEn!;
    } else {
      if (nameEn != null && nameEn!.isNotEmpty) return nameEn!;
      if (nameAr != null && nameAr!.isNotEmpty) return nameAr!;
    }

    return name;
  }

  /// Helper سريع
  bool get isExtra => type == 'extra';
  bool get isRemoval => type == 'removal';
}
