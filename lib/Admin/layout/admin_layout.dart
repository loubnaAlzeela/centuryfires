import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
import '../rewards/admin_rewards_screen.dart';
import '../analytics/analytics_screen.dart';
import '../settings/admin_settings_screen.dart';
import '../admin_profile_screen.dart';
import '../../utils/l.dart';
import '../drivers/drivers_screen.dart';
import '../../screens/home_screen.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AdminPage _currentPage = AdminPage.dashboard;

  final AudioPlayer _player = AudioPlayer();
  late final RealtimeChannel _globalOrdersChannel;
  DateTime? _lastSoundTime;

  @override
  void initState() {
    super.initState();
    _listenToNewOrdersGlobally();
  }

  void _listenToNewOrdersGlobally() {
    _globalOrdersChannel = Supabase.instance.client.channel('global_admin_orders');
    _globalOrdersChannel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            final now = DateTime.now();
            if (_lastSoundTime == null || now.difference(_lastSoundTime!).inSeconds > 2) {
              _playNotificationSound();
              _lastSoundTime = now;
            }
          },
        )
        .subscribe();
  }

  Future<void> _playNotificationSound() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(
        AssetSource('sounds/new_order.mp3'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      debugPrint("Global Sound error: $e");
    }
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_globalOrdersChannel);
    _player.dispose();
    super.dispose();
  }

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
        actions: [
          // ===== Preview Customer Home Button (AppBar action) =====
          Tooltip(
            message: L.t('preview_customer_home'),
            child: IconButton(
              icon: Icon(
                Icons.visibility_outlined,
                color: AppColors.text(context),
              ),
              onPressed: _openCustomerPreview,
            ),
          ),
        ],
      ),

      // ===== Drawer =====
      drawer: AdminSidebar(
        currentPage: _currentPage,
        onPageSelected: (page) {
          setState(() => _currentPage = page);
        },
      ),

      // ===== Body =====
      body: Column(
        children: [
          // ===== Preview Customer Home Card =====
          _buildPreviewCard(context),

          // ===== Main Page Content =====
          Expanded(
            child: AnimatedSwitcher(
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
          ),
        ],
      ),
    );
  }

  // ================= PREVIEW CARD =================
  Widget _buildPreviewCard(BuildContext context) {
    return GestureDetector(
      onTap: _openCustomerPreview,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary(context).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary(context).withOpacity(0.35),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary(context).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.visibility_outlined,
                color: AppColors.primary(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                L.t('preview_customer_home'),
                style: TextStyle(
                  color: AppColors.text(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textGrey(context),
            ),
          ],
        ),
      ),
    );
  }

  // ================= OPEN PREVIEW =================
  void _openCustomerPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HomeScreen(isPreviewMode: true)),
    );
  }

  // ================= PAGE SWITCH =================
  Widget _buildPage(AdminPage page) {
    switch (page) {
      case AdminPage.dashboard:
        return DashboardScreen(
          onNavigate: (page) => setState(() => _currentPage = page),
        );

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

      case AdminPage.rewards:
        return const AdminRewardsScreen();

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

      case AdminPage.rewards:
        return L.t('rewards');

      case AdminPage.analytics:
        return L.t('analytics');

      case AdminPage.settings:
        return L.t('Res_settings');

      case AdminPage.profile:
        return L.t('admin_profile');
    }
  }
}
