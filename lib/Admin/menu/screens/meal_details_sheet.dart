import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_colors.dart';
import '../tabs/meal_sizes_tab.dart';
import '../tabs/meal_addons_tab.dart';
import '../../../utils/l.dart';

class MealDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> meal;

  const MealDetailsSheet({super.key, required this.meal});

  @override
  State<MealDetailsSheet> createState() => _MealDetailsSheetState();
}

class _MealDetailsSheetState extends State<MealDetailsSheet>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;

  late TabController _tabController;

  late TextEditingController _nameEnController;
  late TextEditingController _nameArController;
  late TextEditingController _descEnController;
  late TextEditingController _descArController;
  late TextEditingController _priceController;

  File? _pickedFile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    _nameEnController = TextEditingController(
      text: widget.meal['name_en'] ?? '',
    );
    _nameArController = TextEditingController(
      text: widget.meal['name_ar'] ?? '',
    );
    _descEnController = TextEditingController(
      text: widget.meal['description_en'] ?? '',
    );
    _descArController = TextEditingController(
      text: widget.meal['description_ar'] ?? '',
    );
    _priceController = TextEditingController(
      text: widget.meal['base_price']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameEnController.dispose();
    _nameArController.dispose();
    _descEnController.dispose();
    _descArController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ================= PICK IMAGE =================

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null && mounted) {
      setState(() {
        _pickedFile = File(picked.path);
      });
    }
  }

  // ================= UPLOAD IMAGE =================

  Future<String?> _uploadImage(String mealId) async {
    if (_pickedFile == null) return null;

    try {
      final bytes = await _pickedFile!.readAsBytes();
      final ext = _pickedFile!.path.split('.').last;
      final fileName =
          '${mealId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _supabase.storage
          .from('meals')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      return _supabase.storage.from('meals').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('_uploadImage error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(L.t('image_upload_failed'))));
      }
      return null;
    }
  }

  // ================= UPDATE MEAL =================

  Future<void> _updateMeal() async {
    if (_nameEnController.text.trim().isEmpty ||
        _nameArController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(L.t('name_required'))));
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(L.t('invalid_price'))));
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final mealId = widget.meal['id'].toString();
      String? imageUrl = widget.meal['image_url'];

      // حذف الصورة القديمة إن وجدت
      if (_pickedFile != null && imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final oldPath = Uri.parse(imageUrl).pathSegments.last;
          await _supabase.storage.from('meals').remove([oldPath]);
        } catch (_) {}
      }

      if (_pickedFile != null) {
        final uploadedUrl = await _uploadImage(mealId);
        if (uploadedUrl != null) imageUrl = uploadedUrl;
      }

      await _supabase
          .from('meals')
          .update({
            'name_en': _nameEnController.text.trim(),
            'name_ar': _nameArController.text.trim(),
            'description_en': _descEnController.text.trim(),
            'description_ar': _descArController.text.trim(),
            'base_price': price,
            'image_url': imageUrl,
          })
          .eq('id', mealId);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('_updateMeal error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(L.t('error_general'))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ================= DELETE =================

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card(context),
        title: Text(L.t('delete_meal')),
        content: Text(L.t('delete_meal_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(L.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              L.t('delete'),
              style: TextStyle(color: AppColors.error(context)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _deleteMeal();
    }
  }

  Future<void> _deleteMeal() async {
    if (!mounted) return;

    setState(() => _loading = true);
    final mealId = widget.meal['id'].toString();

    try {
      await _supabase.from('meal_addons').delete().eq('meal_id', mealId);
      await _supabase.from('meal_sizes').delete().eq('meal_id', mealId);
      await _supabase.from('meals').delete().eq('id', mealId);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('_deleteMeal error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(L.t('error_general'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealId = widget.meal['id'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Text(
            L.t('meal_settings'),
            style: TextStyle(
              color: AppColors.text(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // الصورة
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: _pickedFile != null
                              ? FileImage(_pickedFile!)
                              : (widget.meal['image_url'] != null &&
                                        widget.meal['image_url']
                                            .toString()
                                            .isNotEmpty
                                    ? NetworkImage(widget.meal['image_url'])
                                    : const AssetImage(
                                        'assets/placeholder.png',
                                      )),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: const Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.edit, color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _loading ? null : _confirmDelete,
                      icon: Icon(Icons.delete, color: AppColors.error(context)),
                      label: Text(
                        L.t('delete_meal'),
                        style: TextStyle(
                          color: AppColors.error(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  _buildField(L.t('name_en'), _nameEnController),
                  const SizedBox(height: 12),
                  _buildField(L.t('name_ar'), _nameArController),
                  const SizedBox(height: 12),
                  _buildField(
                    L.t('description_en'),
                    _descEnController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    L.t('description_ar'),
                    _descArController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    L.t('base_price'),
                    _priceController,
                    keyboard: TextInputType.number,
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _loading ? null : _updateMeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary(context),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(L.t('save_changes')),
                  ),

                  const SizedBox(height: 30),

                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: AppColors.primary(context),
                    labelColor: AppColors.primary(context),
                    unselectedLabelColor: AppColors.textGrey(context),
                    tabs: [
                      Tab(text: L.t('sizes')),
                      Tab(text: L.t('add_ons')),
                      Tab(text: L.t('removal')),
                    ],
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        MealSizesTab(mealId: mealId),
                        MealAddonsTab(mealId: mealId, type: 'extra'),
                        MealAddonsTab(mealId: mealId, type: 'removal'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textGrey(context), fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: TextStyle(color: AppColors.text(context)),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bg(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
