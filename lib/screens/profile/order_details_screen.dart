import 'package:flutter/material.dart';
import '../../models/order_view_model.dart'; // 👈 عدلنا الموديل
import '../../theme/app_colors.dart';
import '../../widgets/order_tracking_timeline.dart';
import '../../services/loyalty_service.dart';
import '../../utils/l.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderViewModel order; // 👈 صار OrderViewModel

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _loyaltyShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.order.status == 'delivered' && !_loyaltyShown) {
      _loyaltyShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoyaltySheet();
      });
    }
  }

  Future<void> _showLoyaltySheet() async {
    try {
      final loyalty = await LoyaltyService().getLoyaltyState();
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.card(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) {
          final progress =
              loyalty.points / loyalty.nextTierPoints.clamp(1, 999999);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textHint(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  L.t('loyalty_updated'),
                  style: TextStyle(
                    color: AppColors.text(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  L.t('you_are_now').replaceAll('{tier}', loyalty.tierName),
                  style: TextStyle(
                    color: AppColors.primary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  L
                      .t('points_to_next')
                      .replaceAll('{points}', loyalty.points.toString())
                      .replaceAll('{next}', loyalty.nextTierPoints.toString())
                      .replaceAll('{tier}', loyalty.nextTierName),
                  style: TextStyle(
                    color: AppColors.textGrey(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: AppColors.textHint(
                      context,
                    ).withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(
                      AppColors.primary(context),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    } catch (_) {
      // silent
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    final orderIdShort = order.id.length >= 6
        ? order.id.substring(0, 6)
        : order.id;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(L.t('order_details')),
        backgroundColor: AppColors.bg(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= ORDER NUMBER =================
            Text(
              L.t('order_number').replaceAll('{id}', orderIdShort),
              style: TextStyle(
                color: AppColors.text(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // ================= STATUS =================
            Text(
              L.t('order_status'),
              style: TextStyle(
                color: AppColors.text(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            OrderTrackingTimeline(status: order.status),

            const SizedBox(height: 28),

            // ================= ITEMS =================
            Text(
              L.t('order_items'),
              style: TextStyle(
                color: AppColors.text(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            ...order.orderItems.map((item) {
              final quantity = item['quantity'] ?? 1;
              final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0;
              final totalPrice = (item['total_price'] as num?)?.toDouble() ?? 0;

              final mealName =
                  item['meal_name_en'] ?? item['meal_name_ar'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "$quantity x $mealName",
                            style: TextStyle(
                              color: AppColors.text(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          totalPrice.toStringAsFixed(2),
                          style: TextStyle(
                            color: AppColors.text(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "${unitPrice.toStringAsFixed(2)} ${L.t('each')}",
                      style: TextStyle(
                        color: AppColors.textGrey(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // ================= PRICE SUMMARY =================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _priceRow(context, L.t('subtotal'), order.subtotal),

                  if (order.discount > 0)
                    _priceRow(context, L.t('discount'), -order.discount),

                  const Divider(height: 24),

                  _priceRow(context, L.t('total'), order.total, isTotal: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(
    BuildContext context,
    String label,
    double value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal
                  ? AppColors.text(context)
                  : AppColors.textGrey(context),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              color: isTotal
                  ? AppColors.primary(context)
                  : AppColors.text(context),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
