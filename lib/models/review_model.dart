class ReviewModel {
  final int rating;
  final String? comment;
  final DateTime createdAt;

  final String mealNameAr;
  final String mealNameEn;

  ReviewModel({
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.mealNameAr,
    required this.mealNameEn,
  });

  String displayName(bool isArabic) {
    return isArabic ? mealNameAr : mealNameEn;
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      rating: map['rating'] as int,
      comment: map['comment'],
      createdAt: DateTime.parse(map['created_at']),
      mealNameAr: map['meal_name_ar'] ?? '',
      mealNameEn: map['meal_name_en'] ?? '',
    );
  }
}
