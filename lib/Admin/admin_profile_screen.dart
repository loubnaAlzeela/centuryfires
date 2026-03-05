import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../utils/l.dart';
import '../utils/language_controller.dart';
import '../theme/theme_controller.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final supabase = Supabase.instance.client;

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();

  // ✅ FIX 1: إنشاء controller ثابت للباسورد مع dispose صحيح بدلاً من إنشائه داخل build
  final passwordCtrl = TextEditingController(text: '••••••••');

  bool isLoading = true;

  String selectedLanguage = LanguageController.ar ? 'ar' : 'en';
  String selectedTheme = ThemeController.themeMode.value == ThemeMode.dark
      ? 'dark'
      : 'light';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  // ✅ FIX 2: dispose جميع controllers لتجنب memory leak
  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final res = await supabase
          .from('users')
          .select('name')
          .eq('auth_id', user.id)
          .maybeSingle();

      // ✅ FIX 3: التحقق من mounted قبل setState بعد عملية async
      if (!mounted) return;

      nameCtrl.text = res?['name'] ?? '';
      emailCtrl.text = user.email ?? '';

      setState(() => isLoading = false);
    } catch (e) {
      // ✅ FIX 3: التحقق من mounted قبل setState في catch أيضاً
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card(context),
          title: Text(L.t('change_password')),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(hintText: L.t('enter_new_password')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(L.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPassword = controller.text.trim();
                if (newPassword.length < 6) return;

                try {
                  await supabase.auth.updateUser(
                    UserAttributes(password: newPassword),
                  );
                } catch (e) {
                  debugPrint('Password update error: $e');
                }

                // ✅ FIX 4: التحقق من mounted قبل استخدام context بعد async
                if (!mounted) return;

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(L.t('password_updated')),
                    backgroundColor: AppColors.primary(context),
                  ),
                );
              },
              child: Text(L.t('save')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeEmail() async {
    final controller = TextEditingController(text: emailCtrl.text);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card(context),
          title: Text(L.t('change_email')),
          content: TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: InputDecoration(
              hintText: L.t('enter_new_email'),
              filled: true,
              fillColor: AppColors.bg(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
                final newEmail = controller.text.trim();
                if (newEmail.isEmpty) return;

                try {
                  final currentUser = supabase.auth.currentUser;
                  if (currentUser == null) return;

                  await supabase.auth.refreshSession();

                  final response = await supabase.auth.updateUser(
                    UserAttributes(email: newEmail),
                  );

                  debugPrint('Updated email: ${response.user?.email}');

                  // ✅ FIX 5: إغلاق الـ dialog أولاً، ثم setState بعد التحقق من mounted
                  if (!mounted) return;
                  Navigator.pop(dialogContext);

                  setState(() {
                    emailCtrl.text = newEmail;
                  });
                } catch (e) {
                  debugPrint('Email update error: $e');

                  // ✅ FIX 5: التحقق من mounted قبل إظهار رسالة الخطأ
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(L.t('error_updating_email')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(L.t('save')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveName() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final newName = nameCtrl.text.trim();
    if (newName.isEmpty) return;

    try {
      await supabase
          .from('users')
          .update({'name': newName})
          .eq('auth_id', user.id);

      // ✅ FIX 4: التحقق من mounted قبل استخدام context بعد async
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L.t('name_updated')),
          backgroundColor: AppColors.primary(context),
        ),
      );
    } catch (e) {
      debugPrint('Name update error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary(context)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            _profileHeader(context),

            const SizedBox(height: 28),

            /// ACCOUNT
            _sectionTitle(L.t('account_information')),
            const SizedBox(height: 12),
            _card(
              context,
              Column(
                children: [
                  // ===== FULL NAME =====
                  _inputField(
                    L.t('full_name'),
                    nameCtrl,
                    suffix: IconButton(
                      icon: Icon(
                        Icons.check_circle,
                        color: AppColors.primary(context),
                      ),
                      onPressed: _saveName,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ===== EMAIL =====
                  _inputField(
                    L.t('email'),
                    emailCtrl,
                    readOnly: true,
                    suffix: IconButton(
                      icon: Icon(Icons.edit, color: AppColors.primary(context)),
                      onPressed: _changeEmail,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ===== PASSWORD =====
                  // ✅ FIX 1: استخدام passwordCtrl الثابت بدلاً من إنشاء controller جديد في كل build
                  _inputField(
                    L.t('password'),
                    passwordCtrl,
                    readOnly: true,
                    suffix: IconButton(
                      icon: Icon(
                        Icons.lock_reset,
                        color: AppColors.primary(context),
                      ),
                      onPressed: _changePassword,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            /// PREFERENCES
            _sectionTitle(L.t('preferences')),
            const SizedBox(height: 12),
            _card(
              context,
              Column(
                children: [
                  _dropdown(
                    context,
                    label: L.t('language'),
                    value: selectedLanguage,
                    items: const {'ar': 'Arabic', 'en': 'English'},
                    onChanged: (val) async {
                      setState(() => selectedLanguage = val);
                      await LanguageController.setArabic(val == 'ar');
                    },
                  ),
                  const SizedBox(height: 18),
                  _dropdown(
                    context,
                    label: L.t('theme'),
                    value: selectedTheme,
                    items: const {'dark': 'Dark', 'light': 'Light'},
                    onChanged: (val) async {
                      setState(() => selectedTheme = val);
                      await ThemeController.toggle(val == 'dark');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= UI =================

  Widget _profileHeader(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              // ✅ FIX 6: استبدال withValues(alpha:) بـ withOpacity() الصحيحة
              color: AppColors.primary(context).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 46,
              color: AppColors.primary(context),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            L.t('administrator'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            L.t('manage_account_settings'),
            style: TextStyle(color: AppColors.textGrey(context)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.text(context),
      ),
    );
  }

  Widget _card(BuildContext context, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            // ✅ FIX 6: استبدال withValues(alpha:) بـ withOpacity() الصحيحة
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _inputField(
    String label,
    TextEditingController ctrl, {
    bool readOnly = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.bg(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _dropdown(
    BuildContext context, {
    required String label,
    required String value,
    required Map<String, String> items,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.text(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.bg(context),
            borderRadius: BorderRadius.circular(14),
            // ✅ FIX 7: إضافة border لتوحيد شكل الـ dropdown مع الـ input fields
            border: Border.all(
              color: AppColors.textGrey(context).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: AppColors.card(context),
            items: items.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ),
      ],
    );
  }
}
