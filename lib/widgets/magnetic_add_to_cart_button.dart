import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MagneticAddToCartButton extends StatefulWidget {
  final VoidCallback onTap;

  const MagneticAddToCartButton({super.key, required this.onTap});

  @override
  State<MagneticAddToCartButton> createState() =>
      _MagneticAddToCartButtonState();
}

class _MagneticAddToCartButtonState extends State<MagneticAddToCartButton> {
  double x = 0;
  double y = 0;
  bool isPressed = false;

  void _resetPosition() {
    setState(() {
      x = 0;
      y = 0;
      isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          x = (details.localPosition.dx - 100) / 15;
          y = (details.localPosition.dy - 30) / 15;
        });
      },
      onPanEnd: (_) => _resetPosition(),
      onTapDown: (_) {
        setState(() => isPressed = true);
      },
      onTapUp: (_) {
        _resetPosition();
        widget.onTap();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🔥 Glow Effect
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 220,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary(
                    context,
                  ).withValues(alpha: isPressed ? 0.6 : 0.3),
                  blurRadius: isPressed ? 30 : 15,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // 💎 Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()
              ..translate(x, y)
              ..scale(isPressed ? 0.95 : 1.0),
            curve: Curves.easeOutCubic,
            width: 220,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: AppColors.primary(context),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Center(
                  child: Text(
                    "Add To Cart",
                    style: TextStyle(
                      color: AppColors.textOnPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
}
