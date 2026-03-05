import 'package:flutter/material.dart';

import '../../services/order_view_service.dart';
import '../../models/order_view_model.dart';
import '../../widgets/order_card.dart';
import '../../theme/app_colors.dart';
import '../../utils/l.dart';
import 'order_tracking_screen.dart';
import 'order_details_screen.dart';

class ProfileOrdersSection extends StatelessWidget {
  const ProfileOrdersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final orderService = OrderViewService();

    return FutureBuilder<List<OrderViewModel>>(
      future: orderService.getMyOrdersWithAddress(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Text(
                L.t('err_general'),
                style: TextStyle(color: AppColors.text(context)),
              ),
            ),
          );
        }

        // ================= EMPTY STATE =================
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: AppColors.textHint(context),
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    L.t('no_orders'),
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final orders = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          itemCount: orders.length,
          itemBuilder: (context, i) {
            final order = orders[i];

            return OrderCard(
              order: order,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(
                      order: order, // 👈 هون لازم ينتبه لنوع الموديل
                    ),
                  ),
                );
              },
              onTrack: order.status == 'out_for_delivery'
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(order: order),
                        ),
                      );
                    }
                  : null,
            );
          },
        );
      },
    );
  }
}
