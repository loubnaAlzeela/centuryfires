import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../services/admin_orders_service.dart';
import '../../utils/l.dart';

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

              Text(
                '${L.t('customer')}: ${order['users']?['name'] ?? L.t('guest')}',
              ),
              const SizedBox(height: 10),
              Text('Total: SAR ${order['total']}'),
              const SizedBox(height: 10),

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
                      currentStatus.toUpperCase(),
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
                  final mealName =
                      mealMap?['name_en'] ?? mealMap?['name_ar'] ?? '';
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
}
