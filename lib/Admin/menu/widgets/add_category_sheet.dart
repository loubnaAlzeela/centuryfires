import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_colors.dart';

class AddCategorySheet extends StatefulWidget {
  const AddCategorySheet({super.key});

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final supabase = Supabase.instance.client;

  final TextEditingController nameEnCtrl = TextEditingController();
  final TextEditingController nameArCtrl = TextEditingController();

  bool _saving = false;

  Future<void> _saveCategory() async {
    if (_saving) return;

    final nameEn = nameEnCtrl.text.trim();
    final nameAr = nameArCtrl.text.trim();

    if (nameEn.isEmpty || nameAr.isEmpty) return;

    setState(() => _saving = true);

    final res = await supabase
        .from('categories')
        .insert({'name_en': nameEn, 'name_ar': nameAr})
        .select()
        .single();

    if (!mounted) return;

    Navigator.pop(context, res['id']); // 👈 رجّع ID للفئة الجديدة
  }

  @override
  void dispose() {
    nameEnCtrl.dispose();
    nameArCtrl.dispose();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add New Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: nameEnCtrl,
            decoration: _input(context, 'Category name (English)'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: nameArCtrl,
            textDirection: TextDirection.rtl,
            decoration: _input(context, 'اسم الفئة (عربي)'),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveCategory,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Save Category'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _input(BuildContext context, String label) {
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
