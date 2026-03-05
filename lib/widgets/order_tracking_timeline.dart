import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OrderTrackingTimeline extends StatelessWidget {
  final String status;

  const OrderTrackingTimeline({
    super.key,
    required this.status,
  });

  static const List<String> steps = [
    'pending',
    'confirmed',
    'preparing',
    'out_for_delivery',
    'delivered',
  ];

  int get currentStepIndex => steps.indexOf(status);

  String _label(String step) {
    switch (step) {
      case 'pending':
        return 'Order placed';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out for delivery';
      case 'delivered':
        return 'Delivered';
      default:
        return step;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentStepIndex;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicator
            Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primary(context)
                        : AppColors.textHint(context),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 36,
                    color: isCompleted
                        ? AppColors.primary(context)
                        : AppColors.textHint(context),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // Label
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _label(steps[index]),
                style: TextStyle(
                  color: isCompleted
                      ? AppColors.text(context)
                      : AppColors.textHint(context),
                  fontSize: 14,
                  fontWeight:
                      isCompleted ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
