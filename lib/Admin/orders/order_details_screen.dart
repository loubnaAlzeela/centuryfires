import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../services/admin_orders_service.dart';
import '../../utils/l.dart';
import '../../utils/language_controller.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final AdminOrdersService _service = AdminOrdersService();

  late String currentStatus;
  bool isUpdating = false;

  final List<String> statuses = [
    'pending',
    'confirmed',
    'preparing',
    'out_for_delivery',
    'delivered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    currentStatus = widget.order['status'];
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      setState(() => isUpdating = true);

      await _service.updateOrderStatus(
        orderId: widget.order['id'],
        status: newStatus,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      print("UPDATE ERROR: $e");

      setState(() => isUpdating = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${L.t('error')}: $e')));
    }
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '0.00';
    final num? val = value is num ? value : num.tryParse(value.toString());
    if (val == null) return '0.00';
    return val.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        title: Text(L.t('order_details')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${order['id'].toString().substring(0, 6)}',
                style: TextStyle(
                  color: AppColors.primary(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${L.t('customer')}: ${order['users']?['name'] ?? L.t('guest')}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (order['users'] != null)
                    TextButton.icon(
                      onPressed: () => _showCustomerDetailsDialog(order['users']),
                      icon: const Icon(Icons.person_search_rounded, size: 18),
                      label: Text(L.t('details')),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary(context),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (order['created_at'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.access_time_filled, size: 16, color: AppColors.textGrey(context)),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.parse(order['created_at']).toLocal()),
                      style: TextStyle(color: AppColors.textGrey(context), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              if (order['payment_method'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.payment, size: 16, color: AppColors.textGrey(context)),
                    const SizedBox(width: 6),
                    Text(
                      '${L.t('payment_method')}: ${order['payment_method'] == 'online' ? order['payment_provider']?.toString().toUpperCase() ?? 'Online' : L.t('cash')}',
                      style: TextStyle(color: AppColors.textGrey(context), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(L.t('subtotal'), style: TextStyle(color: AppColors.textGrey(context))),
                        Text('SAR ${_formatPrice(order['subtotal'] ?? order['total'])}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if ((order['driver_fee'] ?? 0) > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(L.t('delivery_fee'), style: TextStyle(color: AppColors.textGrey(context))),
                          Text('SAR ${_formatPrice(order['driver_fee'])}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],

                    if ((order['discount'] ?? 0) > 0) ...[
                      // ── Coupon discount ──
                      if ((order['discount_coupon'] ?? 0) > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${L.t('coupon')}: ${order['applied_coupon_code'] ?? ''}',
                                      style: const TextStyle(color: Colors.green),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.confirmation_number, size: 14, color: Colors.green),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('- SAR ${_formatPrice(order['discount_coupon'])}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],

                      // ── Big order discount ──
                      if ((order['discount_big_order'] ?? 0) > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      L.t('big_order_discount'),
                                      style: const TextStyle(color: Colors.green),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.shopping_bag, size: 14, color: Colors.green),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('- SAR ${_formatPrice(order['discount_big_order'])}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],

                      // ── Fallback for old orders without detailed discount fields ──
                      if ((order['discount_coupon'] ?? 0) == 0 && (order['discount_big_order'] ?? 0) == 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      L.t('discount_promo'),
                                      style: const TextStyle(color: Colors.green),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.local_offer, size: 14, color: Colors.green),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('- SAR ${_formatPrice(order['discount'])}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                    ],

                    const Divider(),
                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(L.t('total'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('SAR ${_formatPrice(order['total'])}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary(context))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Text('${L.t('status')}: '),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(
                        currentStatus,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      L.t(currentStatus).toUpperCase(),
                      style: TextStyle(
                        color: _statusColor(currentStatus),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (order['order_items'] != null &&
                  (order['order_items'] as List).isNotEmpty) ...[
                Text(
                  L.t('items'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                ...((order['order_items'] as List).map((item) {
                  final qty = item['quantity'] ?? 0;
                  final mealMap = item['meals'] as Map<String, dynamic>?;
                  final mealName = LanguageController.isArabic.value
                      ? (mealMap?['name_ar'] ?? mealMap?['name_en'] ?? '')
                      : (mealMap?['name_en'] ?? mealMap?['name_ar'] ?? '');
                  final price = item['total_price']?.toString() ?? '0';
                  final notes = item['notes']?.toString();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$qty x $mealName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              price,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (notes != null && notes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
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
                                    notes,
                                    style: const TextStyle(
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
                })),
              ],

              const SizedBox(height: 30),

              isUpdating
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary(context),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          _showStatusSelector();
                        },
                        child: Text(L.t('change_status')),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: statuses.map((status) {
              return ListTile(
                title: Text(L.t(status).toUpperCase()),
                trailing: status == currentStatus
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _updateStatus(status);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.deepOrange;
      case 'out_for_delivery':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showCustomerDetailsDialog(Map<String, dynamic> userDetails) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.person, color: AppColors.primary(context)),
              const SizedBox(width: 8),
              Text(L.t('customer_details'), style: const TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.badge, size: 20),
                title: Text('${userDetails['name'] ?? L.t('guest')}'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              if (userDetails['phone'] != null && userDetails['phone'].toString().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.phone, size: 20),
                  title: Text('${userDetails['phone']}'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              if (userDetails['email'] != null && userDetails['email'].toString().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.email, size: 20),
                  title: Text('${userDetails['email']}'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(L.t('close'), style: TextStyle(color: AppColors.primary(context))),
            ),
          ],
        );
      },
    );
  }
}
