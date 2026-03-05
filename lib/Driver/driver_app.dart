import 'package:flutter/material.dart';
import 'screens/driver_home_screen.dart';
import 'screens/driver_orders_screen.dart';
import 'screens/driver_profile_screen.dart';
import '../../theme/app_colors.dart';
import '../../utils/l.dart';

class DriverApp extends StatefulWidget {
  const DriverApp({super.key});

  @override
  State<DriverApp> createState() => _DriverAppState();
}

class _DriverAppState extends State<DriverApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DriverHomeScreen(),
    DriverOrdersScreen(),
    DriverProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(
          top: BorderSide(
            color: AppColors.textGrey(context).withValues(alpha: 0.2),
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.card(context),
        selectedItemColor: AppColors.primary(context),
        unselectedItemColor: AppColors.textGrey(context),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: L.t('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2_outlined),
            activeIcon: const Icon(Icons.inventory_2),
            label: L.t('orders'),
          ),

          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: L.t('profile'),
          ),
        ],
      ),
    );
  }
}
