import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/cart_controller.dart';
import 'quantity_button.dart';
import '../utils/l.dart';

class CartItemCard extends StatelessWidget {
  final CartLine item;

  const CartItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.bg(context),
              borderRadius: BorderRadius.circular(12),
              image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(item.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: AppColors.text(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (item.subtitle != null && item.subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      item.subtitle!,
                      style: TextStyle(
                        color: AppColors.textGrey(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (item.notes != null && item.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.edit_note,
                          size: 14,
                          color: AppColors.primary(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.notes!,
                            style: TextStyle(
                              color: AppColors.text(context),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  '${item.price.toStringAsFixed(2)} ${L.t('currency')}',
                  style: TextStyle(
                    color: AppColors.primary(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Quantity
          QuantityButton(itemId: item.id, quantity: item.quantity),
        ],
      ),
    );
  }
}
