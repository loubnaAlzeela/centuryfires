import 'package:flutter/material.dart';

import '../navigation/admin_page.dart';
import '../dashboard/dashboard_screen.dart';
import 'admin_sidebar.dart';
import '../../theme/app_colors.dart';
import '../menu/menu_screen.dart';
import '../orders/orders_list_screen.dart';
import '../promotions/promotionsscreen.dart';
import '../customers/customers_screen.dart';
import '../ratings/adminreviewsscreen.dart';
import '../loyalty/admin_loyalty_screen.dart';
import '../analytics/analytics_screen.dart';
import '../settings/admin_settings_screen.dart';
import '../admin_profile_screen.dart';
import '../../utils/l.dart';
import '../drivers/drivers_screen.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AdminPage _currentPage = AdminPage.dashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg(context),

      // ===== App Bar =====
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: AppColors.text(context)),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          _titleForPage(_currentPage),
          style: TextStyle(
            color: AppColors.text(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ===== Drawer =====
      drawer: AdminSidebar(
        currentPage: _currentPage,
        onPageSelected: (page) {
          setState(() => _currentPage = page);
        },
      ),

      // ===== Body =====
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey<AdminPage>(_currentPage),
          child: _buildPage(_currentPage),
        ),
      ),
    );
  }

  // ================= PAGE SWITCH =================
  Widget _buildPage(AdminPage page) {
    switch (page) {
      case AdminPage.dashboard:
        return const DashboardScreen();

      case AdminPage.orders:
        return const OrdersListScreen();

      case AdminPage.menu:
        return const MenuScreen();

      case AdminPage.promotions:
        return const PromotionsScreen();

      case AdminPage.customers:
        return const CustomersScreen();

      case AdminPage.drivers:
        return const DriversScreen();

      case AdminPage.ratings:
        return const AdminRatingsScreen();

      case AdminPage.loyalty:
        return const AdminLoyaltyScreen();

      case AdminPage.analytics:
        return const AnalyticsScreen();

      case AdminPage.settings:
        return const AdminSettingsScreen();

      case AdminPage.profile:
        return const AdminProfileScreen();
    }
  }

  // ================= TITLE =================
  String _titleForPage(AdminPage page) {
    switch (page) {
      case AdminPage.dashboard:
        return L.t('dashboard');

      case AdminPage.orders:
        return L.t('orders');

      case AdminPage.menu:
        return L.t('menu');

      case AdminPage.promotions:
        return L.t('promotions');

      case AdminPage.customers:
        return L.t('customers');

      case AdminPage.drivers:
        return L.t('drivers');

      case AdminPage.ratings:
        return L.t('ratings');

      case AdminPage.loyalty:
        return L.t('loyalty');

      case AdminPage.analytics:
        return L.t('analytics');

      case AdminPage.settings:
        return L.t('Res_settings');

      case AdminPage.profile:
        return L.t('admin_profile');
    }
  }
}
