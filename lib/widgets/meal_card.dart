import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/l.dart';
import '../utils/language_controller.dart';
import '../models/meal_model.dart';

class MealHorizontalList extends StatelessWidget {
  final List<MealModel> meals;

  const MealHorizontalList({super.key, required this.meals});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ValueListenableBuilder<bool>(
        valueListenable: LanguageController.isArabic,
        builder: (context, isArabic, _) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];

              return _MealCard(
                title: meal.displayName(isArabic),
                price: '${meal.basePrice.toStringAsFixed(2)} ${L.t('currency')}',
                image: meal.image ?? '',
                isBestSeller: meal.isPopular == true,
              );
            },
          );
        },
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final String title;
  final String price;
  final String image;
  final bool isBestSeller;

  const _MealCard({
    required this.title,
    required this.price,
    required this.image,
    required this.isBestSeller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 160,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Material(
          color: AppColors.card(context),
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= IMAGE + BADGE =================
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: image.startsWith('http')
                        ? Image.network(
                            image,
                            height: 110,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 110,
                              color: AppColors.card(context),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.image_not_supported,
                                color: AppColors.textGrey(context),
                              ),
                            ),
                          )
                        : Image.asset(
                            image,
                            height: 110,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),

                  // ⭐ BEST SELLER BADGE
                  if (isBestSeller)
                    Positioned(
                      top: 8,
                      left: 8, // 👈 خليتها يسار حتى ما تتغطى
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          L.t('best_seller'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // ================= TEXT =================
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      price,
                      style: TextStyle(
                        color: AppColors.primary(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
