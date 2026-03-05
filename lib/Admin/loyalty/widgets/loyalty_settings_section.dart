import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/l.dart';

class LoyaltySettingsSection extends StatefulWidget {
  final VoidCallback? onUpdated;

  const LoyaltySettingsSection({super.key, this.onUpdated});

  @override
  State<LoyaltySettingsSection> createState() => _LoyaltySettingsSectionState();
}

class _LoyaltySettingsSectionState extends State<LoyaltySettingsSection> {
  final _supabase = Supabase.instance.client;

  final currencyStepCtrl = TextEditingController();
  final basePointsCtrl = TextEditingController();

  bool birthdayEnabled = false;

  bool _loading = false;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    currencyStepCtrl.dispose();
    basePointsCtrl.dispose();
    super.dispose();
  }

  // ========================= LOAD =========================

  Future<void> _load() async {
    try {
      final data = await _supabase
          .from('loyalty_settings')
          .select()
          .eq('is_active', true)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          currencyStepCtrl.text = (data['currency_step'] ?? '').toString();
          basePointsCtrl.text = (data['base_points'] ?? '').toString();
          birthdayEnabled = data['birthday_bonus_enabled'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('_load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(L.t('error_general'))));
      }
    } finally {
      if (mounted) {
        setState(() => _initialLoading = false);
      }
    }
  }

  // ========================= SAVE =========================

  Future<void> _save() async {
    final currencyStep = int.tryParse(currencyStepCtrl.text);
    final basePoints = int.tryParse(basePointsCtrl.text);

    if (currencyStep == null || currencyStep <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(L.t('invalid_currency_step'))));
      return;
    }

    if (basePoints == null || basePoints <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(L.t('invalid_base_points'))));
      return;
    }

    setState(() => _loading = true);

    try {
      await _supabase
          .from('loyalty_settings')
          .update({
            'currency_step': currencyStep,
            'base_points': basePoints,
            'birthday_bonus_enabled': birthdayEnabled,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('is_active', true);

      widget.onUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(L.t('saved_successfully'))));
      }
    } catch (e) {
      debugPrint('_save error: $e');

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

  // ========================= UI =========================

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary(context)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.t('points_settings'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 24),

          /// Currency Step
          TextField(
            controller: currencyStepCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(color: AppColors.text(context)),
            decoration: InputDecoration(
              labelText: L.t('currency_step'),
              labelStyle: TextStyle(color: AppColors.textGrey(context)),
              filled: true,
              fillColor: AppColors.bg(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// Base Points
          TextField(
            controller: basePointsCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(color: AppColors.text(context)),
            decoration: InputDecoration(
              labelText: L.t('base_points'),
              labelStyle: TextStyle(color: AppColors.textGrey(context)),
              filled: true,
              fillColor: AppColors.bg(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// Birthday Switch
          SwitchListTile(
            value: birthdayEnabled,
            activeThumbColor: AppColors.primary(context),
            onChanged: (v) => setState(() => birthdayEnabled = v),
            title: Text(
              L.t('birthday_bonus_enabled'),
              style: TextStyle(color: AppColors.text(context)),
            ),
          ),

          const SizedBox(height: 24),

          /// Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
              ),
              onPressed: _loading ? null : _save,
              child: _loading
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary(context),
                      ),
                    )
                  : Text(
                      L.t('save'),
                      style: TextStyle(color: AppColors.textOnPrimary(context)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
