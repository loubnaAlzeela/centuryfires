import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/loyalty_card.dart';
import '../../widgets/profile_contact_menu.dart';

import 'refund_policy_screen.dart';
import 'saved_addresses_screen.dart';
import 'edit_profile_screen.dart';
import 'profile_orders_screen.dart';
import 'reward_screen.dart';
import 'rate_your_meals_screen.dart';
import '../../utils/l.dart';
import '../auth/login_signup_screen.dart';
import '../../utils/language_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  bool isGuest = true;
  bool hasError = false;
  String errorMessage = '';

  // ================= USER INFO =================
  String name = '';
  String email = '';
  String phone = '';

  // ================= RESTAURANT STATUS =================
  bool restaurantOpen = false;
  bool restaurantStatusLoading = true;

  // ================= LOYALTY INFO =================
  String tierName = 'BRONZE';
  int points = 0;
  int orders = 0;

  int currentTierMinPoints = 0;
  int nextTierPoints = 0;
  String nextTierName = 'BRONZE';

  double progress = 0.0;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _loadRestaurantStatus();
  }

  /// Initialize authentication listener and load initial data
  void _initializeAuth() {
    _authSub = supabase.auth.onAuthStateChange.listen(
      _handleAuthStateChange,
      onError: (error) {
        debugPrint('AUTH STREAM ERROR: $error');
        if (mounted) {
          setState(() {
            hasError = true;
            errorMessage = L.t('err_auth_listener');
          });
        }
      },
    );

    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      _setGuestState();
    } else {
      setState(() {
        isGuest = false;
        isLoading = true;
      });
      _loadData();
      _loadRestaurantStatus();
    }
  }

  Future<void> _handleAuthStateChange(AuthState data) async {
    if (!mounted) return;

    final session = data.session;

    if (session == null) {
      _setGuestState();
    } else {
      setState(() {
        isGuest = false;
        isLoading = true;
        hasError = false;
      });
      await _loadData();
      await _loadRestaurantStatus();
    }
  }

  void _setGuestState() {
    if (!mounted) return;

    setState(() {
      isGuest = true;
      name = L.t('guest');
      email = '';
      phone = '';
      tierName = 'BRONZE';
      points = 0;
      orders = 0;
      currentTierMinPoints = 0;
      nextTierPoints = 0;
      nextTierName = 'BRONZE';
      progress = 0.0;
      isLoading = false;
      hasError = false;
    });
    print("Today weekday: ${DateTime.now().weekday}");
    _loadRestaurantStatus();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // ================= REQUIRE LOGIN =================
  Future<void> _requireLogin(VoidCallback onLoggedIn) async {
    if (!isGuest) {
      onLoggedIn();
      return;
    }

    final loggedIn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
    );

    if (loggedIn == true && mounted) {
      final authUser = supabase.auth.currentUser;
      if (authUser != null) {
        setState(() {
          isGuest = false;
          isLoading = true;
        });
        await _loadData();
      }
    }
  }

  // ================= PROGRESS CALCULATION =================
  double _calcProgress({
    required int points,
    required int currentMin,
    required int nextMin,
  }) {
    if (nextMin <= currentMin) return 1.0;
    final range = nextMin - currentMin;
    if (range <= 0) return 0.0;
    return ((points - currentMin) / range).clamp(0.0, 1.0);
  }

  // ================= DYNAMIC GRADIENT (NO FIXED COLORS) =================
  Color _hsl(Color c, {double? hue, double? sat, double? light}) {
    final h = HSLColor.fromColor(c);
    return h
        .withHue(hue ?? h.hue)
        .withSaturation(sat ?? h.saturation)
        .withLightness(light ?? h.lightness)
        .toColor();
  }

  Gradient tierGradient(BuildContext context, String tier) {
    final base = AppColors.primary(context);

    // تمايز واضح لكل Tier بدون ألوان Hex ثابتة
    final t = tier.toLowerCase();
    double hue;
    double s = 0.85;

    if (t.contains('silver')) {
      hue = 210; // cool steel
      s = 0.15;
    } else if (t.contains('gold')) {
      hue = 45; // warm gold
      s = 0.95;
    } else if (t.contains('diamond')) {
      hue = 185; // icy blue
      s = 0.50;
    } else {
      hue = 20; // bronze/copper
      s = 0.70;
    }

    final c1 = _hsl(base, hue: hue, sat: s, light: 0.62);
    final c2 = _hsl(base, hue: hue, sat: s, light: 0.34);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c1, c2],
    );
  }

  //========================================
  int _dartWeekdayToDb(int wd) {
    // Dart: Mon=1..Sun=7 -> نفس اللي عندك
    return wd;
  }

  TimeOfDay? _parseTimeOfDay(String s) {
    // يدعم "10:00 AM" و "23:30" بشكل بسيط
    final v = s.trim();
    if (v.isEmpty) return null;

    // AM/PM
    final ampm = RegExp(r'\b(am|pm)\b', caseSensitive: false);
    if (ampm.hasMatch(v)) {
      final parts = v.split(RegExp(r'\s+'));
      if (parts.isEmpty) return null;

      final timePart = parts.first;
      final suffix = parts.length > 1 ? parts.last.toLowerCase() : '';

      final hhmm = timePart.split(':');
      if (hhmm.length < 2) return null;

      int h = int.tryParse(hhmm[0]) ?? -1;
      int m = int.tryParse(hhmm[1]) ?? -1;
      if (h < 0 || m < 0) return null;

      if (suffix == 'pm' && h != 12) h += 12;
      if (suffix == 'am' && h == 12) h = 0;

      return TimeOfDay(hour: h, minute: m);
    }

    // 24h "HH:mm"
    final hhmm = v.split(':');
    if (hhmm.length < 2) return null;
    final h = int.tryParse(hhmm[0]) ?? -1;
    final m = int.tryParse(hhmm[1]) ?? -1;
    if (h < 0 || m < 0) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  bool _isNowInRange({
    required int nowMin,
    required int openMin,
    required int closeMin,
  }) {
    // نفس اليوم
    if (closeMin > openMin) {
      return nowMin >= openMin && nowMin <= closeMin;
    }

    // حالة الدوام يعبر منتصف الليل (مثلاً 6PM -> 2AM)
    if (closeMin < openMin) {
      return nowMin >= openMin || nowMin <= closeMin;
    }

    // open == close → اعتبره مغلق
    return false;
  }

  Future<void> _loadRestaurantStatus() async {
    print("LOAD RESTAURANT STATUS STARTED");
    try {
      if (!mounted) return;
      setState(() => restaurantStatusLoading = true);

      final row = await supabase
          .from('restaurant_settings')
          .select('opening_time, closing_time, working_days')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final openStr = (row?['opening_time'] ?? '').toString().trim();
      final closeStr = (row?['closing_time'] ?? '').toString().trim();
      final daysRaw = row?['working_days'];

      final open = _parseTimeOfDay(openStr);
      final close = _parseTimeOfDay(closeStr);

      // ✅ robust working_days parsing (List or JSON string)
      List<int> workingDays = [];

      if (daysRaw is List) {
        // ممكن تجي [1,2,3] أو ["1","2","3"]
        workingDays = daysRaw
            .map((e) => int.tryParse(e.toString()))
            .whereType<int>()
            .toList();
      } else if (daysRaw is String) {
        final s = daysRaw.trim();
        if (s.isNotEmpty) {
          try {
            final decoded = jsonDecode(s);
            if (decoded is List) {
              workingDays = decoded
                  .map((e) => int.tryParse(e.toString()))
                  .whereType<int>()
                  .toList();
            }
          } catch (_) {
            // إذا كان نص غريب، حاول نفصله يدويًا (احتياط)
            final cleaned = s.replaceAll('[', '').replaceAll(']', '').trim();
            if (cleaned.isNotEmpty) {
              workingDays = cleaned
                  .split(',')
                  .map((e) => int.tryParse(e.replaceAll('"', '').trim()))
                  .whereType<int>()
                  .toList();
            }
          }
        }
      }

      final now = DateTime.now();
      final todayDb = _dartWeekdayToDb(now.weekday); // حسب mapping تبعك
      final isWorkingDay = workingDays.contains(todayDb);
      print("IS WORKING DAY: $isWorkingDay");
      print("OPEN PARSED: $open");
      print("CLOSE PARSED: $close");

      bool openNow = false;
      if (isWorkingDay && open != null && close != null) {
        final nowMin = now.hour * 60 + now.minute;
        openNow = _isNowInRange(
          nowMin: nowMin,
          openMin: _toMinutes(open),
          closeMin: _toMinutes(close),
        );
      }

      if (!mounted) return;
      setState(() {
        restaurantOpen = openNow;
        restaurantStatusLoading = false;
      });
    } catch (e, stack) {
      print("ERROR IN LOAD STATUS: $e");
      print(stack);
      if (!mounted) return;
      setState(() {
        restaurantOpen = false;
        restaurantStatusLoading = false;
      });
    }
  }

  // ================= LOAD DATA =================
  Future<void> _loadData() async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) {
        _setGuestState();
        return;
      }

      debugPrint('PROFILE: auth id = ${authUser.id}');

      Map<String, dynamic>? userData;

      Future<Map<String, dynamic>?> fetchUser() async {
        return await supabase
            .from('users')
            .select('id, name, email, phone, is_active')
            .eq('auth_id', authUser.id)
            .maybeSingle();
      }

      userData = await fetchUser();
      if (userData == null) {
        await Future.delayed(const Duration(milliseconds: 300));
        userData = await fetchUser();
      }

      if (userData == null) {
        debugPrint('PROFILE: user row not found → creating one...');

        await supabase.from('users').insert({
          'auth_id': authUser.id,
          'email': authUser.email,
          'name': '',
          'phone': '',
          'role': 'customer',
          'is_active': true,
        });

        userData = await fetchUser();

        if (userData == null) {
          debugPrint('PROFILE: failed to fetch user row even after insert');
          _handleLoadError(L.t('err_user_not_found'));
          return;
        }
      }

      debugPrint('PROFILE: user row found id=${userData['id']}');

      final isActive = (userData['is_active'] as bool?) ?? true;
      if (!isActive) {
        await supabase.auth.signOut();
        if (mounted) _showErrorSnackbar(L.t('err_account_disabled'));
        return;
      }

      final userId = (userData['id'] as String);

      final loyaltyData = await supabase
          .from('user_loyalty')
          .select(
            'points, total_orders, loyalty_tiers(name_ar, name_en, min_points)',
          )
          .eq('user_id', userId)
          .maybeSingle();

      final loyaltyInfo = _processLoyaltyData(loyaltyData);
      final nextTierInfo = await _fetchNextTier(
        (loyaltyInfo['currentMin'] as int?) ?? 0,
      );

      final calculatedProgress = _calcProgress(
        points: (loyaltyInfo['points'] as int?) ?? 0,
        currentMin: (loyaltyInfo['currentMin'] as int?) ?? 0,
        nextMin:
            (nextTierInfo['nextMin'] as int?) ??
            ((loyaltyInfo['currentMin'] as int?) ?? 0),
      );

      if (!mounted) return;

      setState(() {
        name = (userData!['name'] as String?)?.trim().isNotEmpty == true
            ? (userData['name'] as String).trim()
            : L.t('guest');

        email = (userData['email'] as String?) ?? (authUser.email ?? '');
        phone = (userData['phone'] as String?) ?? '';

        points = (loyaltyInfo['points'] as int?) ?? 0;
        orders = (loyaltyInfo['orders'] as int?) ?? 0;
        tierName = (loyaltyInfo['tierName'] as String?) ?? 'BRONZE';

        currentTierMinPoints = (loyaltyInfo['currentMin'] as int?) ?? 0;
        nextTierPoints =
            (nextTierInfo['nextMin'] as int?) ?? currentTierMinPoints;
        nextTierName = (nextTierInfo['nextName'] as String?) ?? tierName;

        progress = calculatedProgress;

        isLoading = false;
        hasError = false;
        errorMessage = '';
      });

      debugPrint('PROFILE: load success ✅');
    } on PostgrestException catch (e) {
      debugPrint('PROFILE DB ERROR: ${e.code} | ${e.message} | ${e.details}');
      _handleLoadError(L.t('err_database'));
    } catch (e) {
      debugPrint('PROFILE LOAD ERROR: $e');
      _handleLoadError(L.t('err_general'));
    }
  }

  Map<String, dynamic> _processLoyaltyData(Map<String, dynamic>? loyaltyData) {
    if (loyaltyData == null) {
      return {'points': 0, 'orders': 0, 'tierName': 'BRONZE', 'currentMin': 0};
    }

    final tier = loyaltyData['loyalty_tiers'];

    final String tierName =
        (LanguageController.ar ? tier['name_ar'] : tier['name_en'])
            ?.toString()
            .toUpperCase() ??
        'BRONZE';

    return {
      'points': (loyaltyData['points'] as num?)?.toInt() ?? 0,
      'orders': (loyaltyData['total_orders'] as num?)?.toInt() ?? 0,
      'tierName': tierName,
      'currentMin': (tier?['min_points'] as num?)?.toInt() ?? 0,
    };
  }

  Future<Map<String, dynamic>> _fetchNextTier(int currentMin) async {
    try {
      final nextTier = await supabase
          .from('loyalty_tiers')
          .select('name_ar, name_en, min_points')
          .gt('min_points', currentMin)
          .order('min_points', ascending: true)
          .limit(1)
          .maybeSingle();

      if (nextTier != null) {
        return {
          'nextName':
              (LanguageController.ar
                      ? nextTier['name_ar']
                      : nextTier['name_en'])
                  ?.toString()
                  .toUpperCase() ??
              'BRONZE',
          'nextMin': (nextTier['min_points'] as num?)?.toInt() ?? currentMin,
        };
      }
    } catch (e) {
      debugPrint('FETCH NEXT TIER ERROR: $e');
    }

    return {'nextName': tierName, 'nextMin': currentMin};
  }

  void _handleLoadError(String message) {
    if (!mounted) return;

    setState(() {
      isLoading = false;
      hasError = true;
      errorMessage = message;
    });

    _showErrorSnackbar(message);
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error(context),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: L.t('retry'),
          textColor: AppColors.textOnPrimary(context),
          onPressed: _loadData,
        ),
      ),
    );
  }

  // ================= THEME + LANGUAGE ICONS (IN HEADER) =================
  Widget _headerIconButton({
    required Widget child,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.textGrey(context).withValues(alpha: 0.35),
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildHeaderActions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ar = LanguageController.ar;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _headerIconButton(
          tooltip: L.t('dark_mode'),
          onTap: () => ThemeController.toggle(!isDark),
          child: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            size: 20,
            color: AppColors.primary(context),
          ),
        ),
        const SizedBox(width: 10),
        _headerIconButton(
          tooltip: L.t('language'), // إذا ما عندك key: ضيفه بالترجمة
          onTap: () async {
            await LanguageController.setArabic(!ar);
            if (mounted) setState(() {}); // rebuild screen
          },
          child: Text(
            ar ? 'AR' : 'EN',
            style: TextStyle(
              color: AppColors.text(context),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ================= LOGOUT =================
  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('LOGOUT ERROR: $e');
      if (mounted) {
        _showErrorSnackbar(L.t('err_logout'));
      }
    }
  }

  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card(context),
        title: Text(
          L.t('sign_out'),
          style: TextStyle(color: AppColors.text(context)),
        ),
        content: Text(
          L.t('confirm_logout'),
          style: TextStyle(color: AppColors.textGrey(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              L.t('cancel'),
              style: TextStyle(color: AppColors.textGrey(context)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              L.t('sign_out'),
              style: TextStyle(color: AppColors.error(context)),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await _logout();
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        title: Text(
          L.t('profile'),
          style: TextStyle(color: AppColors.text(context)),
        ),
        centerTitle: true,
        actions: [
          if (!isGuest && !isLoading)
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.text(context)),
              onPressed: () {
                setState(() => isLoading = true);
                _loadData();
              },
              tooltip: L.t('refresh'),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary(context)),
            const SizedBox(height: 16),
            Text(
              L.t('loading'),
              style: TextStyle(color: AppColors.textGrey(context)),
            ),
          ],
        ),
      );
    }

    if (hasError && !isGuest) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textGrey(context),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(color: AppColors.textGrey(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  hasError = false;
                });
                _loadData();
              },
              icon: Icon(
                Icons.refresh,
                color: AppColors.textOnPrimary(context),
              ),
              label: Text(
                L.t('retry'),
                style: TextStyle(color: AppColors.textOnPrimary(context)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary(context),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildLoyaltyCard(),
          const SizedBox(height: 20),
          if (!isGuest) ..._buildUserInfo(),

          const SizedBox(height: 20),

          // ✅ زر تسجيل الدخول يظهر فوق الإعدادات
          if (isGuest) _buildActionButton(),

          const SizedBox(height: 20),

          ..._buildMenuItems(),

          const SizedBox(height: 28),
          const ProfileContactMenu(),

          // زر تسجيل الخروج يبقى تحت
          if (!isGuest) ...[const SizedBox(height: 28), _buildActionButton()],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.text(context).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'profile_avatar',
            child: CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary(context),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: AppColors.textOnPrimary(context),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ✅ icons جنب الاسم
                    _buildHeaderActions(),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isGuest ? L.t('guest') : tierName,
                        style: TextStyle(
                          color: AppColors.textGrey(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(width: 8), // مسافة صغيرة ثابتة فقط
                    // ===== Restaurant status badge =====
                    restaurantStatusLoading
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bg(context),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.textGrey(
                                  context,
                                ).withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              L.t('loading'),
                              style: TextStyle(
                                color: AppColors.textGrey(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: restaurantOpen
                                  ? AppColors.primary(
                                      context,
                                    ).withValues(alpha: 0.18)
                                  : AppColors.bg(context),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: restaurantOpen
                                    ? AppColors.primary(
                                        context,
                                      ).withValues(alpha: 0.55)
                                    : AppColors.textGrey(
                                        context,
                                      ).withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              restaurantOpen
                                  ? L.t('open_now')
                                  : L.t('closed_now'),
                              style: TextStyle(
                                color: restaurantOpen
                                    ? AppColors.text(context)
                                    : AppColors.textGrey(context),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyCard() {
    return GestureDetector(
      onTap: () => _requireLogin(() {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RewardScreen()),
        );
      }),
      child: LoyaltyCard(
        tier: tierName,
        points: points,
        orders: orders,
        currentTierMinPoints: currentTierMinPoints,
        nextTierPoints: nextTierPoints,
        nextTierName: nextTierName,
        gradient: tierGradient(context, tierName),
      ),
    );
  }

  List<Widget> _buildUserInfo() {
    return [
      if (email.isNotEmpty) _infoRow(context, Icons.email, email),
      if (phone.isNotEmpty) _infoRow(context, Icons.phone, phone),
    ];
  }

  List<Widget> _buildMenuItems() {
    return [
      _item(context, Icons.edit, L.t('settings'), () async {
        _requireLogin(() async {
          final updated = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          );

          if (updated == true) {
            setState(() => isLoading = true);
            await _loadData();
          }
        });
      }),
      _item(context, Icons.location_on, L.t('saved_addresses'), () {
        _requireLogin(() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
          );
        });
      }),
      const SizedBox(height: 28),
      _item(context, Icons.star_border, L.t('my_orders'), () {
        _requireLogin(() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileOrdersScreen()),
          );
        });
      }),
      _item(context, Icons.card_giftcard, L.t('rewards'), () {
        _requireLogin(() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RewardScreen()),
          );
        });
      }),
      _item(context, Icons.rate_review, L.t('my_reviews'), () {
        _requireLogin(() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RateYourMealsScreen()),
          );
        });
      }),
      const SizedBox(height: 28),
      _item(context, Icons.policy, L.t('terms_privacy'), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RefundPolicyScreen()),
        );
      }),
    ];
  }

  Widget _buildActionButton() {
    if (isGuest) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
            );
          },
          icon: Icon(Icons.login, color: AppColors.textOnPrimary(context)),
          label: Text(
            L.t('login_signup'),
            style: TextStyle(
              color: AppColors.textOnPrimary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _confirmLogout,
      icon: Icon(Icons.logout, color: AppColors.error(context)),
      label: Text(
        L.t('sign_out'),
        style: TextStyle(color: AppColors.error(context)),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.error(context), width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ================= HELPERS =================
  Widget _infoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textGrey(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textGrey(context),
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.text(context).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary(context), size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.text(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textGrey(context)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
