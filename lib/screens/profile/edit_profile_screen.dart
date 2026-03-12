import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../utils/l.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final supabase = Supabase.instance.client;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  bool isLoading = true;
  bool updatingName = false;
  bool updatingPhone = false;
  bool updatingEmail = false;
  bool updatingPassword = false;
  bool _hasUpdated = false;
  List<String> preferredContacts = ['phone'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ================= LOAD =================
  Future<void> _loadUserData() async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) {
        setState(() => isLoading = false);
        return;
      }

      emailCtrl.text = authUser.email ?? '';

      final data = await supabase
          .from('users')
          .select('name, phone, preferred_contact')
          .eq('auth_id', authUser.id)
          .single();

      nameCtrl.text = data['name'] ?? '';
      phoneCtrl.text = data['phone'] ?? '';
      preferredContacts = (data['preferred_contact'] ?? 'phone')
          .toString()
          .split(',')
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(L.t('err_load_profile'))));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= UPDATE NAME =================
  Future<void> _updateName() async {
    setState(() => updatingName = true);
    try {
      final authUser = supabase.auth.currentUser;
      await supabase
          .from('users')
          .update({'name': nameCtrl.text})
          .eq('auth_id', authUser!.id);
      _hasUpdated = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L.t('updated_successfully')),
            backgroundColor: AppColors.primary(context),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => updatingName = false);
    }
  }

  // ================= UPDATE PHONE =================
  Future<void> _updatePhone() async {
    setState(() => updatingPhone = true);
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) {
        throw Exception('Not logged in');
      }
      final phoneVal = phoneCtrl.text.trim();

      debugPrint('Updating phone: $phoneVal for auth_id: ${authUser.id}');

      final result = await supabase
          .from('users')
          .update({'phone': phoneVal.isEmpty ? null : phoneVal})
          .eq('auth_id', authUser.id)
          .select('id, phone');

      debugPrint('Phone update result: $result');

      _hasUpdated = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L.t('updated_successfully')),
            backgroundColor: AppColors.primary(context),
          ),
        );
      }
    } catch (e) {
      debugPrint('Phone update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${L.t('error')}: $e'),
            backgroundColor: AppColors.error(context),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => updatingPhone = false);
    }
  }

  //==========================================
  /*  Future<void> _updateProfile() async {
    setState(() => updatingName = true);

    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) return;

      await supabase
          .from('users')
          .update({
            'name': nameCtrl.text,
            'phone': phoneCtrl.text,
            'preferred_contact': preferredContact,
          })
          .eq('auth_id', authUser.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L.t('updated_successfully')),
          backgroundColor: AppColors.primary(context),
        ),
      );
    } finally {
      if (mounted) setState(() => updatingName = false);
    }
  }*/

  // ================= UPDATE EMAIL =================
  Future<void> _updateEmail() async {
    setState(() => updatingEmail = true);

    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) return;

      if (emailCtrl.text != authUser.email) {
        await supabase.auth.updateUser(UserAttributes(email: emailCtrl.text));

        await supabase
            .from('users')
            .update({'email': emailCtrl.text})
            .eq('auth_id', authUser.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L.t('email_verification_sent')),
              backgroundColor: AppColors.primary(context),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L.t('err_update_email')),
            backgroundColor: AppColors.error(context),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => updatingEmail = false);
    }
  }

  // ================= UPDATE PASSWORD =================
  Future<void> _updatePassword() async {
    if (passwordCtrl.text.length < 6) return;
    if (passwordCtrl.text != confirmPasswordCtrl.text) return;

    setState(() => updatingPassword = true);

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: passwordCtrl.text),
      );

      passwordCtrl.clear();
      confirmPasswordCtrl.clear();
    } finally {
      if (mounted) setState(() => updatingPassword = false);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, _hasUpdated);
          },
        ),
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        title: Text(L.t('edit_profile')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// NAME
            _editableField(
              label: L.t('full_name'),
              controller: nameCtrl,
              onSave: _updateName,
              loading: updatingName,
            ),

            /// PHONE
            _editableField(
              label: L.t('phone'),
              controller: phoneCtrl,
              keyboard: TextInputType.phone,
              onSave: _updatePhone,
              loading: updatingPhone,
            ),
            const SizedBox(height: 20),

            /// 🔥 PREFERRED CONTACT
            _preferredContactSection(),
            const SizedBox(height: 20),

            /// EMAIL
            _editableField(
              label: L.t('email'),
              controller: emailCtrl,
              keyboard: TextInputType.emailAddress,
              onSave: _updateEmail,
              loading: updatingEmail,
            ),

            const SizedBox(height: 30),

            /// PASSWORD SECTION
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                L.t('change_password'),
                style: TextStyle(
                  color: AppColors.text(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            _passwordField(L.t('new_password'), passwordCtrl),
            const SizedBox(height: 12),
            _passwordField(L.t('confirm_password'), confirmPasswordCtrl),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: updatingPassword ? null : _updatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: updatingPassword
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      L.t('change_password'),
                      style: TextStyle(color: AppColors.textOnPrimary(context)),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= FIELD WITH ICON SAVE =================
  Widget _editableField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onSave,
    required bool loading,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textGrey(context), fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.card(context),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 12,
              ),
              suffixIcon: loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        Icons.check_circle,
                        color: AppColors.primary(context),
                      ),
                      onPressed: onSave,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.card(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _preferredContactSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.t('preferred_contact'),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 14),

          _contactOption('phone', Icons.phone, L.t('phone_call')),
          const SizedBox(height: 8),
          _contactOption('whatsapp', Icons.chat, L.t('whatsapp')),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _contactOption(String value, IconData icon, String label) {
    final isSelected = preferredContacts.contains(value);

    return InkWell(
      onTap: () async {
        setState(() {
          if (preferredContacts.contains(value)) {
            preferredContacts.remove(value);
          } else {
            preferredContacts.add(value);
          }
        });

        final authUser = supabase.auth.currentUser;
        if (authUser == null) return;

        try {
          await supabase
              .from('users')
              .update({'preferred_contact': preferredContacts.join(',')})
              .eq('auth_id', authUser.id);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${L.t('error')}: $e'),
                backgroundColor: AppColors.error(context),
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary(context).withValues(alpha: .15)
              : AppColors.bg(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary(context)
                : AppColors.textHint(context).withValues(alpha: .3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary(context)
                  : AppColors.text(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.text(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary(context),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
