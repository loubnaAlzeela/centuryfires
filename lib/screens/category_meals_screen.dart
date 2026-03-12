import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/category_model.dart';
import '../models/meal_model.dart';
import '../services/category_service.dart';
import '../services/meal_service.dart';
import '../utils/cart_controller.dart';
import '../utils/l.dart';
import '../utils/language_controller.dart';
import 'meal_details_screen.dart';

class CategoryMealsScreen extends StatefulWidget {
  final int initialIndex;

  const CategoryMealsScreen({super.key, this.initialIndex = 0});

  @override
  State<CategoryMealsScreen> createState() => _CategoryMealsScreenState();
}

class _CategoryMealsScreenState extends State<CategoryMealsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<CategoryModel> categories = [];
  bool _loading = true;

  bool get isArabic => LanguageController.ar;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final data = await CategoryService().getCategories();
    if (!mounted) return;

    final totalTabs = data.length + 1;
    final safeIndex = widget.initialIndex < totalTabs ? widget.initialIndex : 0;

    _tabController = TabController(
      length: totalTabs,
      vsync: this,
      initialIndex: safeIndex,
    );

    setState(() {
      categories = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _tabController == null) {
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary(context)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        title: Text(L.t('menu')),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicator: BoxDecoration(
            color: AppColors.primary(context),
            borderRadius: BorderRadius.circular(30),
          ),
          labelColor: Colors.black,
          unselectedLabelColor: AppColors.text(context),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: [
            Tab(text: L.t('all')),
            ...categories.map(
              (CategoryModel c) => Tab(text: c.displayName(isArabic)),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _MealsList(categoryId: null),
          ...categories.map((CategoryModel c) => _MealsList(categoryId: c.id)),
        ],
      ),
    );
  }
}

/* =========================================================
   Meals List
   ========================================================= */

class _MealsList extends StatelessWidget {
  final String? categoryId;

  const _MealsList({this.categoryId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MealModel>>(
      future: MealService().getMealsByCategory(categoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary(context)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              L.t('no_items'),
              style: TextStyle(color: AppColors.textGrey(context)),
            ),
          );
        }

        final meals = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: meals.length,
          itemBuilder: (context, index) {
            final meal = meals[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MealDetailsScreen(meal: meal),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // ── الصورة مع العداد ──
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            (meal.image ?? '').trim(),
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 90,
                              height: 90,
                              color: AppColors.card(context),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.image_not_supported,
                                color: AppColors.textGrey(context),
                              ),
                            ),
                          ),
                        ),
                        // العداد الذي يظهر "برا" على الكرت
                        Positioned(
                          top: -5,
                          right: -5,
                          child: ListenableBuilder(
                            listenable: CartController.instance,
                            builder: (context, _) {
                              final mealCount = CartController.instance.lines
                                  .where(
                                    (l) =>
                                        l.mealId.toString() ==
                                        meal.id.toString(),
                                  )
                                  .fold(0, (sum, l) => sum + l.quantity);

                              if (mealCount == 0) {
                                return const SizedBox.shrink();
                              }

                              return Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black, // أسود كما هو مطلوب
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

                    const SizedBox(width: 12),

                    // ── الاسم والسعر ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.displayName(LanguageController.ar),
                            style: TextStyle(
                              color: AppColors.text(context),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${meal.basePrice} SAR',
                            style: TextStyle(
                              color: AppColors.primary(context),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── زر + مع Badge ──
                    ListenableBuilder(
                      listenable: CartController.instance,
                      builder: (context, _) {
                        // الطريقة الصحيحة لحساب كمية الوجبة بغض النظر عن الإضافات
                        final mealCount = CartController.instance.lines
                            .where(
                              (l) => l.mealId.toString() == meal.id.toString(),
                            )
                            .fold(0, (sum, l) => sum + l.quantity);

                        final bool isInCart = mealCount > 0;

                        return GestureDetector(
                          onTap: () {
                            // تنفيذ الإضافة
                            CartController.instance.addLine(
                              mealId: meal.id,
                              name: meal.displayName(LanguageController.ar),
                              price: meal.basePrice,
                              imageUrl: meal.image,
                              addonIds: [],
                              addonNames: [],
                            );

                            // إظهار تنبيه نجاح
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
                              // تغيير شكل الزر إذا كانت الوجبة مضافة
                              CircleAvatar(
                                backgroundColor: AppColors.primary(context),
                                child: Icon(
                                  isInCart
                                      ? Icons.shopping_cart_checkout
                                      : Icons.add, // أيقونة مختلفة عند الإضافة
                                  color: Colors.black,
                                ),
                              ),
                              // العداد (Badge)
                              if (isInCart)
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
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
            );
          },
        );
      },
    );
  }
}
