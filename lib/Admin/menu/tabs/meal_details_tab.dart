import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../Admin/services/meals_service.dart';
import '../../../utils/l.dart';

class MealDetailsTab extends StatefulWidget {
  final String mealId;

  const MealDetailsTab({super.key, required this.mealId});

  @override
  State<MealDetailsTab> createState() => _MealDetailsTabState();
}

class _MealDetailsTabState extends State<MealDetailsTab> {
  final MealsService _service = MealsService();

  final nameEnCtrl = TextEditingController();
  final nameArCtrl = TextEditingController();
  final descEnCtrl = TextEditingController();
  final descArCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadMeal();
  }

  Future<void> _loadMeal() async {
    final meal = await _service.getMealById(widget.mealId);

    nameEnCtrl.text = meal['name_en'] ?? '';
    nameArCtrl.text = meal['name_ar'] ?? '';
    descEnCtrl.text = meal['description_en'] ?? '';
    descArCtrl.text = meal['description_ar'] ?? '';
    priceCtrl.text = '${meal['base_price'] ?? 0}';

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    await _service.updateMeal(
      id: widget.mealId,
      nameEn: nameEnCtrl.text,
      nameAr: nameArCtrl.text,
      descEn: descEnCtrl.text,
      descAr: descArCtrl.text,
      price: num.tryParse(priceCtrl.text)?.toDouble() ?? 0,
    );

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(L.t('saving'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          _field(L.t('meal_name_en'), nameEnCtrl),
          _field(L.t('meal_name_ar'), nameArCtrl, rtl: true),
          _field(L.t('meal_description_en'), descEnCtrl, lines: 3),
          _field(L.t('meal_description_ar'), descArCtrl, rtl: true, lines: 3),
          _field(L.t('meal_base_price'), priceCtrl, number: true),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const CircularProgressIndicator()
                : SnackBar(content: Text(L.t('saved_successfully'))),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool rtl = false,
    int lines = 1,
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: lines,
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        keyboardType: number ? TextInputType.number : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.card(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
