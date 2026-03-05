import 'package:flutter/material.dart';
import '../../../Admin/services/meal_addons_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/l.dart';

class MealAddonsTab extends StatefulWidget {
  final String mealId;
  final String type; // addon or removal

  const MealAddonsTab({super.key, required this.mealId, required this.type});

  @override
  State<MealAddonsTab> createState() => _MealAddonsTabState();
}

class _MealAddonsTabState extends State<MealAddonsTab> {
  final MealAddonsService _service = MealAddonsService();
  List<Map<String, dynamic>> _addons = [];
  bool _loading = true;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _addonId(Map<String, dynamic> a) {
    return (a['addon_id'] ?? a['id']).toString();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);

    try {
      final data = await _service.getAddons(
        mealId: widget.mealId,
        type: widget.type,
        includeInactive: _showInactive,
      );
      if (!mounted) return;

      setState(() {
        _addons = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _openAddAddonSheet({Map<String, dynamic>? existing}) async {
    final nameEnCtrl = TextEditingController(
      text: existing?['addon_name_en'] ?? '',
    );
    final nameArCtrl = TextEditingController(
      text: existing?['addon_name_ar'] ?? '',
    );
    final priceCtrl = TextEditingController(
      text: existing?['price']?.toString() ?? '',
    );

    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(ctx).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null ? L.t('add_new_addon') : L.t('edit_addon'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text(ctx),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameEnCtrl,
                    decoration: InputDecoration(labelText: L.t('name_english')),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameArCtrl,
                    decoration: InputDecoration(labelText: L.t('name_arabic')),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: L.t('price')),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary(ctx),
                        foregroundColor: AppColors.textOnPrimary(ctx),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: saving
                          ? null
                          : () async {
                              final nameEn = nameEnCtrl.text.trim();
                              final nameAr = nameArCtrl.text.trim();
                              final price = double.tryParse(
                                priceCtrl.text.trim(),
                              );

                              if (nameEn.isEmpty || nameAr.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(L.t('name_required'))),
                                );
                                return;
                              }

                              if (price == null || price < 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(L.t('invalid_price'))),
                                );
                                return;
                              }

                              setSheetState(() => saving = true);

                              try {
                                if (existing == null) {
                                  await _service.createAndAttach(
                                    mealId: widget.mealId,
                                    nameEn: nameEn,
                                    nameAr: nameAr,
                                    price: price,
                                    type: widget.type,
                                  );
                                } else {
                                  await _service.updateAddon(
                                    addonId: existing['id'],
                                    nameEn: nameEn,
                                    nameAr: nameAr,
                                    price: price,
                                  );
                                }

                                if (!mounted) return;

                                Navigator.pop(ctx);
                                await _load();
                              } catch (e) {
                                debugPrint('saveAddon error: $e');
                                setSheetState(() => saving = false);

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(L.t('error_general')),
                                    ),
                                  );
                                }
                              }
                            },
                      child: saving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary(ctx),
                              ),
                            )
                          : Text(L.t('save')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nameEnCtrl.dispose();
    nameArCtrl.dispose();
    priceCtrl.dispose();
  }

  Future<void> _deleteAddon(Map<String, dynamic> a) async {
    final id = _addonId(a);

    try {
      await _service.deleteAddon(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            L.t('addon_disabled'),
            style: TextStyle(color: AppColors.textOnPrimary(context)),
          ),
          backgroundColor: AppColors.primary(context),
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _addons.removeWhere((addon) => _addonId(addon) == id);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            L.t('delete_failed'),
            style: TextStyle(color: AppColors.textOnPrimary(context)),
          ),
          backgroundColor: AppColors.error(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary(context)),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            SwitchListTile(
              value: _showInactive,
              onChanged: (v) async {
                setState(() => _showInactive = v);
                await _load();
              },
              title: Text(L.t('show_inactive')),
            ),
            Expanded(
              child: _addons.isEmpty
                  ? Center(
                      child: Text(
                        L.t('no_items'),
                        style: TextStyle(color: AppColors.textGrey(context)),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        80 + MediaQuery.of(context).padding.bottom,
                      ),
                      itemCount: _addons.length,
                      itemBuilder: (_, i) {
                        final a = _addons[i];
                        final bool isInactive = a['is_active'] == false;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isInactive
                                ? AppColors.textGrey(
                                    context,
                                  ).withValues(alpha: 0.08)
                                : AppColors.card(context),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            textDirection: isArabic
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            children: [
                              Expanded(
                                flex: 7,
                                child: Column(
                                  children: [
                                    Text(
                                      isArabic
                                          ? (a['addon_name_ar'] ?? '')
                                          : (a['addon_name_en'] ?? ''),
                                      style: TextStyle(
                                        color: AppColors.text(context),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      a['price'] != null
                                          ? '+${a['price']} ${L.t('currency')}'
                                          : '',
                                      style: TextStyle(
                                        color: AppColors.textGrey(context),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Transform.scale(
                                    scale: 0.78,
                                    child: Switch(
                                      value: a['linked'] == true,
                                      onChanged: isInactive
                                          ? null
                                          : (v) async {
                                              try {
                                                if (v) {
                                                  await _service.attach(
                                                    mealId: widget.mealId,
                                                    addonId: _addonId(a),
                                                  );
                                                } else {
                                                  await _service.detach(
                                                    widget.mealId,
                                                    _addonId(a),
                                                  );
                                                }
                                                await _load();
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        L.t('error_general'),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        size: 18,
                                        color: isInactive
                                            ? AppColors.textGrey(
                                                context,
                                              ).withValues(alpha: 0.4)
                                            : AppColors.textGrey(context),
                                      ),
                                      onPressed: isInactive
                                          ? null
                                          : () =>
                                                _openAddAddonSheet(existing: a),
                                    ),
                                    const SizedBox(height: 6),
                                    IconButton(
                                      icon: Icon(
                                        isInactive
                                            ? Icons.restore
                                            : Icons.delete,
                                        size: 18,
                                        color: isInactive
                                            ? AppColors.primary(context)
                                            : AppColors.error(context),
                                      ),
                                      onPressed: () async {
                                        try {
                                          if (isInactive) {
                                            await _service.restoreAddon(
                                              _addonId(a),
                                            );
                                            await _load();
                                          } else {
                                            await _deleteAddon(a);
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  L.t('error_general'),
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: AppColors.primary(context),
            foregroundColor: AppColors.textOnPrimary(context),
            onPressed: () => _openAddAddonSheet(),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
