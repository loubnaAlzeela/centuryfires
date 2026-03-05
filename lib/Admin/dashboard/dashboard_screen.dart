import 'package:flutter/material.dart';

import 'widgets/dashboard_stats.dart';
import 'widgets/dashboard_orders_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        DashboardStats(),
        SizedBox(height: 24),

        // 👇 الودجت نفسه صار مسؤول عن realtime + الصوت
        DashboardOrdersWidget(),
      ],
    );
  }
}
