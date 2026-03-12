import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/l.dart';
import '../../utils/language_controller.dart';
import '../services/admin_rewards_service.dart';

class AdminRewardsScreen extends StatefulWidget {
  const AdminRewardsScreen({super.key});

  @override
  State<AdminRewardsScreen> createState() => _AdminRewardsScreenState();
}

class _AdminRewardsScreenState extends State<AdminRewardsScreen> {
  final AdminRewardsService _service = AdminRewardsService();
  bool _loading = true;
  List<Map<String, dynamic>> _rewards = [];
  List<Map<String, dynamic>> _coupons = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);

    // 1) جلب المكافآت
    try {
      final res = await _service.getRewards();
      if (!mounted) return;
      _rewards = res;
    } catch (e) {
      debugPrint('AdminRewardsScreen getRewards Error: $e');
    }

    // 2) جلب الكوبونات (مستقل - لو فشل لا يوقف المكافآت)
    try {
      final coups = await _service.getCoupons();
      if (!mounted) return;
      _coupons = coups;
    } catch (e) {
      debugPrint('AdminRewardsScreen getCoupons Error: $e');
      // الكوبونات فشلت لكن المكافآت تظهر عادي
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _showAddEditModal([Map<String, dynamic>? reward]) {
    final bool isEdit = reward != null;
    final titleArController = TextEditingController(text: reward?['title_ar'] ?? '');
    final titleEnController = TextEditingController(text: reward?['title_en'] ?? '');
    final descArController = TextEditingController(text: reward?['description_ar'] ?? '');
    final descEnController = TextEditingController(text: reward?['description_en'] ?? '');
    final pointsController = TextEditingController(text: reward?['points_required']?.toString() ?? '');
    String? selectedPromotionId = reward?['promotion_id']?.toString();
    bool isActive = reward?['is_active'] ?? true;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.bg(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? L.t('edit_reward') : L.t('add_new_reward'),
                          style: TextStyle(
                            color: AppColors.text(context),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.textGrey(context)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _textInput(L.t('admin_title_ar'), titleArController),
                    const SizedBox(height: 12),
                    _textInput(L.t('admin_title_en'), titleEnController),
                    const SizedBox(height: 12),
                    _textInput(L.t('admin_desc_ar'), descArController),
                    const SizedBox(height: 12),
                    _textInput(L.t('admin_desc_en'), descEnController),
                    const SizedBox(height: 12),
                    _textInput(L.t('points'), pointsController, isNumber: true),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedPromotionId,
                      dropdownColor: AppColors.card(context),
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        labelText: L.t('select_coupon'),
                        labelStyle: TextStyle(color: AppColors.textGrey(context)),
                        filled: true,
                        fillColor: AppColors.card(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.textGrey(context).withOpacity(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.textGrey(context).withOpacity(0.2)),
                        ),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            L.t('none'),
                            style: TextStyle(color: AppColors.textGrey(context)),
                          ),
                        ),
                        ..._coupons.map((c) {
                          final title = LanguageController.isArabic.value
                              ? c['title_ar'] ?? c['title_en']
                              : c['title_en'] ?? c['title_ar'];
                          final code = c['code'] ?? '';
                          return DropdownMenuItem<String>(
                            value: c['id'].toString(),
                            child: Text('$title ($code)', style: TextStyle(color: AppColors.text(context))),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setModalState(() => selectedPromotionId = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(L.t('is_active'), style: TextStyle(color: AppColors.text(context))),
                      value: isActive,
                      activeColor: AppColors.primary(context),
                      onChanged: (val) {
                        setModalState(() => isActive = val);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary(context),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);

                          final pts = int.tryParse(pointsController.text.trim()) ?? 0;

                          try {
                            if (isEdit) {
                              await _service.updateReward(
                                id: reward['id'],
                                titleAr: titleArController.text.trim(),
                                titleEn: titleEnController.text.trim(),
                                descAr: descArController.text.trim(),
                                descEn: descEnController.text.trim(),
                                points: pts,
                                isActive: isActive,
                                promotionId: selectedPromotionId,
                              );
                            } else {
                              await _service.createReward(
                                titleAr: titleArController.text.trim(),
                                titleEn: titleEnController.text.trim(),
                                descAr: descArController.text.trim(),
                                descEn: descEnController.text.trim(),
                                points: pts,
                                isActive: isActive,
                                promotionId: selectedPromotionId,
                              );
                            }
                            _fetchData();
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(L.t('saved_successfully'))),
                              );
                            }
                          } catch (e) {
                            debugPrint('Save reward error: $e');
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        },
                        child: Text(L.t('save')),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(context),
        title: Text(L.t('delete'), style: TextStyle(color: AppColors.text(context))),
        content: Text(L.t('delete_confirmation'), style: TextStyle(color: AppColors.textGrey(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(L.t('cancel'), style: TextStyle(color: AppColors.textGrey(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                await _service.deleteReward(id);
                _fetchData();
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(L.t('deleted_successfully'))),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(L.t('err_general'))),
                  );
                }
              }
            },
            child: Text(L.t('delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _textInput(String label, TextEditingController controller, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: AppColors.text(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textGrey(context)),
        filled: true,
        fillColor: AppColors.card(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textGrey(context).withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textGrey(context).withOpacity(0.2)),
        ),
      ),
      validator: (val) => val == null || val.trim().isEmpty ? L.t('field_required') : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAr = LanguageController.isArabic.value;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(L.t('rewards')),
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary(context),
        foregroundColor: Colors.black,
        onPressed: () => _showAddEditModal(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary(context)))
          : _rewards.isEmpty
              ? Center(
                  child: Text(L.t('no_items'), style: TextStyle(color: AppColors.textGrey(context))),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rewards.length,
                  itemBuilder: (context, index) {
                    final reward = _rewards[index];
                    final title = isAr ? reward['title_ar'] : reward['title_en'];
                    final desc = isAr ? reward['description_ar'] : reward['description_en'];
                    final pts = reward['points_required'];
                    final isActive = reward['is_active'] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary(context).withOpacity(0.1),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title ?? '',
                                style: TextStyle(
                                  color: AppColors.text(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary(context).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.star, size: 14, color: AppColors.primary(context)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$pts ${L.t('points')}',
                                    style: TextStyle(
                                      color: AppColors.primary(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              desc ?? '',
                              style: TextStyle(color: AppColors.textGrey(context), fontSize: 13),
                            ),
                            if (reward['promotion_id'] != null) ...[
                                const SizedBox(height: 8),
                                Builder(builder: (context) {
                                  final promoId = reward['promotion_id'];
                                  final linkedPromo = _coupons.firstWhere(
                                      (c) => c['id'].toString() == promoId.toString(),
                                      orElse: () => {});
                                  final code = linkedPromo['code'] ?? L.t('none');
                                  return Row(
                                    children: [
                                      Icon(Icons.card_giftcard, size: 14, color: AppColors.primary(context)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${L.t('coupon')}: $code',
                                        style: TextStyle(color: AppColors.primary(context), fontSize: 12),
                                      ),
                                    ],
                                  );
                                }),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  isActive ? Icons.check_circle : Icons.cancel,
                                  size: 14,
                                  color: isActive ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isActive ? L.t('active') : L.t('inactive'),
                                  style: TextStyle(
                                    color: isActive ? Colors.green : Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () => _showAddEditModal(reward),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _confirmDelete(reward['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
