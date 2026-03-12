import 'package:flutter/material.dart';
import '../../models/order_view_model.dart'; // 👈 عدلنا الموديل
import '../../theme/app_colors.dart';
import '../../widgets/order_tracking_timeline.dart';
import '../../services/loyalty_service.dart';
import '../../utils/l.dart';
import '../../utils/cart_controller.dart';
import '../../utils/language_controller.dart';
import '../cart/cart_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderViewModel order;

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
              final String? itemNotes = item['notes']?.toString();

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

                    if (itemNotes != null && itemNotes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.edit_note,
                              size: 16,
                              color: AppColors.primary(context),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                itemNotes,
                                style: TextStyle(
                                  color: AppColors.text(context),
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
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

                  if (order.deliveryFee > 0)
                    _priceRow(context, L.t('delivery_fee'), order.deliveryFee),

                  if (order.discount > 0) ...[
                    if (order.discountCoupon > 0)
                      _priceRow(
                        context,
                        '${L.t('coupon')}: ${order.appliedCouponCode ?? ''}',
                        -order.discountCoupon,
                      ),
                    if (order.discountBigOrder > 0)
                      _priceRow(
                        context,
                        L.t('big_order_discount'),
                        -order.discountBigOrder,
                      ),
                    // Fallback for old orders without detailed fields
                    if (order.discountCoupon == 0 && order.discountBigOrder == 0)
                      _priceRow(context, L.t('discount'), -order.discount),
                  ],

                  const Divider(height: 24),

                  _priceRow(context, L.t('total'), order.total, isTotal: true),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= REORDER BUTTON =================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary(context),
                  foregroundColor: AppColors.textOnPrimary(context),
                ),
                icon: const Icon(Icons.refresh),
                label: Text(
                  L.t('reorder', {'key': 'Reorder'}),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onPressed: _isReordering ? null : _handleReorder,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  bool _isReordering = false;

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
          addonIds:
              [], // Advanced: To support fetching addons properly, we would query `order_item_addons`
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
        Navigator.pop(context);
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
