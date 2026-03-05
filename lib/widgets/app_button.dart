import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

enum AppButtonType { primary, secondary, option, icon, card }

class AppButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final AppButtonType type;
  final bool enabled;

  const AppButton({
    super.key,
    required this.child,
    required this.onTap,
    this.type = AppButtonType.primary,
    this.enabled = true,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = _backgroundColor(context);
    final shadowColor = AppColors.text(context).withValues(alpha: 0.35);

    return GestureDetector(
      onTapDown: widget.enabled
          ? (_) {
              setState(() => pressed = true);
              HapticFeedback.lightImpact();
            }
          : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: () => setState(() => pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          color: widget.enabled ? bgColor : AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          boxShadow: pressed
              ? []
              : [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: widget.child,
      ),
    );
  }

  Color _backgroundColor(BuildContext context) {
    switch (widget.type) {
      case AppButtonType.primary:
        return AppColors.primary(context);
      case AppButtonType.secondary:
        return AppColors.primary(context).withValues(alpha: 0.9);
      case AppButtonType.option:
      case AppButtonType.icon:
      case AppButtonType.card:
        return AppColors.card(context);
    }
  }
}
