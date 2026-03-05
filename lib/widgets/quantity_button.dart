import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/cart_controller.dart';

class QuantityButton extends StatelessWidget {
  final String itemId;
  final int quantity;

  const QuantityButton({
    super.key,
    required this.itemId,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(
          context,
          icon: Icons.remove,
          onTap: () {
            CartController.instance.decrease(itemId); // ✅ صح
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            quantity.toString(),
            style: TextStyle(
              color: AppColors.text(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _btn(
          context,
          icon: Icons.add,
          onTap: () {
            CartController.instance.increase(itemId); // ✅ صح
          },
        ),
      ],
    );
  }

  Widget _btn(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.card(context),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.text(context)),
      ),
    );
  }
}
