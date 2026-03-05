import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../utils/cart_controller.dart';
import '../utils/address_controller.dart';
import '../utils/l.dart';

class AppHeader extends StatelessWidget {
  final String restaurantName;

  const AppHeader({super.key, required this.restaurantName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Image.asset(
                  "assets/images/branding/splash_logo.png",
                  width: 42,
                ),
                const SizedBox(width: 12),

                // ===== Restaurant Name + Address =====
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName.isEmpty
                          ? L.t('app_header_brand')
                          : restaurantName,
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    FutureBuilder(
                      future: AddressController.instance.loadDefaultAddress(),
                      builder: (context, snapshot) {
                        return Text(
                          '📍 ${AddressController.instance.displayText}',
                          style: TextStyle(
                            color: AppColors.textGrey(context),
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const Spacer(),

                // ===== Cart =====
                AnimatedBuilder(
                  animation: CartController.instance,
                  builder: (context, _) {
                    final cartCount = CartController.instance.count;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        );
                      },
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 28,
                              color: AppColors.text(context),
                            ),
                            if (cartCount > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary(context),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    cartCount.toString(),
                                    style: TextStyle(
                                      color: AppColors.textOnPrimary(context),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 8),

                // ===== Profile =====
                IconButton(
                  icon: Icon(
                    Icons.person_outline,
                    color: AppColors.text(context),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
