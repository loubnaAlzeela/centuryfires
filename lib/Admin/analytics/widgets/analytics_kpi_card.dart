import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/l.dart';

class AnalyticsKpiCard extends StatefulWidget {
  final String titleKey;
  final String value;

  const AnalyticsKpiCard({
    super.key,
    required this.titleKey,
    required this.value,
  });

  @override
  State<AnalyticsKpiCard> createState() => _AnalyticsKpiCardState();
}

class _AnalyticsKpiCardState extends State<AnalyticsKpiCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // 👈 بدل center
          children: [
            Text(
              L.t(widget.titleKey),
              style: TextStyle(
                color: AppColors.textGrey(context),
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 8),

            /// 👇 حل مشكلة overflow
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                widget.value,
                style: TextStyle(
                  color: AppColors.text(context),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
