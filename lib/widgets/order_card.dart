import 'package:flutter/material.dart';
import '../models/order_view_model.dart';
import '../theme/app_colors.dart';
import '../utils/l.dart';
import '../utils/cart_controller.dart';
import '../utils/language_controller.dart';
import '../screens/cart/cart_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderCard extends StatefulWidget {
  final OrderViewModel order;
  final VoidCallback onTap;
  final VoidCallback? onTrack;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onTrack,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _isReordering = false;

  Color _statusColor(BuildContext context) {
    switch (widget.order.status) {
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
        onTap: widget.onTap,
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
                        (widget.order.imageUrl != null &&
                            widget.order.imageUrl!.isNotEmpty)
                        ? Image.network(
                            widget.order.imageUrl!,
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
                          "${L.t('order')} #${widget.order.orderNumber ?? ''}",
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
                          L.t(widget.order.status).toUpperCase(),
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
              if (widget.order.area != null || widget.order.street != null)
                Text(
                  '${widget.order.area ?? ''} - ${widget.order.street ?? ''}',
                  style: TextStyle(
                    color: AppColors.textGrey(context),
                    fontSize: 13,
                  ),
                ),

              const SizedBox(height: 10),

              // ✅ نقاط العميل
              Text(
                widget.order.pointsEarned > 0
                    ? '+${widget.order.pointsEarned} ${L.t('order_card_points_earned')}'
                    : L.t('order_card_points_pending'),
                style: TextStyle(
                  color: widget.order.pointsEarned > 0
                      ? AppColors.primary(context)
                      : AppColors.textHint(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // ================= TRACK BUTTON =================
              if (widget.order.status == 'out_for_delivery' &&
                  widget.onTrack != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onTrack,
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

              // ================= REORDER BUTTON =================
              if (widget.order.status == 'delivered' ||
                  widget.order.status == 'completed') ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isReordering ? null : _handleReorder,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary(context),
                      side: BorderSide(color: AppColors.primary(context)),
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isReordering
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 20),
                    label: Text(
                      L.t('reorder', {'key': 'Reorder'}),
                      style: const TextStyle(fontWeight: FontWeight.w600),
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

  Future<void> _handleReorder() async {
    setState(() => _isReordering = true);

    try {
      final supabase = Supabase.instance.client;
      // Fetch order items with their corresponding meal names/images
      final List<dynamic> items = await supabase
          .from('order_items')
          .select('''
            meal_id,
            quantity,
            unit_price,
            notes,
            meals (
              name_en,
              name_ar,
              image_url
            )
          ''')
          .eq('order_id', widget.order.id);

      if (items.isEmpty) return;

      final isAr = LanguageController.ar;

      // Add each item to the cart
      for (final it in items) {
        final mealsInfo = it['meals'];
        if (mealsInfo == null) continue;

        final nameEn = mealsInfo['name_en'] ?? '';
        final nameAr = mealsInfo['name_ar'] ?? '';
        final name = isAr && nameAr.toString().isNotEmpty ? nameAr : nameEn;

        // Ensure we retrieve an image URL if possible
        String? imgUrlStr = mealsInfo['image_url']?.toString();
        // Validation for the image URL
        if (imgUrlStr != null &&
            (!imgUrlStr.startsWith('http') && !imgUrlStr.startsWith('https'))) {
          imgUrlStr = null;
        }

        CartController.instance.addLine(
          mealId: it['meal_id']?.toString() ?? '',
          name: name.toString(),
          price: (it['unit_price'] as num?)?.toDouble() ?? 0.0,
          imageUrl: imgUrlStr,
          addonIds: [],
          addonNames: [],
          quantity: (it['quantity'] as num?)?.toInt() ?? 1,
          notes: it['notes']?.toString(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              L.t('items_added_to_cart', {'key': 'Items added to cart!'}),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L.t('err_general')),
            backgroundColor: AppColors.error(context),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReordering = false);
      }
    }
  }
}
