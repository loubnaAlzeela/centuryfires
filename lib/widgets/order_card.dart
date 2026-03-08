import 'package:flutter/material.dart';
import '../models/order_view_model.dart';
import '../theme/app_colors.dart';
import '../utils/l.dart';

class OrderCard extends StatelessWidget {
  final OrderViewModel order;
  final VoidCallback onTap;
  final VoidCallback? onTrack;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onTrack,
  });

  Color _statusColor(BuildContext context) {
    switch (order.status) {
      case 'delivered':
      case 'completed':
      case 'confirmed':
      case 'preparing':
      case 'out_for_delivery':
        return AppColors.primary(context);
      case 'cancelled':
      case 'payment_failed':
        return AppColors.error(context);
      case 'awaiting_payment':
        return Colors.orange;
      default:
        return AppColors.textHint(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HEADER =================
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        (order.imageUrl != null && order.imageUrl!.isNotEmpty)
                        ? Image.network(
                            order.imageUrl!,
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 54,
                            height: 54,
                            color: AppColors.textHint(
                              context,
                            ).withValues(alpha: 0.2),
                            child: Icon(
                              Icons.fastfood,
                              color: AppColors.textHint(context),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${L.t('order')} #${order.orderNumber ?? ''}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.text(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // ✅ status صغير وبسطر لحاله
                        Text(
                          L.t(order.status).toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ================= ADDRESS =================
              if (order.area != null || order.street != null)
                Text(
                  '${order.area ?? ''} - ${order.street ?? ''}',
                  style: TextStyle(
                    color: AppColors.textGrey(context),
                    fontSize: 13,
                  ),
                ),

              const SizedBox(height: 10),

              // ✅ نقاط العميل
              Text(
                order.pointsEarned > 0
                    ? '+${order.pointsEarned} ${L.t('order_card_points_earned')}'
                    : L.t('order_card_points_pending'),
                style: TextStyle(
                  color: order.pointsEarned > 0
                      ? AppColors.primary(context)
                      : AppColors.textHint(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // ================= TRACK BUTTON =================
              if (order.status == 'out_for_delivery' && onTrack != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTrack,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary(context),
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      L.t('track_order'),
                      style: TextStyle(
                        color: AppColors.textOnPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
