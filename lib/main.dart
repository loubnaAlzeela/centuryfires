import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/theme_controller.dart';
import 'utils/cart_controller.dart';
import 'utils/language_controller.dart';
import 'screens/home_screen.dart';
import 'Admin/app/admin_app.dart';
import 'driver/driver_app.dart';
import 'driver/services/driver_tracking_service.dart';
import 'screens/auth/reset_password_screen.dart';

import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  const supabaseUrl = 'https://vznqsmzqvliarvfcpaaq.supabase.co';
  const supabaseAnonKey = 'sb_publishable_ns6I2P9dNdnQ2lcbsajFFg_VdGT4K0I';

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  await CartController.instance.loadCart();
  await ThemeController.loadTheme();
  await LanguageController.loadLanguage();
  await DriverTrackingService.init();
  FlutterNativeSplash.remove();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: LanguageController.isArabic,
      builder: (context, isArabic, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.themeMode,
          builder: (context, mode, __) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: isArabic ? const Locale('ar') : const Locale('en'),
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              themeMode: mode,
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              home: const InitialScreen(),
            );
          },
        );
      },
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  final supabase = Supabase.instance.client;

  int _reloadKey = 0;

  @override
  void initState() {
    super.initState();

    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      if (!mounted) return;

      if (event == AuthChangeEvent.passwordRecovery) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ResetPasswordScreen()));
        return;
      }

      // أي login / logout طبيعي
      setState(() => _reloadKey++);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      key: ValueKey(_reloadKey), // مهم: يجبر FutureBuilder يعيد التشغيل
      future: _decideStartScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          // ما نخلي شاشة سودة، رجّع Home كـ fallback
          return const HomeScreen();
        }

        return snapshot.data ?? const HomeScreen();
      },
    );
  }

  Future<Widget> _decideStartScreen() async {
    final session = supabase.auth.currentSession;

    // 🔥 إذا ما في تسجيل دخول → افتح Home
    if (session == null) {
      return const HomeScreen();
    }

    final userRes = await supabase
        .from('users')
        .select('id, role')
        .eq('auth_id', session.user.id)
        .maybeSingle();

    if (userRes == null) {
      return const HomeScreen();
    }

    final String role = userRes['role'];
    final String userId = userRes['id'];

    if (role == 'admin') {
      return const AdminApp();
    }

    if (role == 'driver') {
      final driverRes = await supabase
          .from('driver_profiles')
          .select('is_active')
          .eq('id', userId)
          .maybeSingle();

      if (driverRes != null && driverRes['is_active'] == true) {
        return const DriverApp();
      }
    }

    return const HomeScreen();
  }
}
