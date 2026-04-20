import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/l.dart';
import '../../theme/app_colors.dart';
import 'login_signup_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;

  // ✅ كل حقل لحاله
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool _isStrongPassword(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$',
    );
    return regex.hasMatch(password);
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (!_isStrongPassword(password)) {
      _showError(L.t('password_weak'));
      return;
    }

    if (password != confirm) {
      _showError(L.t('password_mismatch'));
      return;
    }

    setState(() => _loading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(L.t('password_updated'))));

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
        (_) => false,
      );
    } catch (e) {
      // ✅ لا نخفي الخطأ بالكامل
      debugPrint('UpdatePassword error: $e');
      _showError(L.t('error_general'));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ✅ مهم جداً – منع memory leak
  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(
      context,
    ).textTheme.bodySmall?.color?.withValues(alpha: 0.7);
    final primaryColor = AppColors.primary(context);

    // التحقق المباشر لتفعيل الزر
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final isValid = _isStrongPassword(password) && password == confirm && password.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(L.t('reset_password'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔐 Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: L.t('new_password'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔐 Confirm Password
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: L.t('confirm_password'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "${L.t('password_policy_full')}\n"
                "${L.t('password_min_chars')}\n"
                "${L.t('password_upper_lower')}\n"
                "${L.t('password_number')}\n"
                "${L.t('password_special')}",
                style: TextStyle(fontSize: 12, color: textColor),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_loading || !isValid) ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isValid ? primaryColor : Colors.grey.withOpacity(0.3),
                    foregroundColor: isValid ? Colors.black : Colors.white54,
                    elevation: isValid ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                        )
                      : Text(
                          L.t('confirm'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
