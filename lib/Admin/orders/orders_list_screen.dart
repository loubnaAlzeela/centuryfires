import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../services/admin_orders_service.dart';
import 'order_details_screen.dart';
import '../../utils/l.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  final AdminOrdersService _service = AdminOrdersService();

  String? selectedStatus;
  bool isLoading = true;
  List<Map<String, dynamic>> orders = [];

  final Map<String, String?> statuses = {
    'all': null,
    'new': 'pending',
    'confirmed': 'confirmed',
    'preparing': 'preparing',
    'out_for_delivery': 'out_for_delivery',
    'completed': 'delivered',
    'cancelled': 'cancelled',
  };

  @override
  void initState() {
    super.initState();
    selectedStatus = null;
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final data = await _service.getOrders(status: selectedStatus);

      data.sort((a, b) {
        final statusA = a['status'] ?? '';
        final statusB = b['status'] ?? '';

        final statusCompare = _statusPriority(
          statusA,
        ).compareTo(_statusPriority(statusB));

        if (statusCompare != 0) return statusCompare;

        final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '');
        final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '');

        if (dateA == null || dateB == null) return 0;

        return dateB.compareTo(dateA); // الأحدث أولاً
      });

      if (!mounted) return;

      setState(() {
        orders = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('fetchOrders error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(L.t('err_general'))));

      setState(() => isLoading = false);
    }
  }

  int _statusPriority(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'preparing':
        return 2;
      case 'out_for_delivery':
        return 3;
      case 'delivered':
        return 4;
      case 'cancelled':
        return 5;
      default:
        return 99;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = statuses.entries.toList();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        title: Text(L.t('orders')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchOrders),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 35,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final label = entries[index].key;
                final value = entries[index].value;
                final isActive = selectedStatus == value;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      selectedStatus = value;
                      fetchOrders();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary(context)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary(context)),
                      ),
                      child: Text(
                        L.t(label),
                        style: TextStyle(
                          color: isActive
                              ? Colors.black
                              : AppColors.primary(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                ? _emptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      return _orderCard(orders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? '';

    final idRaw = order['id']?.toString() ?? '';
    final shortId = idRaw.length >= 6 ? idRaw.substring(0, 6) : idRaw;

    final total = double.tryParse(order['total']?.toString() ?? '');

    final createdAtRaw = order['created_at']?.toString() ?? '';
    String timeFormatted = '';
    if (createdAtRaw.isNotEmpty) {
      try {
        final parsed = DateTime.parse(createdAtRaw).toLocal();
        final hour = parsed.hour == 0 ? 12 : (parsed.hour > 12 ? parsed.hour - 12 : parsed.hour);
        final amPm = parsed.hour >= 12 ? 'PM' : 'AM';
        final minutes = parsed.minute.toString().padLeft(2, '0');
        timeFormatted = '$hour:$minutes $amPm';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: _statusColor(status),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '#$shortId',
                              style: TextStyle(
                                color: AppColors.primary(context),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (timeFormatted.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.access_time_rounded, size: 14, color: AppColors.textGrey(context)),
                              const SizedBox(width: 3),
                              Text(
                                timeFormatted,
                                style: TextStyle(
                                  color: AppColors.textGrey(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Icon(_statusIcon(status), color: _statusColor(status)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(order['users']?['name'] ?? L.t('guest')),
                    const SizedBox(height: 6),
                    Text(
                      '${L.t('currency')} ${total?.toStringAsFixed(2) ?? order['total']}',
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        L.t(status).toUpperCase(),
                        style: TextStyle(
                          color: _statusColor(status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailsScreen(order: order),
                            ),
                          ).then((value) {
                            if (value == true) {
                              fetchOrders();
                            }
                          });
                        },
                        child: Text(L.t('view_order')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 60,
            color: AppColors.textGrey(context),
          ),
          const SizedBox(height: 16),
          Text(
            L.t('no_orders_found'),
            style: TextStyle(color: AppColors.textGrey(context)),
          ),
        ],
      ),
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
