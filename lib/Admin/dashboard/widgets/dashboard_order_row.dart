import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/l.dart';

class DashboardOrderRow extends StatelessWidget {
  final String orderId;
  final String status;
  final String time;

  const DashboardOrderRow({
    super.key,
    required this.orderId,
    required this.status,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.trim().toLowerCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Column 1: Name
          Expanded(
            flex: 4,
            child: Text(
              orderId,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _statusColor(normalizedStatus),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Column 2: Time
          Expanded(
            flex: 2,
            child: Text(
              time,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textGrey(context),
                fontSize: 12,
              ),
            ),
          ),

          // Column 3: Status Badge
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: _statusBadge(context, normalizedStatus),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(BuildContext context, String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        L.t(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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
}
