import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../screens/meal_details_sheet.dart';
import 'category_chip.dart';
import '../../services/meals_service.dart';
import '../../services/categories_service.dart';
import '../../../utils/l.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  final MealsService _service = MealsService();
  final CategoriesService _categoriesService = CategoriesService();

  String? _selectedCategoryId;
  bool _loading = true;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _meals = [];

  bool get isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);

    final categories = await _categoriesService.getCategories();
    final meals = await _service.getMeals();

    setState(() {
      _categories = categories;
      _meals = meals;
      _loading = false;
    });
  }

  Future<void> _loadMeals() async {
    setState(() => _loading = true);

    final data = await _service.getMeals(categoryId: _selectedCategoryId);

    setState(() {
      _meals = data;
      _loading = false;
    });
  }

  Future<void> _openMealDetails(Map<String, dynamic> meal) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MealDetailsSheet(meal: meal),
    );

    if (result == true) {
      _loadMeals(); // refresh after update/delete
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasItems = _meals.isNotEmpty;
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          /// 🔍 Search
          TextField(
            decoration: InputDecoration(
              hintText: 'Search meals...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.card(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// 🏷️ Category Filters
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                CategoryChip(
                  label: isArabic ? 'الكل' : 'All',
                  selected: _selectedCategoryId == null,
                  onTap: () {
                    setState(() => _selectedCategoryId = null);
                    _loadMeals();
                  },
                ),

                ..._categories.map((cat) {
                  final String id = cat['id'];
                  final String label = isArabic
                      ? (cat['name_ar'] ?? '')
                      : (cat['name_en'] ?? '');

                  return CategoryChip(
                    label: label,
                    selected: _selectedCategoryId == id,
                    onTap: () {
                      setState(() => _selectedCategoryId = id);
                      _loadMeals();
                    },
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// 📦 Meals Grid
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : hasItems
                ? GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.6,
                        ),
                    itemCount: _meals.length,

                    itemBuilder: (_, index) {
                      final meal = _meals[index];

                      return GestureDetector(
                        onTap: () => _openMealDetails(meal),

                        child: MealCard(
                          name: isArabic
                              ? (meal['name_ar'] ?? '')
                              : (meal['name_en'] ?? ''),
                          price: meal['base_price'] ?? 0,
                          imageUrl: meal['image_url'],
                          isArabic: isArabic,
                        ),
                      );
                    },
                  )
                : const _EmptyState(),
          ),
        ],
      ),
    );
  }
}

class MealCard extends StatelessWidget {
  final String name;
  final num price;
  final String? imageUrl;
  final bool isArabic;

  const MealCard({
    super.key,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          /// 🖼️ IMAGE
          Expanded(
            flex: 7,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? const Center(child: Icon(Icons.image, size: 48))
                  : null,
            ),
          ),

          /// 📝 TEXT
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Align(
                alignment: isArabic
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Column(
                  // 👈 لازم Column هون
                  crossAxisAlignment: isArabic
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$price ${L.t('currency')}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textGrey(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 72,
            color: AppColors.textGrey(context),
          ),
          const SizedBox(height: 16),
          const Text(
            'No meals yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Start by adding your first meal',
            style: TextStyle(color: AppColors.textGrey(context)),
          ),
        ],
      ),
    );
  }
}
