import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/l.dart';
import '../utils/language_controller.dart';

class OrderTypeSelector extends StatefulWidget {
  final String initialType;
  final ValueChanged<String> onChanged;

  const OrderTypeSelector({
    super.key,
    required this.initialType,
    required this.onChanged,
  });

  @override
  State<OrderTypeSelector> createState() => _OrderTypeSelectorState();
}

class _OrderTypeSelectorState extends State<OrderTypeSelector> {
  late String selectedType;

  @override
  void initState() {
    super.initState();
    selectedType = widget.initialType;
  }

  void select(String value) {
    if (value == selectedType) return;

    setState(() {
      selectedType = value;
    });

    widget.onChanged(value);
  }

  /// 🔹 position index حسب الاختيار
  int _indexOfSelected() {
    switch (selectedType) {
      case 'delivery':
        return 0;
      case 'pickup':
        return 1;
      case 'dine_in':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRtl = LanguageController.isArabic.value;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 12.0;
          final itemWidth = (constraints.maxWidth - gap * 2) / 3;
          final index = _indexOfSelected();
          final offset = index * (itemWidth + gap);

          return SizedBox(
            height: 80,
            child: Stack(
              children: [
                /// 🟡 المؤشر (RTL / LTR ذكي)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  left: isRtl ? null : offset,
                  right: isRtl ? offset : null,
                  child: Container(
                    width: itemWidth,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                /// 🧱 العناصر
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Item(
                      width: itemWidth,
                      icon: Icons.delivery_dining,
                      title: L.t('order_type_delivery'),
                      selected: selectedType == 'delivery',
                      onTap: () => select('delivery'),
                    ),
                    _Item(
                      width: itemWidth,
                      icon: Icons.storefront,
                      title: L.t('order_type_pickup'),
                      selected: selectedType == 'pickup',
                      onTap: () => select('pickup'),
                    ),
                    _Item(
                      width: itemWidth,
                      icon: Icons.restaurant,
                      title: L.t('order_type_dine_in'),
                      selected: selectedType == 'dine_in',
                      onTap: () => select('dine_in'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _Item({
    required this.width,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: selected ? Colors.transparent : AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected
                    ? AppColors.textOnPrimary(context)
                    : AppColors.text(context),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected
                      ? AppColors.textOnPrimary(context)
                      : AppColors.text(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
