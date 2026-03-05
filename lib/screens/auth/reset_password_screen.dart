import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/l.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(L.t('reset_password'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 🔐 Password
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: L.t('new_password'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
              decoration: InputDecoration(
                labelText: L.t('confirm_password'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(L.t('confirm')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
