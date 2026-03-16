import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_colors.dart';
import '../../../Admin/services/meals_service.dart';
import '../screens/meal_details_sheet.dart';
import 'add_category_sheet.dart';
import '../../../utils/l.dart';

class AddMealSheet extends StatefulWidget {
  const AddMealSheet({super.key});

  @override
  State<AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<AddMealSheet> {
  final MealsService _service = MealsService();
  final supabase = Supabase.instance.client;

  final TextEditingController nameEnCtrl = TextEditingController();
  final TextEditingController nameArCtrl = TextEditingController();
  final TextEditingController descEnCtrl = TextEditingController();
  final TextEditingController descArCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();

  List<Map<String, dynamic>> categories = [];
  String? selectedCategoryId;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final res = await supabase.from('categories').select();

    setState(() {
      categories = List<Map<String, dynamic>>.from(res);
    });
  }

  Future<void> _openAddCategory() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddCategorySheet(),
    );

    if (result != null) {
      await _loadCategories();
      setState(() {
        selectedCategoryId = result;
      });
    }
  }

  Future<void> _saveMeal() async {
    if (_saving) return;

    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _saving = true);

    final String nameEn = nameEnCtrl.text.trim();
    final String nameAr = nameArCtrl.text.trim();
    final String descEn = descEnCtrl.text.trim();
    final String descAr = descArCtrl.text.trim();
    final num price = num.tryParse(priceCtrl.text) ?? 0;

    final String mealId = await _service.insertMeal(
      nameEn: nameEn,
      nameAr: nameAr,
      descriptionEn: descEn,
      descriptionAr: descAr,
      basePrice: price,
      categoryId: selectedCategoryId,
    );

    final meal = await _service.getMealById(mealId);

    if (!mounted) return;

    // سكّر شاشة الإضافة
    Navigator.pop(context);

    // افتح شاشة التفاصيل من الـ root navigator
    showModalBottomSheet(
      context: Navigator.of(context, rootNavigator: true).context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MealDetailsSheet(meal: meal),
    );
  }

  @override
  void dispose() {
    nameEnCtrl.dispose();
    nameArCtrl.dispose();
    descEnCtrl.dispose();
    descArCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add New Meal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 🟡 CATEGORY SELECTOR
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedCategoryId,
                    dropdownColor: AppColors.card(context),
                    decoration: _input('Select Category'),
                    items: categories.map<DropdownMenuItem<String>>((c) {
                      return DropdownMenuItem<String>(
                        value: c['id'].toString(),
                        child: Text(c['name_en'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedCategoryId = value);
                    },
                  ),
                ),

                const SizedBox(width: 8),
                InkWell(
                  onTap: _openAddCategory,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 🖼 Image placeholder
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.textGrey(context)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.camera_alt, size: 36),
                  SizedBox(height: 8),
                  Text('Tap to add image'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: nameEnCtrl,
              decoration: _input('Meal name (English)'),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: nameArCtrl,
              textDirection: TextDirection.rtl,
              decoration: _input('اسم الوجبة (عربي)'),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: descEnCtrl,
              maxLines: 3,
              decoration: _input('Description (English)'),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: descArCtrl,
              maxLines: 3,
              textDirection: TextDirection.rtl,
              decoration: _input('الوصف (عربي)'),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: _input('Base price (${L.t('currency')})'),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveMeal,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Save Meal',
                        style: TextStyle(
                          color: Colors.black, // 👈 هون لون الخط
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.card(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
