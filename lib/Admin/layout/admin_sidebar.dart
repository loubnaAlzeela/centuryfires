import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../navigation/admin_page.dart';
import '../../theme/app_colors.dart';
import '../../screens/auth/login_signup_screen.dart';
import '../../utils/l.dart';

class AdminSidebar extends StatefulWidget {
  final AdminPage currentPage;
  final ValueChanged<AdminPage> onPageSelected;

  const AdminSidebar({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar>
    with SingleTickerProviderStateMixin {
  String restaurantName = '...';
  bool isLoading = true;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
    _loadRestaurantName();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurantName() async {
    try {
      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('restaurant_settings')
          .select('name_en')
          .limit(1)
          .maybeSingle();

      if (data != null && data['name_en'] != null) {
        setState(() {
          restaurantName = data['name_en'];
        });
      }
    } catch (e) {
      debugPrint("SIDEBAR RESTAURANT LOAD ERROR: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bg(context),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _item(
                    context,
                    AdminPage.dashboard,
                    Icons.dashboard,
                    L.t('dashboard'),
                    0,
                  ),
                  _item(
                    context,
                    AdminPage.orders,
                    Icons.receipt_long,
                    L.t('orders'),
                    1,
                  ),
                  _item(
                    context,
                    AdminPage.menu,
                    Icons.restaurant_menu,
                    L.t('menu'),
                    2,
                  ),
                  _item(
                    context,
                    AdminPage.promotions,
                    Icons.local_offer,
                    L.t('promotions'),
                    3,
                  ),
                  _item(
                    context,
                    AdminPage.customers,
                    Icons.people,
                    L.t('customers'),
                    4,
                  ),
                  _item(
                    context,
                    AdminPage.drivers,
                    Icons.local_shipping,
                    L.t('drivers'),
                    5,
                  ),
                  _item(
                    context,
                    AdminPage.ratings,
                    Icons.star_border,
                    L.t('ratings'),
                    6,
                  ),
                  _item(
                    context,
                    AdminPage.loyalty,
                    Icons.workspace_premium,
                    L.t('loyalty'),
                    7,
                  ),
                  _item(
                    context,
                    AdminPage.analytics,
                    Icons.bar_chart,
                    L.t('analytics'),
                    8,
                  ),
                  _item(
                    context,
                    AdminPage.settings,
                    Icons.settings,
                    L.t('settings'),
                    9,
                  ),
                  _item(
                    context,
                    AdminPage.profile,
                    Icons.person,
                    L.t('admin_profile'),
                    10,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animController,
                  curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: Colors.redAccent.withValues(alpha: 0.8),
                  ),
                  title: Text(
                    L.t('sign_out'),
                    style: TextStyle(
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    await Supabase.instance.client.auth.signOut();

                    if (!context.mounted) return;

                    Navigator.of(context).pop();

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const LoginSignupScreen(),
                      ),
                      (_) => false,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _animController,
                curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
              ),
            ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Image.asset(
                  'assets/images/branding/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading ? '...' : restaurantName,
                    style: TextStyle(
                      color: AppColors.text(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Admin', // 🔥 يبقى إنكليزي
                    style: TextStyle(
                      color: AppColors.textGrey(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= ITEM =================
  Widget _item(
    BuildContext context,
    AdminPage page,
    IconData icon,
    String label,
    int index,
  ) {
    final bool active = page == widget.currentPage;

    final delay = index * 0.05;
    final end = (delay + 0.4).clamp(0.0, 1.0);

    final slideAnim =
        Tween<Offset>(begin: const Offset(-0.2, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(delay, end, curve: Curves.easeOutCubic),
          ),
        );

    final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(delay, end, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Icon(
              icon,
              color: active
                  ? AppColors.primary(context)
                  : AppColors.textGrey(context),
            ),
            title: Text(
              label,
              style: TextStyle(
                color: active
                    ? AppColors.primary(context)
                    : AppColors.text(context),
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onTap: () {
              widget.onPageSelected(page);
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }
}
