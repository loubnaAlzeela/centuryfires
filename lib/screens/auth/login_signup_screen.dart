import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../utils/l.dart';
import 'dart:async';
import '../../main.dart';

enum AppMessageType { error, success, info }

enum _InputType { empty, email, phone }

// ── Widget مساعد: ظهور ناعم من الأسفل ──
class _FadeSlide extends StatefulWidget {
  final Widget child;
  final bool visible;
  const _FadeSlide({required this.child, required this.visible});

  @override
  State<_FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<_FadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    if (widget.visible) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_FadeSlide old) {
    super.didUpdateWidget(old);
    if (widget.visible != old.visible) {
      widget.visible ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        if (_ctrl.value == 0.0) return const SizedBox.shrink();
        return FadeTransition(
          opacity: _fade,
          child: SlideTransition(position: _slide, child: widget.child),
        );
      },
    );
  }
}

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  bool isLogin = true;
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _resetLoading = false;

  // OTP state
  bool _otpSent = false;
  bool _otpLoading = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  // كشف ذكي
  bool _secondFieldVisible = false;
  bool _phoneFieldVisible = false;
  Timer? _debounceTimer;

  // Controllers
  final _identifierCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  // FocusNodes
  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();

  late final StreamSubscription<AuthState> _authSub;

  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final _phoneRegex = RegExp(r'^\+[1-9]\d{7,14}$');

  _InputType get _inputType {
    final val = _identifierCtrl.text.trim();
    if (val.isEmpty) return _InputType.empty;
    if (val.startsWith('+') || RegExp(r'^\d').hasMatch(val)) {
      return _InputType.phone;
    }
    return _InputType.email;
  }

  bool get _isPhone => _inputType == _InputType.phone;
  bool get _isEmail => _inputType == _InputType.email;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _identifierCtrl.addListener(_onIdentifierChanged);

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final event = data.event;
      final session = data.session;

      if (session == null) return;
      if (event != AuthChangeEvent.signedIn &&
          event != AuthChangeEvent.tokenRefreshed) {
        return;
      }

      final supabase = Supabase.instance.client;

      int retries = 0;
      while (supabase.auth.currentUser == null && retries < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        retries++;
      }

      final user = supabase.auth.currentUser;
      debugPrint(
        'AUTH CHANGE [$event]: user=${user?.id} phone=${user?.phone} email=${user?.email}',
      );

      if (user == null) {
        debugPrint('AUTH CHANGE: currentUser still null after retries!');
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const InitialScreen()),
          (_) => false,
        );
        return;
      }

      if (event == AuthChangeEvent.signedIn) {
        try {
          final phone = _identifierCtrl.text.trim().startsWith('+')
              ? _identifierCtrl.text.trim()
              : (user.phone?.isNotEmpty == true
                    ? user.phone!
                    : _phoneCtrl.text.trim());

          final email = user.email ?? session.user.email ?? '';

          debugPrint(
            'ENSURE USER CALL: phone=$phone email=$email name=${_nameCtrl.text.trim()}',
          );

          await _ensureUserRow(
            supabase: supabase,
            email: email,
            name: _nameCtrl.text.trim(),
            phone: phone,
          );
        } catch (e) {
          debugPrint('ENSURE USER error: $e');
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const InitialScreen()),
        (_) => false,
      );
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
        );
    _fadeController.forward();
  }

  void _onIdentifierChanged() {
    setState(() {});
    _debounceTimer?.cancel();

    final type = _inputType;
    if (type == _InputType.empty) {
      if (_secondFieldVisible || _phoneFieldVisible) {
        setState(() {
          _secondFieldVisible = false;
          _phoneFieldVisible = false;
        });
      }
      return;
    }

    final val = _identifierCtrl.text.trim();
    final isReadyEmail =
        type == _InputType.email && val.contains('@') && val.contains('.');
    final isReadyPhone = type == _InputType.phone && _phoneRegex.hasMatch(val);

    if (isReadyEmail || isReadyPhone) {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() => _secondFieldVisible = true);
        Future.delayed(const Duration(milliseconds: 350), () {
          if (!mounted) return;
          if (_isEmail) FocusScope.of(context).requestFocus(_passwordFocus);
        });
        Future.delayed(const Duration(milliseconds: 650), () {
          if (!mounted) return;
          if (_isEmail && !isLogin) setState(() => _phoneFieldVisible = true);
        });
      });
    } else {
      if (_secondFieldVisible || _phoneFieldVisible) {
        setState(() {
          _secondFieldVisible = false;
          _phoneFieldVisible = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _identifierCtrl.removeListener(_onIdentifierChanged);
    _identifierCtrl.dispose();
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    _resendTimer?.cancel();
    _debounceTimer?.cancel();
    _authSub.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════════════════
  // MAIN AUTH HANDLER
  // ══════════════════════════════════════════════════
  Future<void> _handleAuth() async {
    if (isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    if (_isPhone) {
      _otpSent ? await _verifyPhoneOtp() : await _sendPhoneOtp();
      return;
    }

    setState(() => isLoading = true);
    final supabase = Supabase.instance.client;
    final email = _identifierCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    try {
      if (isLogin) {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        try {
          await supabase.auth.signUp(email: email, password: password);
          try {
            await supabase.auth.signInWithPassword(
              email: email,
              password: password,
            );
          } on AuthException catch (e) {
            if (_isEmailNotConfirmed(e)) {
              if (!mounted) return;
              setState(() => isLoading = false);
              _showErrorMessage(L.t('err_email_not_confirmed'));
              return;
            }
            rethrow;
          }
        } on AuthException catch (e) {
          if (_isUserAlreadyExists(e)) {
            if (!mounted) return;
            setState(() {
              isLoading = false;
              isLogin = true;
            });
            _showErrorMessage(L.t('err_user_exists'));
            return;
          }
          rethrow;
        }
      }
    } on PostgrestException catch (e) {
      if (mounted) setState(() => isLoading = false);
      _showErrorMessage('DB ERROR: ${e.message}');
    } on AuthException catch (e) {
      if (mounted) setState(() => isLoading = false);
      _showErrorMessage(_mapAuthError(e));
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      _showErrorMessage('ERR: $e');
    }
  }

  // ══════════════════════════════════════════════════
  // PHONE OTP — Supabase + Vonage (بدون Firebase)
  // ══════════════════════════════════════════════════
  Future<void> _sendPhoneOtp() async {
    final phone = _identifierCtrl.text.trim();
    debugPrint('=== SEND OTP START === PHONE=$phone');
    setState(() => _otpLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: phone);

      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _otpLoading = false;
        _secondFieldVisible = false;
      });

      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        setState(() => _secondFieldVisible = true);
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) FocusScope.of(context).requestFocus(_otpFocus);
        });
      });

      _startResendCountdown();
      _showNiceMessage(
        type: AppMessageType.success,
        title: L.t('otp_sent_title'),
        message: L.t('otp_sent_message'),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _otpLoading = false);
      _showErrorMessage(_mapAuthError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _otpLoading = false);
      _showErrorMessage('ERR: $e');
      debugPrint('OTP Error: $e');
    }
  }

  Future<void> _verifyPhoneOtp() async {
    final phone = _identifierCtrl.text.trim();
    final otp = _otpCtrl.text.trim();

    if (otp.length < 4) {
      _showErrorMessage(L.t('otp_too_short'));
      return;
    }

    setState(() => isLoading = true);

    try {
      await Supabase.instance.client.auth.verifyOTP(
        phone: phone,
        token: otp,
        type: OtpType.sms,
      );
      // onAuthStateChange listener will handle navigation
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showErrorMessage(_mapAuthError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showErrorMessage('ERR: $e');
    }
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _resendCountdown > 0 ? _resendCountdown-- : t.cancel());
    });
  }

  // ══════════════════════════════════════════════════
  // FORGOT PASSWORD
  // ══════════════════════════════════════════════════
  Future<void> _forgotPassword() async {
    if (_resetLoading) return;
    final email = _identifierCtrl.text.trim();
    if (!_emailRegex.hasMatch(email)) {
      _showErrorMessage(L.t('email_invalid'));
      return;
    }
    setState(() => _resetLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://poetic-creponne-e07173.netlify.app',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L.t('reset_link_sent')),
          backgroundColor: Colors.green,
        ),
      );
    } on AuthException {
      _showErrorMessage(L.t('err_reset_failed'));
    } finally {
      if (mounted) setState(() => _resetLoading = false);
    }
  }

  // ══════════════════════════════════════════════════
  // ENSURE USER ROW
  // ══════════════════════════════════════════════════
  Future<void> _ensureUserRow({
    required SupabaseClient supabase,
    required String email,
    required String name,
    required String phone,
  }) async {
    int attempt = 0;
    while (supabase.auth.currentUser == null && attempt < 8) {
      await Future.delayed(const Duration(milliseconds: 250));
      attempt++;
    }

    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      debugPrint('ENSURE USER: skipped (authUser is null)');
      return;
    }

    final authId = authUser.id;

    final finalPhone = phone.trim().isNotEmpty
        ? phone.trim()
        : (authUser.phone ?? '').trim();

    String finalEmail = email.trim().isNotEmpty
        ? email.trim()
        : (authUser.email ?? '').trim();

    if (finalPhone.isEmpty && finalEmail.isEmpty) {
      debugPrint('ENSURE USER: skipped (no phone/email)');
      return;
    }

    debugPrint(
      'ENSURE USER: authId=$authId email=$finalEmail phone=$finalPhone',
    );

    final existing = await supabase
        .from('users')
        .select('id, phone, email, name')
        .eq('auth_id', authId)
        .maybeSingle();

    if (existing != null) {
      final Map<String, dynamic> updateData = {'is_active': true};
      if (finalPhone.isNotEmpty) updateData['phone'] = finalPhone;
      if (finalEmail.isNotEmpty) updateData['email'] = finalEmail;
      if (name.trim().isNotEmpty) updateData['name'] = name.trim();

      await supabase.from('users').update(updateData).eq('auth_id', authId);
      debugPrint('ENSURE USER: updated existing user row ✅');
      return;
    }

    final insertName = name.trim().isNotEmpty ? name.trim() : 'Customer';

    await supabase.from('users').insert({
      'auth_id': authId,
      'name': insertName,
      'phone': finalPhone.isEmpty ? null : finalPhone,
      'email': finalEmail.isEmpty ? null : finalEmail,
      'role': 'customer',
      'is_active': true,
    });

    debugPrint('ENSURE USER: inserted new user row ✅');
  }

  // ══════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════
  bool _isUserAlreadyExists(AuthException e) {
    final msg = e.message.toLowerCase();
    return msg.contains('already registered') ||
        msg.contains('already exists') ||
        msg.contains('user already') ||
        (msg.contains('already') && msg.contains('registered'));
  }

  bool _isEmailNotConfirmed(AuthException e) {
    final msg = e.message.toLowerCase();
    return msg.contains('confirm') || msg.contains('not confirmed');
  }

  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (_isUserAlreadyExists(e)) return L.t('err_user_exists');
    if (msg.contains('invalid login') || msg.contains('invalid_credentials')) {
      return L.t('err_invalid_credentials');
    }
    if (_isEmailNotConfirmed(e)) {
      return _isPhone
          ? L.t('err_phone_provider_disabled')
          : L.t('err_email_not_confirmed');
    }
    if (msg.contains('phone') && msg.contains('not')) {
      return L.t('err_phone_provider_disabled');
    }
    if (msg.contains('otp') ||
        msg.contains('token') ||
        msg.contains('expired')) {
      return L.t('err_otp_invalid');
    }
    if (msg.contains('rate') || msg.contains('too many')) {
      return L.t('err_too_many_requests');
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return L.t('err_network');
    }
    return '${L.t('err_general')}: ${e.message}';
  }

  void _showErrorMessage(String msg) => _showNiceMessage(
    type: AppMessageType.error,
    title: L.t('error'),
    message: msg,
  );

  void _resetOtpState() {
    _otpSent = false;
    _secondFieldVisible = false;
    _phoneFieldVisible = false;
    _otpCtrl.clear();
    _phoneCtrl.clear();
    _resendTimer?.cancel();
    _debounceTimer?.cancel();
    _resendCountdown = 0;
  }

  // ══════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                Positioned(
                  top: -100,
                  right: -50,
                  child: _glowCircle(
                    300,
                    AppColors.primary(context).withOpacity(0.15),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: -80,
                  child: _glowCircle(
                    250,
                    AppColors.primary(context).withOpacity(0.10),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 32,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _logo(),
                          const SizedBox(height: 40),
                          _card(
                            child: Column(
                              children: [
                                _tabs(),
                                const SizedBox(height: 28),
                                _smartFields(),
                                if (isLogin && _isEmail)
                                  _forgotBtn()
                                else
                                  const SizedBox(height: 4),
                                _submitBtn(),
                                const SizedBox(height: 24),
                                _socialLogins(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          _switchMode(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // SMART FIELDS
  // ══════════════════════════════════════════════════
  Widget _smartFields() {
    final showPassword = _isEmail && _secondFieldVisible;
    final showPhoneField = _isEmail && !isLogin && _phoneFieldVisible;
    final showOtpField = _isPhone && _otpSent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FadeSlide(
          visible: !isLogin,
          child: !isLogin
              ? _inputField(
                  L.t('full_name'),
                  Icons.person_outline,
                  controller: _nameCtrl,
                  validator: (v) => v!.isEmpty ? L.t('name_required') : null,
                )
              : const SizedBox.shrink(),
        ),
        _smartIdentifierField(),
        _FadeSlide(
          visible: showPassword,
          child: _inputField(
            L.t('password'),
            Icons.lock_outline,
            controller: _passwordCtrl,
            focusNode: _passwordFocus,
            isPassword: true,
            validator: showPassword
                ? (v) => v!.length < 6 ? L.t('password_min') : null
                : null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textGrey(context),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        _FadeSlide(
          visible: showPhoneField,
          child: _inputField(
            L.t('phone_with_code'),
            Icons.phone_outlined,
            controller: _phoneCtrl,
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            validator: showPhoneField
                ? (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return L.t('phone_required');
                    if (!_phoneRegex.hasMatch(val))
                      return L.t('phone_invalid_format');
                    return null;
                  }
                : null,
          ),
        ),
        _FadeSlide(
          visible: showOtpField,
          child: Column(
            children: [
              _inputField(
                L.t('enter_otp'),
                Icons.pin_outlined,
                controller: _otpCtrl,
                focusNode: _otpFocus,
                keyboardType: TextInputType.number,
                validator: showOtpField
                    ? (v) => v!.length < 4 ? L.t('otp_too_short') : null
                    : null,
              ),
              if (showOtpField) _otpFooter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _smartIdentifierField() {
    final icon = _isPhone
        ? Icons.phone_outlined
        : Icons.alternate_email_rounded;
    final hint = _isPhone ? L.t('phone_with_code') : L.t('email_or_phone');

    final Color badgeColor;
    final IconData badgeIcon;
    final String badgeText;

    if (_isPhone) {
      badgeColor = Colors.green;
      badgeIcon = Icons.sms_outlined;
      badgeText = L.t('otp_will_be_sent');
    } else if (_isEmail) {
      badgeColor = AppColors.primary(context);
      badgeIcon = Icons.lock_outline;
      badgeText = L.t('password_required');
    } else {
      badgeColor = AppColors.textGrey(context);
      badgeIcon = Icons.help_outline;
      badgeText = L.t('type_to_detect');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextFormField(
            controller: _identifierCtrl,
            focusNode: _identifierFocus,
            readOnly: _otpSent,
            keyboardType: _isPhone
                ? TextInputType.phone
                : TextInputType.emailAddress,
            style: TextStyle(color: AppColors.text(context), fontSize: 15),
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) return L.t('field_required');
              if (_isPhone && !_phoneRegex.hasMatch(val))
                return L.t('phone_invalid_format');
              if (_isEmail && !_emailRegex.hasMatch(val))
                return L.t('email_invalid');
              return null;
            },
            decoration: InputDecoration(
              prefixIcon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey(icon),
                  color: AppColors.textGrey(context),
                ),
              ),
              suffixIcon: _otpSent
                  ? TextButton(
                      onPressed: () => setState(() => _resetOtpState()),
                      child: Text(
                        L.t('change'),
                        style: TextStyle(
                          color: AppColors.primary(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintStyle: TextStyle(
                color: AppColors.textGrey(context).withOpacity(0.7),
              ),
              filled: true,
              fillColor: _otpSent
                  ? AppColors.bg(context).withOpacity(0.3)
                  : AppColors.bg(context).withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.textGrey(context).withOpacity(0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.textGrey(context).withOpacity(0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.primary(context),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.error(context).withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.error(context),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          child: _inputType != _InputType.empty && !_otpSent
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 2, left: 4),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      key: ValueKey(_inputType),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 13, color: badgeColor),
                        const SizedBox(width: 5),
                        Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _otpFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 13,
                color: AppColors.textGrey(context),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${L.t('otp_sent_to')} ${_identifierCtrl.text.trim()}',
                  style: TextStyle(
                    color: AppColors.textGrey(context),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _resendCountdown > 0
                ? Text(
                    '${L.t('resend_in')} ${_resendCountdown}s',
                    style: TextStyle(
                      color: AppColors.textGrey(context),
                      fontSize: 12,
                    ),
                  )
                : GestureDetector(
                    onTap: _otpLoading ? null : _sendPhoneOtp,
                    child: Text(
                      L.t('resend_otp'),
                      style: TextStyle(
                        color: AppColors.primary(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // UI WIDGETS
  // ══════════════════════════════════════════════════
  Widget _glowCircle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [BoxShadow(color: color, blurRadius: 100)],
    ),
  );

  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: AppColors.card(context).withOpacity(0.95),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: AppColors.text(context).withOpacity(0.05),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
      border: Border.all(color: AppColors.textGrey(context).withOpacity(0.1)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
    child: child,
  );

  Widget _logo() => Column(
    children: [
      Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary(context).withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Image.asset('assets/images/branding/splash_logo.png'),
      ),
      const SizedBox(height: 20),
      Text(
        'CENTURY FRIES',
        style: TextStyle(
          color: AppColors.primary(context),
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    ],
  );

  Widget _tabs() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.bg(context),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: AppColors.textGrey(context).withOpacity(0.1)),
    ),
    child: Row(
      children: [
        _tabBtn(L.t('login'), isLogin, () {
          setState(() {
            isLogin = true;
            _resetOtpState();
          });
        }),
        _tabBtn(L.t('signup'), !isLogin, () {
          setState(() {
            isLogin = false;
            _resetOtpState();
            if (_isEmail && _secondFieldVisible) {
              Future.delayed(const Duration(milliseconds: 650), () {
                if (mounted && _isEmail)
                  setState(() => _phoneFieldVisible = true);
              });
            }
          });
        }),
      ],
    ),
  );

  Widget _tabBtn(String text, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary(context).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.black : AppColors.textGrey(context),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    ),
  );

  Widget _inputField(
    String hint,
    IconData icon, {
    TextEditingController? controller,
    FocusNode? focusNode,
    bool isPassword = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: validator,
      style: TextStyle(color: AppColors.text(context), fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textGrey(context)),
        suffixIcon: suffixIcon,
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(
          color: AppColors.textGrey(context).withOpacity(0.7),
        ),
        filled: true,
        fillColor: readOnly
            ? AppColors.bg(context).withOpacity(0.3)
            : AppColors.bg(context).withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.textGrey(context).withOpacity(0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.textGrey(context).withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary(context), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.error(context).withOpacity(0.5),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.error(context), width: 1.5),
        ),
      ),
    ),
  );

  Widget _forgotBtn() => Align(
    alignment: Alignment.centerRight,
    child: TextButton(
      onPressed: _resetLoading ? null : _forgotPassword,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textGrey(context),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: _resetLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              L.t('forgot_password'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
    ),
  );

  Widget _submitBtn() {
    final String btnText;
    if (_isPhone) {
      btnText = _otpSent ? L.t('verify_otp') : L.t('send_otp');
    } else {
      btnText = isLogin ? L.t('login_arrow') : L.t('create_account');
    }

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary(context).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary(context),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.black,
                ),
              )
            : Text(
                btnText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _switchMode() => GestureDetector(
    onTap: () => setState(() {
      isLogin = !isLogin;
      _resetOtpState();
    }),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        isLogin ? L.t('no_account') : L.t('have_account'),
        style: TextStyle(
          color: AppColors.primary(context),
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
  );

  Widget _socialLogins() => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Divider(color: AppColors.textGrey(context).withOpacity(0.2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              L.t('or_continue_with'),
              style: TextStyle(
                color: AppColors.textGrey(context),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: AppColors.textGrey(context).withOpacity(0.2)),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          _socialBtn(
            icon: Icons.g_mobiledata_rounded,
            label: L.t('google'),
            onTap: _googleLogin,
            iconSize: 32,
          ),
        ],
      ),
    ],
  );

  Widget _socialBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    double iconSize = 24,
  }) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.textGrey(context).withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.bg(context).withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: AppColors.text(context)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AppColors.text(context),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _googleLogin() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'centuryfries://login-callback',
      );
    } catch (e) {
      _showErrorMessage('Google login error: $e');
    }
  }

  // ══════════════════════════════════════════════════
  // NICE MESSAGE BOTTOM SHEET
  // ══════════════════════════════════════════════════
  void _showNiceMessage({
    required AppMessageType type,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;

    final icon = switch (type) {
      AppMessageType.error => Icons.error_outline,
      AppMessageType.success => Icons.check_circle_outline,
      AppMessageType.info => Icons.info_outline,
    };
    final accent = switch (type) {
      AppMessageType.error => AppColors.error(context),
      AppMessageType.success => AppColors.primary(context),
      AppMessageType.info => AppColors.primary(context),
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.text(context).withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: TextStyle(
                          color: AppColors.textGrey(context),
                          height: 1.25,
                          fontSize: 13,
                        ),
                      ),
                      if (actionText != null && onAction != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onAction();
                            },
                            child: Text(
                              actionText,
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.close,
                      color: AppColors.textGrey(context),
                      size: 18,
                    ),
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
