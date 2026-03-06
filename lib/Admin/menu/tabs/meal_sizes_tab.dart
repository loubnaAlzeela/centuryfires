import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/l.dart';

class MealSizesTab extends StatefulWidget {
  final String mealId;

  const MealSizesTab({super.key, required this.mealId});

  @override
  State<MealSizesTab> createState() => _MealSizesTabState();
}

class _MealSizesTabState extends State<MealSizesTab> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _sizes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSizes();
  }

  Future<void> _loadSizes() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final data = await _supabase
          .from('meal_sizes')
          .select()
          .eq('meal_id', widget.mealId)
          .order('created_at', ascending: true);

      _sizes = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('MealSizesTab _loadSizes error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(L.t('error_general'))));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteSize(String id) async {
    try {
      await _supabase.from('meal_sizes').delete().eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(L.t('deleted_successfully'))));
      }

      await _loadSizes();
    } catch (e) {
      debugPrint('MealSizesTab _deleteSize error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(L.t('error_general'))));
      }
    }
  }

  Future<void> _setDefaultSize(String id) async {
    try {
      await _supabase
          .from('meal_sizes')
          .update({'is_default': false})
          .eq('meal_id', widget.mealId);

      await _supabase
          .from('meal_sizes')
          .update({'is_default': true})
          .eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(L.t('updated_successfully'))));
      }

      await _loadSizes();
    } catch (e) {
      debugPrint('MealSizesTab _setDefaultSize error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(L.t('error_general'))));
      }
    }
  }

  Future<void> _showSizeDialog({Map<String, dynamic>? size}) async {
    final bool isEdit = size != null;

    final TextEditingController sizeNameController = TextEditingController(
      text: isEdit ? (size['size_name'] ?? '').toString() : '',
    );

    final TextEditingController priceController = TextEditingController(
      text: isEdit ? (size['price'] ?? '').toString() : '',
    );

    bool isDefault = isEdit ? (size['is_default'] ?? false) == true : false;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> save() async {
              final String sizeName = sizeNameController.text.trim();
              final double? price = double.tryParse(
                priceController.text.trim(),
              );

              if (sizeName.isEmpty || price == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(L.t('please_fill_all_fields'))),
                );
                return;
              }

              setModalState(() => saving = true);

              try {
                final payload = {
                  'meal_id': widget.mealId,
                  'size_name': sizeName,
                  'price': price,
                  'is_default': isDefault,
                };

                if (isEdit) {
                  await _supabase
                      .from('meal_sizes')
                      .update(payload)
                      .eq('id', size['id']);
                } else {
                  await _supabase.from('meal_sizes').insert(payload);
                }

                if (isDefault) {
                  final currentId = isEdit ? size['id'].toString() : null;

                  await _supabase
                      .from('meal_sizes')
                      .update({'is_default': false})
                      .eq('meal_id', widget.mealId);

                  if (isEdit) {
                    await _supabase
                        .from('meal_sizes')
                        .update({'is_default': true})
                        .eq('id', currentId!);
                  } else {
                    final inserted = await _supabase
                        .from('meal_sizes')
                        .select('id')
                        .eq('meal_id', widget.mealId)
                        .eq('size_name', sizeName)
                        .eq('price', price)
                        .order('created_at', ascending: false)
                        .limit(1)
                        .maybeSingle();

                    if (inserted != null && inserted['id'] != null) {
                      await _supabase
                          .from('meal_sizes')
                          .update({'is_default': true})
                          .eq('id', inserted['id']);
                    }
                  }
                }

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit
                            ? L.t('updated_successfully')
                            : L.t('added_successfully'),
                      ),
                    ),
                  );
                }

                await _loadSizes();
              } catch (e) {
                debugPrint('MealSizesTab save size error: $e');
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(SnackBar(content: Text(L.t('error_general'))));
                }
              } finally {
                if (dialogContext.mounted) {
                  setModalState(() => saving = false);
                }
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.card(context),
              title: Text(
                isEdit ? L.t('edit_size') : L.t('add_size'),
                style: TextStyle(color: AppColors.text(context)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: sizeNameController,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        labelText: L.t('size_name'),
                        labelStyle: TextStyle(
                          color: AppColors.textGrey(context),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.textHint(context),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        labelText: L.t('price'),
                        labelStyle: TextStyle(
                          color: AppColors.textGrey(context),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.textHint(context),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: isDefault,
                      onChanged: (v) {
                        setModalState(() => isDefault = v ?? false);
                      },
                      activeColor: AppColors.primary(context),
                      checkColor: AppColors.textOnPrimary(context),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        L.t('default_size'),
                        style: TextStyle(color: AppColors.text(context)),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    L.t('cancel'),
                    style: TextStyle(color: AppColors.textGrey(context)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary(context),
                    foregroundColor: AppColors.textOnPrimary(context),
                  ),
                  onPressed: saving ? null : save,
                  child: Text(saving ? L.t('saving') : L.t('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> size) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card(context),
          title: Text(
            L.t('delete_size'),
            style: TextStyle(color: AppColors.text(context)),
          ),
          content: Text(
            L.t('delete_confirmation'),
            style: TextStyle(color: AppColors.textGrey(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                L.t('cancel'),
                style: TextStyle(color: AppColors.textGrey(context)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error(context),
                foregroundColor: AppColors.textOnPrimary(context),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(L.t('delete')),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _deleteSize(size['id'].toString());
    }
  }

  Widget _buildSizeCard(Map<String, dynamic> size) {
    final bool isDefault = (size['is_default'] ?? false) == true;

    return Card(
      color: AppColors.card(context),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          (size['size_name'] ?? '').toString(),
          style: TextStyle(
            color: AppColors.text(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${L.t('price_label')}: ${size['price']}',
                style: TextStyle(color: AppColors.textGrey(context)),
              ),
              const SizedBox(height: 6),
              Text(
                isDefault ? L.t('default_size') : L.t('not_default'),
                style: TextStyle(
                  color: isDefault
                      ? AppColors.primary(context)
                      : AppColors.textHint(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              onPressed: isDefault
                  ? null
                  : () => _setDefaultSize(size['id'].toString()),
              icon: Icon(
                Icons.star,
                color: isDefault
                    ? AppColors.primary(context)
                    : AppColors.textHint(context),
              ),
              tooltip: L.t('set_as_default'),
            ),
            IconButton(
              onPressed: () => _showSizeDialog(size: size),
              icon: Icon(Icons.edit, color: AppColors.primary(context)),
            ),
            IconButton(
              onPressed: () => _confirmDelete(size),
              icon: Icon(Icons.delete, color: AppColors.error(context)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary(context),
        foregroundColor: AppColors.textOnPrimary(context),
        onPressed: () => _showSizeDialog(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSizes,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _sizes.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: Text(
                        L.t('no_sizes_found'),
                        style: TextStyle(color: AppColors.textGrey(context)),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _sizes.length,
                itemBuilder: (context, index) {
                  final size = _sizes[index];
                  return _buildSizeCard(size);
                },
              ),
      ),
    );
  }
}
