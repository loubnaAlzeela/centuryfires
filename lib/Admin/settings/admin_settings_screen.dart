import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../utils/l.dart';
import 'model/admin_settings_model.dart';
import '../services/admin_settings_service.dart';
import 'widgets/settings_card.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _service = AdminSettingsService();
  final supabase = Supabase.instance.client;

  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;

  final _instagramCtrl = TextEditingController();
  final _tiktokCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();

  late AdminSettingsModel _settings;

  // Controllers
  final _nameEnCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _openingCtrl = TextEditingController();
  final _closingCtrl = TextEditingController();

  final _radiusCtrl = TextEditingController();
  final _deliveryFeeCtrl = TextEditingController();
  final _minOrderCtrl = TextEditingController();
  final _freeDeliveryCtrl = TextEditingController();

  final _prepTimeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _nameEnCtrl.dispose();
    _nameArCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _openingCtrl.dispose();
    _closingCtrl.dispose();
    _radiusCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    _minOrderCtrl.dispose();
    _freeDeliveryCtrl.dispose();
    _prepTimeCtrl.dispose();

    _instagramCtrl.dispose();
    _tiktokCtrl.dispose();
    _facebookCtrl.dispose();

    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final settings = await _service.getSettings();

    _settings = settings;

    _nameEnCtrl.text = settings.nameEn;
    _nameArCtrl.text = settings.nameAr;
    _phoneCtrl.text = settings.phone;
    _emailCtrl.text = settings.email;
    _addressCtrl.text = settings.address;

    _openingCtrl.text = settings.openingTime;
    _closingCtrl.text = settings.closingTime;

    _radiusCtrl.text = settings.deliveryRadiusKm.toString();
    _deliveryFeeCtrl.text = settings.deliveryFee.toStringAsFixed(0);
    _minOrderCtrl.text = settings.minOrderAmount.toStringAsFixed(0);
    _freeDeliveryCtrl.text = settings.freeDeliveryMinimum.toStringAsFixed(0);

    _instagramCtrl.text = _settings.instagramUrl;
    _tiktokCtrl.text = _settings.tiktokUrl;
    _facebookCtrl.text = _settings.facebookUrl;

    _prepTimeCtrl.text = settings.defaultPrepTimeMin.toString();

    setState(() {
      _dirty = false;
      _loading = false;
    });
  }

  void _markDirty() {
    if (_dirty) return;
    setState(() => _dirty = true);
  }

  int _toInt(String s, int fallback) => int.tryParse(s.trim()) ?? fallback;
  double _toDouble(String s, double fallback) =>
      double.tryParse(s.trim()) ?? fallback;

  AdminSettingsModel _collect() {
    return _settings.copyWith(
      nameEn: _nameEnCtrl.text.trim(),
      nameAr: _nameArCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      openingTime: _openingCtrl.text.trim(),
      closingTime: _closingCtrl.text.trim(),
      deliveryRadiusKm: _toInt(_radiusCtrl.text, _settings.deliveryRadiusKm),
      deliveryFee: _toDouble(_deliveryFeeCtrl.text, _settings.deliveryFee),
      minOrderAmount: _toDouble(_minOrderCtrl.text, _settings.minOrderAmount),
      freeDeliveryMinimum: _toDouble(
        _freeDeliveryCtrl.text,
        _settings.freeDeliveryMinimum,
      ),
      defaultPrepTimeMin: _toInt(
        _prepTimeCtrl.text,
        _settings.defaultPrepTimeMin,
      ),

      // 👇 أضيفي هاد
      instagramUrl: _instagramCtrl.text.trim().split('?').first,
      tiktokUrl: _tiktokCtrl.text.trim().split('?').first,
      facebookUrl: _facebookCtrl.text.trim().split('?').first,
    );
  }

  // ✅ حفظ جزئي للسوشال فقط (كل وحدة لحال)
  Future<void> _updateSocialField(Map<String, dynamic> data) async {
    final cleaned = <String, dynamic>{};

    data.forEach((key, value) {
      if (value is String && value.contains('?')) {
        cleaned[key] = value.split('?').first;
      } else {
        cleaned[key] = value;
      }
    });

    await supabase.from('restaurant_settings').update(cleaned).eq('id', 1);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final updated = _collect();
      await _service.saveSettings(updated);

      setState(() {
        _settings = updated;
        _dirty = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L.t('saved_successfully')),
            backgroundColor: AppColors.card(context),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${L.t('error')}: $e'),
            backgroundColor: AppColors.error(context),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ====== UI helpers ======
  InputDecoration _fieldDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textHint(context)),
      filled: true,
      fillColor: AppColors.bg(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.textGrey(context).withValues(alpha: 0.25),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.textGrey(context).withValues(alpha: 0.25),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primary(context).withValues(alpha: 0.9),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  // ✅ عدلتها: تدعم onChanged و onSubmitted
  Widget _textField({
    required TextEditingController ctrl,
    required String hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      onChanged: onChanged ?? (_) => _markDirty(),
      onSubmitted: onSubmitted,
      style: TextStyle(color: AppColors.text(context)),
      decoration: _fieldDeco(hint),
    );
  }

  Widget _fieldBlock({
    required String title,
    required String description,
    required TextEditingController ctrl,
    TextInputType? keyboardType,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.text(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(color: AppColors.textGrey(context), fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          onChanged: (_) => _markDirty(),
          style: TextStyle(color: AppColors.text(context)),
          decoration: InputDecoration(
            suffixText: suffix,
            filled: true,
            fillColor: AppColors.bg(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.textGrey(context).withValues(alpha: 0.25),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.textGrey(context).withValues(alpha: 0.25),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary(context)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _switchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.textGrey(context).withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.text(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textGrey(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {
              _markDirty();
              onChanged(v);
            },
            activeThumbColor: AppColors.primary(context),
          ),
        ],
      ),
    );
  }

  Widget _daysPicker() {
    final days = <int, String>{
      1: L.t('mon'),
      2: L.t('tue'),
      3: L.t('wed'),
      4: L.t('thu'),
      5: L.t('fri'),
      6: L.t('sat'),
      7: L.t('sun'),
    };

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: days.entries.map((e) {
        final selected = _settings.workingDays.contains(e.key);

        return InkWell(
          onTap: () {
            _markDirty();
            final set = _settings.workingDays.toSet();
            if (selected) {
              set.remove(e.key);
            } else {
              set.add(e.key);
            }
            setState(
              () => _settings = _settings.copyWith(
                workingDays: set.toList()..sort(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary(context).withValues(alpha: 0.2)
                  : AppColors.bg(context),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? AppColors.primary(context).withValues(alpha: 0.9)
                    : AppColors.textGrey(context).withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                color: selected
                    ? AppColors.text(context)
                    : AppColors.textGrey(context),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _grid2(BuildContext context, Widget left, Widget right) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 900) {
      return Column(children: [left, const SizedBox(height: 14), right]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 14),
        Expanded(child: right),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        title: Text(
          L.t('settings'),
          style: TextStyle(
            color: AppColors.text(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: ElevatedButton.icon(
              onPressed: (!_dirty || _saving || _loading) ? null : _save,
              icon: _saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          AppColors.textOnPrimary(context),
                        ),
                      ),
                    )
                  : Icon(
                      Icons.save_rounded,
                      size: 18,
                      color: AppColors.textOnPrimary(context),
                    ),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  L.t('save_changes'),
                  style: TextStyle(
                    color: AppColors.textOnPrimary(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                disabledBackgroundColor: AppColors.textGrey(
                  context,
                ).withValues(alpha: 0.2),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primary(context)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ================= Row 1 =================
                  _grid2(
                    context,
                    SettingsCard(
                      icon: Icons.storefront,
                      title: L.t('restaurant_information'),
                      subtitle: L.t('configure_restaurant_preferences'),
                      child: Column(
                        children: [
                          _grid2(
                            context,
                            _textField(
                              ctrl: _nameEnCtrl,
                              hint: L.t('restaurant_name_en'),
                            ),
                            _textField(
                              ctrl: _nameArCtrl,
                              hint: L.t('restaurant_name_ar'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _grid2(
                            context,
                            _textField(
                              ctrl: _phoneCtrl,
                              hint: L.t('phone'),
                              keyboardType: TextInputType.phone,
                            ),
                            _textField(
                              ctrl: _emailCtrl,
                              hint: L.t('email'),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _textField(ctrl: _addressCtrl, hint: L.t('address')),
                        ],
                      ),
                    ),
                    SettingsCard(
                      icon: Icons.access_time,
                      title: L.t('working_hours'),
                      subtitle: L.t('set_operating_hours'),
                      child: Column(
                        children: [
                          _grid2(
                            context,
                            _textField(
                              ctrl: _openingCtrl,
                              hint: L.t('opening_time'),
                            ),
                            _textField(
                              ctrl: _closingCtrl,
                              hint: L.t('closing_time'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              L.t('working_days'),
                              style: TextStyle(
                                color: AppColors.text(context),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _daysPicker(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ================= Row 2 =================
                  _grid2(
                    context,
                    SettingsCard(
                      icon: Icons.location_on,
                      title: L.t('delivery_settings'),
                      subtitle: L.t('configure_delivery_areas'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldBlock(
                            title: L.t('delivery_radius_title'),
                            description: L.t('delivery_radius_desc'),
                            ctrl: _radiusCtrl,
                            keyboardType: TextInputType.number,
                            suffix: L.t('km'),
                          ),
                          const SizedBox(height: 16),
                          _fieldBlock(
                            title: L.t('delivery_fee_title'),
                            description: L.t('delivery_fee_desc'),
                            ctrl: _deliveryFeeCtrl,
                            keyboardType: TextInputType.number,
                            suffix: 'SAR',
                          ),
                          const SizedBox(height: 16),
                          _fieldBlock(
                            title: L.t('min_order_delivery_title'),
                            description: L.t('min_order_delivery_desc'),
                            ctrl: _minOrderCtrl,
                            keyboardType: TextInputType.number,
                            suffix: 'SAR',
                          ),
                          const SizedBox(height: 16),
                          _fieldBlock(
                            title: L.t('free_delivery_above_title'),
                            description: L.t('free_delivery_above_desc'),
                            ctrl: _freeDeliveryCtrl,
                            keyboardType: TextInputType.number,
                            suffix: 'SAR',
                          ),
                        ],
                      ),
                    ),
                    SettingsCard(
                      icon: Icons.receipt_long,
                      title: L.t('order_settings'),
                      subtitle: L.t('configure_order_handling'),
                      child: Column(
                        children: [
                          _fieldBlock(
                            title: L.t('default_prep_time_title'),
                            description: L.t('default_prep_time_desc'),
                            ctrl: _prepTimeCtrl,
                            keyboardType: TextInputType.number,
                            suffix: L.t('minutes'),
                          ),
                          const SizedBox(height: 12),
                          _switchRow(
                            title: L.t('auto_accept_orders'),
                            subtitle: L.t('auto_accept_orders_desc'),
                            value: _settings.autoAcceptOrders,
                            onChanged: (v) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  autoAcceptOrders: v,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ================= Payment Methods =================
                  SettingsCard(
                    icon: Icons.credit_card,
                    title: L.t('payment_methods'),
                    subtitle: L.t('enable_or_disable_payments'),
                    child: Column(
                      children: [
                        _switchRow(
                          title: L.t('visa_master'),
                          subtitle: L.t('visa_master_desc'),
                          value: _settings.payVisaMaster,
                          onChanged: (v) => setState(
                            () => _settings = _settings.copyWith(
                              payVisaMaster: v,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _switchRow(
                          title: L.t('apple_pay'),
                          subtitle: L.t('apple_pay_desc'),
                          value: _settings.payApplePay,
                          onChanged: (v) => setState(
                            () =>
                                _settings = _settings.copyWith(payApplePay: v),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _switchRow(
                          title: L.t('google_pay'),
                          subtitle: L.t('google_pay_desc'),
                          value: _settings.payGooglePay,
                          onChanged: (v) => setState(
                            () =>
                                _settings = _settings.copyWith(payGooglePay: v),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _switchRow(
                          title: L.t('cash_on_delivery'),
                          subtitle: L.t('cash_on_delivery_desc'),
                          value: _settings.payCashOnDelivery,
                          onChanged: (v) => setState(
                            () => _settings = _settings.copyWith(
                              payCashOnDelivery: v,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ================= Social Media =================
                  SettingsCard(
                    icon: Icons.share,
                    title: L.t('social_media_settings'),
                    subtitle: L.t('enable_disable_social_links'),
                    child: Column(
                      children: [
                        // Instagram
                        _switchRow(
                          title: 'Instagram',
                          subtitle: L.t('enable_instagram'),
                          value: _settings.instagramEnabled,
                          onChanged: (v) async {
                            setState(() {
                              _settings = _settings.copyWith(
                                instagramEnabled: v,
                              );
                            });
                            await _updateSocialField({'instagram_enabled': v});
                          },
                        ),
                        if (_settings.instagramEnabled)
                          _textField(
                            ctrl: _instagramCtrl,
                            hint: 'https://instagram.com/yourpage',
                            onSubmitted: (_) async {
                              await _updateSocialField({
                                'instagram_url': _instagramCtrl.text.trim(),
                              });
                            },
                          ),

                        const SizedBox(height: 12),

                        // TikTok
                        _switchRow(
                          title: 'TikTok',
                          subtitle: L.t('enable_tiktok'),
                          value: _settings.tiktokEnabled,
                          onChanged: (v) async {
                            setState(() {
                              _settings = _settings.copyWith(tiktokEnabled: v);
                            });
                            await _updateSocialField({'tiktok_enabled': v});
                          },
                        ),
                        if (_settings.tiktokEnabled)
                          _textField(
                            ctrl: _tiktokCtrl,
                            hint: 'https://tiktok.com/@yourpage',
                            onSubmitted: (_) async {
                              await _updateSocialField({
                                'tiktok_url': _tiktokCtrl.text.trim(),
                              });
                            },
                          ),

                        const SizedBox(height: 12),

                        // Facebook
                        _switchRow(
                          title: 'Facebook',
                          subtitle: L.t('enable_facebook'),
                          value: _settings.facebookEnabled,
                          onChanged: (v) async {
                            setState(() {
                              _settings = _settings.copyWith(
                                facebookEnabled: v,
                              );
                            });
                            await _updateSocialField({'facebook_enabled': v});
                          },
                        ),
                        if (_settings.facebookEnabled)
                          _textField(
                            ctrl: _facebookCtrl,
                            hint: 'https://facebook.com/yourpage',
                            onSubmitted: (_) async {
                              await _updateSocialField({
                                'facebook_url': _facebookCtrl.text.trim(),
                              });
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
