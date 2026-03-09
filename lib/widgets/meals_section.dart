import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/meal_model.dart';
import '../services/meal_service.dart';
import '../screens/meal_details_screen.dart';
import '../utils/l.dart';
import '../utils/language_controller.dart';
import '../utils/cart_controller.dart';

class MealsSection extends StatelessWidget {
  final String title;
  final dynamic categoryId;

  const MealsSection({
    super.key,
    required this.title,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MealModel>>(
      future: categoryId == null
          ? MealService().getAllMeals()
          : MealService().getMealsByCategory(categoryId),
      builder: (context, snapshot) {
        // ================= LOADING (SKELETON) =================
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            itemCount: 5,
            itemBuilder: (_, __) => const _MealSkeletonCard(),
          );
        }

        // ================= ERROR (SAFE UX) =================
        if (snapshot.hasError) {
          debugPrint('MealsSection error: ${snapshot.error}');

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                L.t('meals_section_error'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textGrey(context),
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        // ================= EMPTY =================
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              L.t('meals_section_empty'),
              style: TextStyle(color: AppColors.textGrey(context)),
            ),
          );
        }

        final meals = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: meals.length + 1,
          itemBuilder: (context, index) {
            // ===== Section Header =====
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title, // 🔒 من الداتا / الهوم – لا ترجمة
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${meals.length} ${L.t('items')}',
                      style: TextStyle(color: AppColors.textGrey(context)),
                    ),
                  ],
                ),
              );
            }

            final meal = meals[index - 1];

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MealDetailsScreen(meal: meal),
                    ),
                  );
                },
                child: _AnimatedMealCard(meal: meal),
              ),
            );
          },
        );
      },
    );
  }
}

// =======================================================
// Animated Meal Card (Fade + Slide + Hero)
// =======================================================

class _AnimatedMealCard extends StatefulWidget {
  final MealModel meal;
  const _AnimatedMealCard({required this.meal});

  @override
  State<_AnimatedMealCard> createState() => _AnimatedMealCardState();
}

class _AnimatedMealCardState extends State<_AnimatedMealCard> {
  bool visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) setState(() => visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;

    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= IMAGE =================
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    child: Hero(
                      tag: 'meal_${meal.id}',
                      child: Image.network(
                        meal.image ?? '',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: AppColors.card(context),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported,
                            color: AppColors.textGrey(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // عداد الكمية أعلى الصورة
                  Positioned(
                    top: 10,
                    right: 10,
                    child: ListenableBuilder(
                      listenable: CartController.instance,
                      builder: (context, _) {
                        final mealCount = CartController.instance.lines
                            .where(
                              (l) => l.mealId.toString() == meal.id.toString(),
                            )
                            .fold(0, (sum, l) => sum + l.quantity);

                        if (mealCount == 0) return const SizedBox.shrink();

                        return Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary(context),
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 26,
                            minHeight: 26,
                          ),
                          child: Center(
                            child: Text(
                              '$mealCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
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

              // ================= CONTENT =================
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${meal.basePrice} SAR',
                            style: TextStyle(
                              color: AppColors.primary(context),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            meal.displayName(LanguageController.ar),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.text(context),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListenableBuilder(
                      listenable: CartController.instance,
                      builder: (context, _) {
                        final mealCount = CartController.instance.lines
                            .where(
                              (l) => l.mealId.toString() == meal.id.toString(),
                            )
                            .fold(0, (sum, l) => sum + l.quantity);
                        final bool isInCart = mealCount > 0;

                        return GestureDetector(
                          onTap: () {
                            // إضافة الوجبة للسلة
                            CartController.instance.addLine(
                              mealId: meal.id,
                              name: meal.displayName(LanguageController.ar),
                              price: meal.basePrice,
                              imageUrl: meal.image,
                              addonIds: [],
                              addonNames: [],
                            );

                            // تنبيه إضافة ناجحة
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${meal.displayName(LanguageController.ar)} ${LanguageController.ar ? 'أضيفت للسلة' : 'added to cart'}',
                                  style: const TextStyle(fontFamily: 'Cairo'),
                                ),
                                backgroundColor: AppColors.primary(context),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary(context),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isInCart
                                      ? Icons.shopping_cart_checkout
                                      : Icons.add,
                                  color: AppColors.text(context),
                                ),
                              ),
                              if (isInCart)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$mealCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
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

// =======================================================
// Skeleton Card (Loading)
// =======================================================

class _MealSkeletonCard extends StatelessWidget {
  const _MealSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.textGrey(context).withValues(alpha: 0.25),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _line(context, 80),
                      const SizedBox(height: 8),
                      _line(context, 140),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.textGrey(context).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, double width) {
    return Container(
      height: 14,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.textGrey(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
