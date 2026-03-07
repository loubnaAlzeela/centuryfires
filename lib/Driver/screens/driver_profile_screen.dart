import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../theme/theme_controller.dart';
import '../../utils/l.dart';
import '../../utils/language_controller.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final supabase = Supabase.instance.client;

  bool loading = true;

  String userId = '';
  String driverName = '';
  String driverEmail = '';
  String driverPhone = '';

  String vehicleType = '';
  String plateNumber = '';

  String currentLanguageLabel = 'English';
  String currentThemeLabel = 'System';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final session = supabase.auth.currentSession;
    if (session == null) return;

    setState(() => loading = true);

    final userRes = await supabase
        .from('users')
        .select('id, name, email, phone')
        .eq('auth_id', session.user.id)
        .single();

    userId = userRes['id'].toString();
    driverName = (userRes['name'] ?? '').toString();
    driverEmail = (userRes['email'] ?? '').toString();
    driverPhone = (userRes['phone'] ?? '').toString();

    final driverRes = await supabase
        .from('driver_profiles')
        .select('vehicle_type, plate_number')
        .eq('id', userId)
        .single();

    vehicleType = (driverRes['vehicle_type'] ?? '').toString();
    plateNumber = (driverRes['plate_number'] ?? '').toString();

    if (!mounted) return;
    setState(() => loading = false);
  }

  // ================== USERS UPDATES ==================
  Future<void> _updateUserField(String field, String value) async {
    final session = supabase.auth.currentSession;
    if (session == null) return;

    debugPrint('🔄 Updating $field = $value for auth_id: ${session.user.id}');

    final res = await supabase
        .from('users')
        .update({field: value})
        .eq('auth_id', session.user.id)
        .select(); // ← أضيفي select()

    debugPrint('✅ Update response: $res');

    await _loadProfile();
    debugPrint('👤 After reload, driverName = $driverName');
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: driverName);
    await _editDialog(
      title: L.t('edit_name'),
      controller: controller,
      onSave: () async {
        await _updateUserField('name', controller.text.trim());
      },
    );
  }

  Future<void> _editPhone() async {
    final controller = TextEditingController(text: driverPhone);
    await _editDialog(
      title: L.t('edit_phone'),
      controller: controller,
      onSave: () async {
        await _updateUserField('phone', controller.text.trim());
      },
    );
  }

  Future<void> _editEmail() async {
    final controller = TextEditingController(text: driverEmail);

    await _editDialog(
      title: L.t('edit_email'),
      controller: controller,
      onSave: () async {
        final newEmail = controller.text.trim();

        // 1) update auth email
        await supabase.auth.updateUser(UserAttributes(email: newEmail));

        // 2) (اختياري) خزّني نفس الإيميل بجدول users كمان
        await _updateUserField('email', newEmail);
      },
    );
  }

  // ================== DRIVER PROFILE UPDATES ==================
  Future<void> _updateDriverField(String field, String value) async {
    if (userId.isEmpty) return;

    await supabase
        .from('driver_profiles')
        .update({field: value})
        .eq('id', userId);

    await _loadProfile();
  }

  Future<void> _editVehicle() async {
    final controller = TextEditingController(text: vehicleType);
    await _editDialog(
      title: L.t('edit_vehicle'),
      controller: controller,
      onSave: () async {
        await _updateDriverField('vehicle_type', controller.text.trim());
      },
    );
  }

  Future<void> _editPlate() async {
    final controller = TextEditingController(text: plateNumber);
    await _editDialog(
      title: L.t('edit_plate'),
      controller: controller,
      onSave: () async {
        await _updateDriverField('plate_number', controller.text.trim());
      },
    );
  }

  // ================== DIALOG ==================
  Future<void> _editDialog({
    required String title,
    required TextEditingController controller,
    required Future<void> Function() onSave,
  }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card(context),
        title: Text(title, style: TextStyle(color: AppColors.text(context))),
        content: TextField(
          controller: controller,
          style: TextStyle(color: AppColors.text(context)),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.textGrey(context).withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary(context)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(L.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // سكّر فوراً

              try {
                await onSave();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary(context),
              foregroundColor: AppColors.textOnPrimary(context),
            ),
            child: Text(L.t('save')),
          ),
        ],
      ),
    );
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    final bg = AppColors.bg(context);

    if (loading) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary(context)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _profileHeader(context),
            _cardWrapper(
              context,
              children: [
                _editableField(
                  context,
                  label: L.t('name'),
                  value: driverName,
                  onTap: _editName,
                ),
                _divider(context),
                _editableField(
                  context,
                  label: L.t('email'),
                  value: driverEmail,
                  onTap: _editEmail,
                ),
                _divider(context),
                _editableField(
                  context,
                  label: L.t('phone'),
                  value: driverPhone,
                  onTap: _editPhone,
                ),
              ],
            ),
            _cardWrapper(
              context,
              children: [
                _actionTile(
                  context,
                  icon: Icons.language,
                  title: L.t('language'),
                  trailing: currentLanguageLabel,
                  onTap: () => _changeLanguage(),
                ),
                _divider(context),
                _actionTile(
                  context,
                  icon: Icons.dark_mode_outlined,
                  title: L.t('theme'),
                  trailing: currentThemeLabel,
                  onTap: () => _changeTheme(),
                ),
              ],
            ),
            _cardWrapper(
              context,
              children: [
                _editableField(
                  context,
                  label: L.t('vehicle_type'),
                  value: vehicleType,
                  onTap: _editVehicle,
                ),
                _divider(context),
                _editableField(
                  context,
                  label: L.t('plate_number'),
                  value: plateNumber,
                  onTap: _editPlate,
                ),
              ],
            ),
            _logoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader(BuildContext context) {
    final primary = AppColors.primary(context);
    final bg = AppColors.bg(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.85)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: bg.withValues(alpha: 0.2),
            child: Text(
              driverName.isNotEmpty ? driverName[0].toUpperCase() : '',
              style: TextStyle(
                color: AppColors.textOnPrimary(context),
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            driverName,
            style: TextStyle(
              color: AppColors.textOnPrimary(context),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            vehicleType,
            style: TextStyle(
              color: AppColors.textOnPrimary(context).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error(context),
            foregroundColor: AppColors.textOnPrimary(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          onPressed: () async {
            await supabase.auth.signOut();
          },
          child: Text(
            L.t('logout'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _cardWrapper(BuildContext context, {required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      color: AppColors.textGrey(context).withValues(alpha: 0.2),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary(context)),
      title: Text(title, style: TextStyle(color: AppColors.text(context))),
      trailing: Text(
        trailing,
        style: TextStyle(
          color: AppColors.text(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _editableField(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      title: Text(label, style: TextStyle(color: AppColors.text(context))),
      subtitle: Text(
        value,
        style: TextStyle(color: AppColors.textGrey(context)),
      ),
      trailing: Icon(Icons.edit_outlined, color: AppColors.primary(context)),
    );
  }

  Future<void> _changeLanguage() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<bool>(
          valueListenable: LanguageController.isArabic,
          builder: (context, isArabic, _) {
            return Container(
              color: AppColors.card(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('English'),
                    trailing: !isArabic ? const Icon(Icons.check) : null,
                    onTap: () async {
                      await LanguageController.setArabic(false);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('العربية'),
                    trailing: isArabic ? const Icon(Icons.check) : null,
                    onTap: () async {
                      await LanguageController.setArabic(true);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _changeTheme() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.themeMode,
          builder: (context, mode, _) {
            return Container(
              color: AppColors.card(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Light'),
                    trailing: mode == ThemeMode.light
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () async {
                      await ThemeController.toggle(false);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Dark'),
                    trailing: mode == ThemeMode.dark
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () async {
                      await ThemeController.toggle(true);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
