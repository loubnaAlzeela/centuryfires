import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/l.dart';
import '../../theme/app_colors.dart';

class CreatePromotionScreen extends StatefulWidget {
  final Map<String, dynamic>? promo;

  const CreatePromotionScreen({super.key, this.promo});

  @override
  State<CreatePromotionScreen> createState() => _CreatePromotionScreenState();
}

class _CreatePromotionScreenState extends State<CreatePromotionScreen> {
  final supabase = Supabase.instance.client;

  final titleEnCtrl = TextEditingController();
  final titleArCtrl = TextEditingController();
  final descEnCtrl = TextEditingController();
  final descArCtrl = TextEditingController();
  final discountCtrl = TextEditingController();
  final minOrderCtrl = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  String promotionType = "banner"; // banner | big_order | coupon
  String discountType = "percentage"; // percentage | fixed
  bool isActive = true;
  bool isSaving = false;

  final couponCodeCtrl = TextEditingController();
  final maxDiscountCtrl = TextEditingController();
  final usageLimitCtrl = TextEditingController();

  File? selectedImage;
  String? imageUrl;

  // ===== Unsaved changes snapshot =====
  late final Map<String, dynamic> _initialSnapshot;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    if (widget.promo != null) {
      final p = widget.promo!;

      titleEnCtrl.text = (p['title_en'] ?? '').toString();
      titleArCtrl.text = (p['title_ar'] ?? '').toString();
      descEnCtrl.text = (p['description_en'] ?? '').toString();
      descArCtrl.text = (p['description_ar'] ?? '').toString();
      discountCtrl.text = p['discount_value']?.toString() ?? '';
      minOrderCtrl.text = p['min_order_amount']?.toString() ?? '';
      imageUrl = p['image_url']?.toString();

      promotionType = (p['promotion_type'] ?? 'banner').toString();
      discountType = (p['discount_type'] ?? 'percentage').toString();
      isActive = (p['is_active'] ?? true) == true;

      couponCodeCtrl.text = (p['code'] ?? '').toString();
      maxDiscountCtrl.text = p['max_discount']?.toString() ?? '';
      usageLimitCtrl.text = p['usage_limit']?.toString() ?? '';

      if (p['start_at'] != null) {
        startDate = DateTime.tryParse(p['start_at'].toString());
      }
      if (p['end_at'] != null) {
        endDate = DateTime.tryParse(p['end_at'].toString());
      }
    }

    _initialSnapshot = _currentSnapshot();
  }

  @override
  void dispose() {
    titleEnCtrl.dispose();
    titleArCtrl.dispose();
    descEnCtrl.dispose();
    descArCtrl.dispose();
    discountCtrl.dispose();
    minOrderCtrl.dispose();
    couponCodeCtrl.dispose();
    maxDiscountCtrl.dispose();
    usageLimitCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _currentSnapshot() {
    return {
      'title_en': titleEnCtrl.text.trim(),
      'title_ar': titleArCtrl.text.trim(),
      'desc_en': descEnCtrl.text.trim(),
      'desc_ar': descArCtrl.text.trim(),
      'discount': discountCtrl.text.trim(),
      'min_order': minOrderCtrl.text.trim(),
      'start': startDate?.toIso8601String() ?? '',
      'end': endDate?.toIso8601String() ?? '',
      'promotion_type': promotionType,
      'discount_type': discountType,
      'is_active': isActive,
      'coupon_code': couponCodeCtrl.text.trim(),
      'max_discount': maxDiscountCtrl.text.trim(),
      'usage_limit': usageLimitCtrl.text.trim(),
      'image_url': imageUrl ?? '',
      'selected_image': selectedImage?.path ?? '',
    };
  }

  bool _hasUnsavedChanges() {
    final now = _currentSnapshot();
    if (now.length != _initialSnapshot.length) return true;
    for (final k in now.keys) {
      if ((now[k] ?? '') != (_initialSnapshot[k] ?? '')) return true;
    }
    return false;
  }

  Future<bool> _confirmDiscardChanges() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card(ctx),
          title: Text(
            L.t('confirm'),
            style: TextStyle(color: AppColors.text(ctx)),
          ),
          content: Text(
            L.t(
              'unsaved_changes_confirm',
            ) /* لو ما عندك key، بدّله بنص مناسب */,
            style: TextStyle(color: AppColors.textGrey(ctx)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(L.t('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(L.t('discard')),
            ),
          ],
        );
      },
    );
    return res == true;
  }

  // ================= THEME COLORS (NO FIXED) =================
  Color _accentColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    switch (promotionType) {
      case 'banner':
        return AppColors.primary(context); // brand color from your file
      case 'big_order':
        return cs.tertiary; // theme-driven
      case 'coupon':
        return cs.secondary; // theme-driven
      default:
        return AppColors.primary(context);
    }
  }

  // ================= IMAGE =================
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  String? _extractStoragePathFromPublicUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      // public url عادةً: /storage/v1/object/public/<bucket>/<path...>
      final publicIdx = segments.indexOf('public');
      if (publicIdx != -1 && publicIdx + 2 <= segments.length - 1) {
        // segments[publicIdx+1] = bucket
        final path = segments.sublist(publicIdx + 2).join('/');
        return path.isEmpty ? null : path;
      }
      return segments.isNotEmpty ? segments.last : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteOldImageIfNeeded() async {
    if (selectedImage == null) return;
    if (imageUrl == null || imageUrl!.isEmpty) return;

    try {
      final oldPath = _extractStoragePathFromPublicUrl(imageUrl!);
      if (oldPath == null || oldPath.isEmpty) return;

      await supabase.storage.from('promotions').remove([oldPath]);
    } catch (e) {
      // لا نوقف الحفظ بسبب فشل حذف القديم
      debugPrint('_deleteOldImageIfNeeded error: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (selectedImage == null) return imageUrl;

    try {
      final bytes = await selectedImage!.readAsBytes();
      final fileName = 'promo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage
          .from('promotions')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      return supabase.storage.from('promotions').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('_uploadImage error: $e');
      return null;
    }
  }

  // ================= DATES =================
  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();

    final initial = isStart
        ? (startDate ?? now)
        : (endDate ?? startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: widget.promo != null
          ? DateTime(2024)
          : DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;

          // لو endDate قبل startDate، نمسحها (مش نخليها تساوي start)
          if (endDate != null && endDate!.isBefore(picked)) {
            endDate = null;
          }
        } else {
          // لو المستخدم اختار endDate قبل startDate، نسمح؟ الأفضل نرفض ضمنياً
          if (startDate != null && picked.isBefore(startDate!)) {
            endDate = null;
          } else {
            endDate = picked;
          }
        }
      });
    }
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return L.t('admin_select_date');
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Map<String, dynamic> _buildPayload(String? finalImageUrl) {
    return {
      'title_en': titleEnCtrl.text.trim(),
      'title_ar': titleArCtrl.text.trim(),
      'description_en': descEnCtrl.text.trim(),
      'description_ar': descArCtrl.text.trim(),
      'promotion_type': promotionType,

      // big_order & coupon use discount
      'discount_type': (promotionType != "banner") ? discountType : null,
      'discount_value': (promotionType != "banner")
          ? double.tryParse(discountCtrl.text.trim())
          : null,

      // big_order only
      'min_order_amount': (promotionType == "big_order")
          ? double.tryParse(minOrderCtrl.text.trim())
          : null,

      // banner only
      'image_url': (promotionType == "banner") ? finalImageUrl : null,
      'start_at': (promotionType == "banner" || promotionType == "coupon")
          ? startDate?.toIso8601String()
          : null,
      'end_at': (promotionType == "banner" || promotionType == "coupon")
          ? endDate?.toIso8601String()
          : null,

      // coupon only
      'code': (promotionType == "coupon")
          ? couponCodeCtrl.text.trim().toUpperCase()
          : null,
      'max_discount': (promotionType == "coupon")
          ? double.tryParse(maxDiscountCtrl.text.trim())
          : null,
      'usage_limit': (promotionType == "coupon")
          ? int.tryParse(usageLimitCtrl.text.trim())
          : null,

      'is_active': isActive,
    };
  }

  // ================= SAVE =================
  Future<void> _savePromotion() async {
    if (isSaving) return;

    // ===== Basic validation =====
    if (titleEnCtrl.text.trim().isEmpty || titleArCtrl.text.trim().isEmpty) {
      _showMessage(L.t('required'));
      return;
    }

    if (promotionType == 'banner') {
      if (startDate == null || endDate == null) {
        _showMessage(L.t('admin_active_dates'));
        return;
      }
    } else {
      if (discountCtrl.text.trim().isEmpty ||
          double.tryParse(discountCtrl.text.trim()) == null) {
        _showMessage(L.t('admin_discount_value'));
        return;
      }

      if (promotionType == 'big_order') {
        if (minOrderCtrl.text.trim().isEmpty ||
            double.tryParse(minOrderCtrl.text.trim()) == null) {
          _showMessage(L.t('admin_min_order'));
          return;
        }
      }

      if (promotionType == 'coupon') {
        if (couponCodeCtrl.text.trim().isEmpty) {
          _showMessage(L.t('admin_coupon_code'));
          return;
        }
      }
    }

    setState(() => isSaving = true);

    try {
      String? finalImageUrl = imageUrl;

      if (promotionType == "banner") {
        // حذف القديم فقط إذا في صورة جديدة
        await _deleteOldImageIfNeeded();

        finalImageUrl = await _uploadImage();

        if (finalImageUrl == null) {
          _showMessage(L.t('admin_select_image'));
          if (mounted) setState(() => isSaving = false); // ✅ واضح وصريح
          return;
        }
      }

      final data = _buildPayload(finalImageUrl);

      if (widget.promo == null) {
        await supabase.from('promotions').insert(data);
      } else {
        await supabase
            .from('promotions')
            .update(data)
            .eq('id', widget.promo!['id']);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('SAVE ERROR: $e');
      _showMessage(L.t('err_general'));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI HELPERS =================
  Widget _section(
    BuildContext context,
    String titleKey,
    List<Widget> children,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context).withValues(alpha: .75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.textGrey(context).withValues(alpha: .18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.text(context).withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.t(titleKey),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _input(BuildContext context, String labelKey) {
    return InputDecoration(
      labelText: L.t(labelKey),
      labelStyle: TextStyle(color: AppColors.textGrey(context)),
      filled: true,
      fillColor: AppColors.bg(context).withValues(alpha: .35),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.textGrey(context).withValues(alpha: .22),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primary(context).withValues(alpha: .8),
          width: 1.2,
        ),
      ),
    );
  }

  Widget _bannerImageCard(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 170,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.card(context),
          border: Border.all(
            color: AppColors.primary(context).withValues(alpha: .45),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: selectedImage != null
              ? Image.file(
                  selectedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              : (imageUrl != null && imageUrl!.isNotEmpty)
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              : Center(
                  child: Text(
                    L.t('admin_select_image'),
                    style: TextStyle(color: AppColors.textGrey(context)),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _dateTile({
    required BuildContext context,
    required String labelKey,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg(context).withValues(alpha: .28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.textGrey(context).withValues(alpha: .18),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: AppColors.primary(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    L.t(labelKey),
                    style: TextStyle(
                      color: AppColors.textGrey(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _fmtDate(date),
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textGrey(context)),
          ],
        ),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(context);

    return PopScope(
      canPop: !isSaving,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // إذا في حفظ شغال، ما نطلع
        if (isSaving) return;

        // إذا ما في تغييرات، اطلع مباشرة
        if (!_hasUnsavedChanges()) {
          if (mounted) Navigator.pop(context);
          return;
        }

        final confirm = await _confirmDiscardChanges();
        if (confirm == true && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.promo == null
                ? L.t('admin_create_promotion')
                : L.t('admin_edit_promotion'),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: .18),
                AppColors.bg(context),
                AppColors.bg(context),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ===== TYPE =====
                _section(context, 'type', [
                  DropdownButtonFormField<String>(
                    initialValue: promotionType,
                    decoration: _input(context, 'type'),
                    items: [
                      DropdownMenuItem(
                        value: "banner",
                        child: Text(L.t('promo_type_banner')),
                      ),
                      DropdownMenuItem(
                        value: "big_order",
                        child: Text(L.t('promo_type_big_order')),
                      ),
                      DropdownMenuItem(
                        value: "coupon",
                        child: Text(L.t('promo_type_coupon')),
                      ),
                    ],
                    onChanged: (val) => setState(() => promotionType = val!),
                  ),
                ]),

                // ===== IMAGE (Banner only) =====
                if (promotionType == "banner") _bannerImageCard(context),

                // ===== INFO =====
                _section(context, 'promotions', [
                  TextField(
                    controller: titleEnCtrl,
                    textDirection: TextDirection.ltr,
                    decoration: _input(context, 'admin_title_en'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleArCtrl,
                    textDirection: TextDirection.rtl,
                    decoration: _input(context, 'admin_title_ar'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descEnCtrl,
                    maxLines: 2,
                    textDirection: TextDirection.ltr,
                    decoration: _input(context, 'admin_desc_en'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descArCtrl,
                    maxLines: 2,
                    textDirection: TextDirection.rtl,
                    decoration: _input(context, 'admin_desc_ar'),
                  ),
                ]),

                // ===== DISCOUNT (Big order + Coupon) =====
                if (promotionType != "banner")
                  _section(context, 'promo_type_discount', [
                    TextField(
                      controller: discountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _input(context, 'admin_discount_value'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: discountType,
                      decoration: _input(context, 'admin_discount_type'),
                      items: [
                        DropdownMenuItem(
                          value: "percentage",
                          child: Text(L.t('admin_percentage')),
                        ),
                        DropdownMenuItem(
                          value: "fixed",
                          child: Text(L.t('admin_fixed_amount')),
                        ),
                      ],
                      onChanged: (val) => setState(() => discountType = val!),
                    ),
                  ]),

                // ===== BIG ORDER =====
                if (promotionType == "big_order")
                  _section(context, 'promo_type_big_order', [
                    TextField(
                      controller: minOrderCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _input(context, 'admin_min_order'),
                    ),
                  ]),

                // ===== COUPON =====
                if (promotionType == "coupon")
                  _section(context, 'promo_type_coupon', [
                    TextField(
                      controller: couponCodeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _input(context, 'admin_coupon_code_hint'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: maxDiscountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _input(context, 'admin_max_discount_hint'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: usageLimitCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _input(context, 'admin_usage_limit_hint'),
                    ),
                  ]),

                // ===== DATES =====
                if (promotionType == "banner" || promotionType == "coupon")
                  _section(context, 'admin_active_dates', [
                    Row(
                      children: [
                        Expanded(
                          child: _dateTile(
                            context: context,
                            labelKey: 'admin_start_date',
                            date: startDate,
                            onTap: () => _pickDate(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dateTile(
                            context: context,
                            labelKey: 'admin_end_date',
                            date: endDate,
                            onTap: () => _pickDate(isStart: false),
                          ),
                        ),
                      ],
                    ),
                  ]),

                // ===== STATUS =====
                _section(context, 'status', [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      L.t('active'),
                      style: TextStyle(color: AppColors.text(context)),
                    ),
                    value: isActive,
                    activeThumbColor: AppColors.primary(context),
                    onChanged: (val) => setState(() => isActive = val),
                  ),
                ]),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _savePromotion,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary(context),
                      foregroundColor: AppColors.textOnPrimary(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnPrimary(context),
                            ),
                          )
                        : Text(L.t('admin_save_promotion')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
