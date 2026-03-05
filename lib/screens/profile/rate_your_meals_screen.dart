import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/review_service.dart';
import '../../utils/l.dart';
import '../../utils/language_controller.dart';

class RateYourMealsScreen extends StatefulWidget {
  const RateYourMealsScreen({super.key});

  @override
  State<RateYourMealsScreen> createState() => _RateYourMealsScreenState();
}

class _RateYourMealsScreenState extends State<RateYourMealsScreen> {
  final reviewService = ReviewService();

  bool loading = true;

  List<Map<String, dynamic>> mealsToRate = [];
  List<Map<String, dynamic>> myReviews = [];

  final Map<String, int> ratings = {};
  final Map<String, TextEditingController> comments = {};

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  @override
  void dispose() {
    for (final c in comments.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> loadAll() async {
    try {
      final toRate = await reviewService.getMealsToReview();
      final reviews = await reviewService.getMyReviews();

      if (!mounted) return;

      setState(() {
        mealsToRate = toRate;
        myReviews = reviews;
        loading = false;
      });
    } catch (e) {
      debugPrint('Load error: $e');
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> submitMeal(Map<String, dynamic> meal) async {
    final key = '${meal['order_id']}_${meal['meal_id']}';
    final rating = ratings[key] ?? 0;
    if (rating == 0) return;

    try {
      await reviewService.submitMealReview(
        orderId: meal['order_id'].toString(),
        mealId: meal['meal_id'].toString(),
        rating: rating,
        comment: comments[key]?.text,
      );

      if (!mounted) return;

      setState(() {
        mealsToRate.remove(meal);
        ratings.remove(key);
        comments.remove(key)?.dispose();
      });

      await loadAll();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(L.t('thanks_feedback'))));
    } catch (e) {
      debugPrint('Submit error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(L.t('rate_meals'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =================== SECTION 1 ===================
          if (mealsToRate.isNotEmpty)
            Text(
              "Pending Reviews",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.text(context),
              ),
            ),

          ...mealsToRate.map((meal) {
            final key = '${meal['order_id']}_${meal['meal_id']}';
            comments.putIfAbsent(key, () => TextEditingController());
            return _mealCard(meal, key);
          }),

          const SizedBox(height: 30),

          // =================== SECTION 2 ===================
          if (myReviews.isNotEmpty)
            Text(
              "Your Reviews",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.text(context),
              ),
            ),

          ...myReviews.map((review) => _reviewCard(review)),
        ],
      ),
    );
  }

  Widget _mealCard(Map<String, dynamic> meal, String key) {
    final currentRating = ratings[key] ?? 0;

    final mealName = LanguageController.isArabic.value
        ? meal['meal_name_ar']
        : meal['meal_name_en'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mealName ?? '',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.star,
                  color: star <= currentRating
                      ? Colors.amber
                      : Colors.grey.withValues(alpha: 0.4),
                ),
                onPressed: () {
                  setState(() => ratings[key] = star);
                },
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: comments[key],
            maxLines: 2,
            decoration: InputDecoration(
              hintText: L.t('optional_comment'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: currentRating == 0 ? null : () => submitMeal(meal),
              child: Text(L.t('submit')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    final mealName = LanguageController.isArabic.value
        ? review['name_ar']
        : review['name_en'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mealName ?? '',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              review['rating'] ?? 0,
              (i) =>
                  Icon(Icons.star, size: 18, color: AppColors.primary(context)),
            ),
          ),
          if ((review['comment'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(review['comment']),
            ),
          if ((review['admin_reply'] ?? '').toString().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bg(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(review['admin_reply']),
            ),
        ],
      ),
    );
  }
}
