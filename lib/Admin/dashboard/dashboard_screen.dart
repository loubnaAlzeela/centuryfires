import 'package:flutter/material.dart';

import '../navigation/admin_page.dart';
import 'widgets/dashboard_stats.dart';
import 'widgets/dashboard_orders_widget.dart';

class DashboardScreen extends StatelessWidget {
  final void Function(AdminPage)? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DashboardStats(onNavigate: onNavigate),
        const SizedBox(height: 24),

        // 👇 الودجت نفسه صار مسؤول عن realtime + الصوت
        DashboardOrdersWidget(),
      ],
    );
  }
}
