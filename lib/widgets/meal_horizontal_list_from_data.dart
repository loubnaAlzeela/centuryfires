import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import '../services/meal_service.dart';
import '../theme/app_colors.dart';
import '../utils/meal_list_type.dart';
import '../screens/meal_details_screen.dart';
import '../utils/l.dart';
import '../utils/language_controller.dart';
import '../utils/cart_controller.dart';

class MealHorizontalListFromData extends StatelessWidget {
  final MealListType type;

  const MealHorizontalListFromData({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: FutureBuilder<List<MealModel>>(
        future: MealService().getMealsByType(type),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primary(context),
              ),
            );
          }

          if (snapshot.hasError) {
            debugPrint('Meal list error: ${snapshot.error}');
            return Center(
              child: Text(
                L.t('meal_list_error'),
                style: TextStyle(color: AppColors.textGrey(context)),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                L.t('meal_list_empty'),
                style: TextStyle(color: AppColors.textGrey(context)),
              ),
            );
          }

          final meals = snapshot.data!;

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: meals.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final meal = meals[index];

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MealDetailsScreen(meal: meal),
                      ),
                    );
                  },
                  child: Container(
                    width: 160,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  meal.image ?? '',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              // العداد أعلى الصورة في الشاشة الرئيسية والتوصيات
                              Positioned(
                                top: -5,
                                right: -5,
                                child: ListenableBuilder(
                                  listenable: CartController.instance,
                                  builder: (context, _) {
                                    final mealCount = CartController
                                        .instance
                                        .lines
                                        .where(
                                          (l) =>
                                              l.mealId.toString() ==
                                              meal.id.toString(),
                                        )
                                        .fold(0, (sum, l) => sum + l.quantity);

                                    if (mealCount == 0)
                                      return const SizedBox.shrink();

                                    return Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primary(context),
                                          width: 1.5,
                                        ),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 22,
                                        minHeight: 22,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$mealCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          meal.displayName(LanguageController.ar),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.text(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${meal.basePrice} SAR", // ✅ من الداتا
                          style: TextStyle(
                            color: AppColors.primary(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
