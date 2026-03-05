import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import '../services/meal_service.dart';
import '../theme/app_colors.dart';
import '../utils/meal_list_type.dart';
import '../screens/meal_details_screen.dart';
import '../utils/l.dart';
import '../utils/language_controller.dart';

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
            // 🔧 للمطور فقط
            debugPrint('Meal list error: ${snapshot.error}');

            // 👤 للمستخدم
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              meal.image ?? '',
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
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
                          "${meal.basePrice} AED", // ✅ من الداتا
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
