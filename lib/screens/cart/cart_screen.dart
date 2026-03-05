import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/cart_item_card.dart';
import '../../utils/cart_controller.dart';
import '../checkout/checkout_screen.dart';
import '../../utils/l.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(L.t('cart_title')),
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.text(context)),
        titleTextStyle: TextStyle(
          color: AppColors.text(context),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          AnimatedBuilder(
            animation: cart,
            builder: (context, _) {
              if (cart.isEmpty) return const SizedBox.shrink();

              return TextButton.icon(
                onPressed: () {
                  cart.clear();
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: Text(
                  L.t('clear'),
                  style: const TextStyle(color: Colors.red),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: cart,
          builder: (context, _) {
            final lines = cart.lines;

            // ✅ حساب مباشر وآمن
            final double total = cart.isEmpty
                ? 0.0
                : lines
                      .fold<double>(0.0, (sum, item) => sum + item.total)
                      .clamp(0.0, double.infinity);

            return Column(
              children: [
                // ================= CART ITEMS =================
                Expanded(
                  child: lines.isEmpty
                      ? Center(
                          child: Text(
                            L.t('cart_empty'),
                            style: TextStyle(
                              color: AppColors.textGrey(context),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: lines.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CartItemCard(item: lines[index]),
                            );
                          },
                        ),
                ),

                // ================= TOTAL =================
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: _row(
                    context,
                    left: L.t('total'),
                    right: 'AED ${total.toStringAsFixed(2)}',
                    bold: true,
                    big: true,
                  ),
                ),

                // ================= CHECKOUT =================
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.065,
                    child: AppButton(
                      enabled: lines.isNotEmpty,
                      onTap: () async {
                        if (lines.isEmpty) return;

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckoutPage(),
                          ),
                        );
                      },
                      child: Center(
                        child: Text(
                          L.t('checkout_btn'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textOnPrimary(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String left,
    required String right,
    bool bold = false,
    bool big = false,
  }) {
    return Row(
      children: [
        Text(
          left,
          style: TextStyle(
            color: AppColors.textGrey(context),
            fontSize: big ? 15 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          right,
          style: TextStyle(
            color: AppColors.text(context),
            fontSize: big ? 18 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
