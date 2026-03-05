import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/l.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ ICON
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 24),

              // ✅ TITLE
              Text(
                L.t('order_success_title'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                L.t('order_success_subtitle'),
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 32),

              // 🔁 Track order (later)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Track Order لاحقًا
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    L.t('order_success_track'),
                    style: TextStyle(
                      color: AppColors.primary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🏠 Back to Home
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary(context),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Text(
                    L.t('order_success_back_home'),
                    style: const TextStyle(fontSize: 16),
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
