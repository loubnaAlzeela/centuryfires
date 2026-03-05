import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'home_screen.dart';
import '../theme/app_colors.dart';
import '../services/category_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800), // مدة الموجة
    );

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward(); // ✅ موجة مرة وحدة فقط

    _loadDataAndNavigate();
  }

  Future<void> _loadDataAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    await CategoryService().getCategories();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      "assets/images/branding/logo.png",
                      width: 180,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),

                    /// 👇 موجة واحدة فقط
                    WaveText(
                      text: "Century Fries",
                      controller: _controller,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// =======================
/// Widget موجة مرة واحدة
/// =======================
class WaveText extends StatelessWidget {
  final String text;
  final AnimationController controller;

  const WaveText({
    super.key,
    required this.text,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(text.length, (index) {
        final char = text[index];

        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            // موجة تتحرك مع تقدّم الأنيميشن مرة وحدة
            final progress = controller.value;
            final wave =
                (progress * math.pi * 2) - (index * 0.5);
            final offset = math.sin(wave) * 6 * (1 - progress);

            return Transform.translate(
              offset: Offset(0, offset),
              child: child,
            );
          },
          child: Text(
            char,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        );
      }),
    );
  }
}
