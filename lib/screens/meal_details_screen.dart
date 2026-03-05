import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/meal_model.dart';
import '../models/meal_size_model.dart';
import '../models/addon_model.dart';

import '../theme/app_colors.dart';
import '../utils/cart_controller.dart';
import '../utils/l.dart';
import '../utils/language_controller.dart';
import 'package:flutter/services.dart';

class MealDetailsScreen extends StatefulWidget {
  final MealModel meal;

  const MealDetailsScreen({super.key, required this.meal});

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen>
    with TickerProviderStateMixin {
  // ================= STATE =================
  List<MealSizeModel> mealSizes = [];
  MealSizeModel? selectedSize;
  bool isLoadingSizes = true;
  List<AddonModel> mealAddons = [];
  Set<String> selectedAddonIds = {};
  int quantity = 1;

  List<AddonModel> extraAddons = [];
  List<AddonModel> removalAddons = [];

  Set<String> selectedExtraIds = {};
  Set<String> selectedRemovalIds = {};

  bool isLoadingAddons = true;

  // ================= PRICE =================
  double get totalPrice {
    double price = widget.meal.basePrice.toDouble();

    if (selectedSize != null) {
      price += selectedSize!.price.toDouble();
    }

    // السعر فقط للإضافات extra
    for (final addon in extraAddons) {
      if (selectedExtraIds.contains(addon.id)) {
        price += addon.price.toDouble();
      }
    }

    return price;
  }

  @override
  void initState() {
    super.initState();
    _loadMealSizes();
    _loadMealAddons();
  }

  // ================= LOAD SIZES =================
  Future<void> _loadMealSizes() async {
    try {
      final supabase = Supabase.instance.client;

      final res = await supabase
          .from('meal_sizes')
          .select()
          .eq('meal_id', widget.meal.id)
          .order('is_default', ascending: false);

      final list = (res as List)
          .map((e) => MealSizeModel.fromMap(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;

      setState(() {
        mealSizes = list;
        selectedSize = list.isNotEmpty ? list.first : null;
        isLoadingSizes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoadingSizes = false);
    }
  }

  // ================= LOAD ADDONS =================
  Future<void> _loadMealAddons() async {
    try {
      final supabase = Supabase.instance.client;

      final res = await supabase
          .from('meal_addons')
          .select(
            'addons ( id, addon_name_ar, addon_name_en, price, is_active, type )',
          )
          .eq('meal_id', widget.meal.id);

      final rows = res as List;
      final list = <AddonModel>[];

      for (final row in rows) {
        final addonMap = row['addons'];
        if (addonMap == null) continue;

        final addon = AddonModel.fromMap(Map<String, dynamic>.from(addonMap));

        if (addon.isActive) {
          list.add(addon);
        }
      }

      if (!mounted) return;

      setState(() {
        mealAddons = list;
        extraAddons = list.where((a) => a.type == 'extra').toList();

        removalAddons = list.where((a) => a.type == 'removal').toList();

        isLoadingAddons = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoadingAddons = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSizes = mealSizes.isNotEmpty;

    return ValueListenableBuilder<bool>(
      valueListenable: LanguageController.isArabic,
      builder: (context, isArabic, _) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: AppColors.bg(context),
            body: Column(
              children: [
                // ================= IMAGE =================
                Stack(
                  children: [
                    Hero(
                      tag: 'meal_${widget.meal.id}',
                      child: Image.network(
                        widget.meal.image ?? '',
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 280,
                          width: double.infinity,
                          color: AppColors.card(context),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported,
                            color: AppColors.textGrey(context),
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),

                // ================= CONTENT =================
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      20,
                      20,
                      20,
                      20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NAME
                        Text(
                          widget.meal.displayName(isArabic),
                          style: TextStyle(
                            color: AppColors.text(context),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // DESCRIPTION
                        if (widget.meal.displayDescription(isArabic) != null &&
                            widget.meal
                                .displayDescription(isArabic)!
                                .trim()
                                .isNotEmpty)
                          Text(
                            widget.meal.displayDescription(isArabic)!,
                            style: TextStyle(
                              color: AppColors.textGrey(context),
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),

                        const SizedBox(height: 12),

                        // BASE PRICE
                        Text(
                          '${widget.meal.basePrice} SAR',
                          style: TextStyle(
                            color: AppColors.primary(context),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // ================= SIZES =================
                        if (!isLoadingSizes && hasSizes) ...[
                          const SizedBox(height: 28),
                          Text(
                            L.t('choose_size'),
                            style: TextStyle(
                              color: AppColors.text(context),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...mealSizes.map((size) {
                            return RadioListTile<MealSizeModel>(
                              value: size,
                              groupValue: selectedSize,
                              activeColor: AppColors.primary(context),
                              title: Text(size.displayName(isArabic)),
                              secondary: Text(
                                size.price == 0
                                    ? L.t('included')
                                    : '+${size.price} SAR',
                                textDirection: TextDirection.ltr,
                              ),
                              onChanged: (value) {
                                setState(() => selectedSize = value);
                              },
                            );
                          }),
                        ],

                        // ================= REMOVALS =================
                        if (!isLoadingAddons && removalAddons.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Text(
                            L.t('customize'),
                            style: TextStyle(
                              color: AppColors.text(context),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...removalAddons.map((addon) {
                            return CheckboxListTile(
                              value: selectedRemovalIds.contains(addon.id),
                              activeColor: AppColors.primary(context),
                              title: Text(addon.displayName(isArabic)),
                              onChanged: (checked) {
                                setState(() {
                                  checked == true
                                      ? selectedRemovalIds.add(addon.id)
                                      : selectedRemovalIds.remove(addon.id);
                                });
                              },
                            );
                          }),
                        ],

                        // ================= EXTRAS =================
                        if (!isLoadingAddons && extraAddons.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Text(
                            L.t('extras'),
                            style: TextStyle(
                              color: AppColors.text(context),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...extraAddons.map((addon) {
                            return CheckboxListTile(
                              value: selectedExtraIds.contains(addon.id),
                              activeColor: AppColors.primary(context),
                              title: Text(addon.displayName(isArabic)),
                              secondary: Text(
                                '+${addon.price} SAR',
                                textDirection: TextDirection.ltr,
                              ),
                              onChanged: (checked) {
                                setState(() {
                                  checked == true
                                      ? selectedExtraIds.add(addon.id)
                                      : selectedExtraIds.remove(addon.id);
                                });
                              },
                            );
                          }),
                        ],

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),

                // ================= BOTTOM BAR =================
                // ================= BOTTOM BAR =================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 🔹 Quantity Selector (عرض ثابت)
                      SizedBox(
                        width: 120,
                        height: 48,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppColors.primary(context),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (quantity > 1) {
                                    setState(() => quantity--);
                                  }
                                },
                                icon: const Icon(Icons.remove),
                                color: AppColors.primary(context),
                              ),
                              Text(
                                quantity.toString(),
                                style: TextStyle(
                                  color: AppColors.text(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() => quantity++);
                                },
                                icon: const Icon(Icons.add),
                                color: AppColors.primary(context),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 🔹 Add To Cart Button (ياخد باقي الشاشة)
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: _AnimatedBottomCartButton(
                            totalPrice: totalPrice,
                            quantity: quantity,
                            onTap: () {
                              final selectedExtras = extraAddons
                                  .where((a) => selectedExtraIds.contains(a.id))
                                  .toList();

                              final selectedRemovals = removalAddons
                                  .where(
                                    (a) => selectedRemovalIds.contains(a.id),
                                  )
                                  .toList();

                              // نجمعهم كلهم
                              final allSelectedAddons = [
                                ...selectedExtras,
                                ...selectedRemovals,
                              ];

                              CartController.instance.addLine(
                                mealId: widget.meal.id,
                                name: widget.meal.displayName(
                                  LanguageController.isArabic.value,
                                ),
                                price: totalPrice,
                                imageUrl: widget.meal.image,
                                mealSizeId: selectedSize?.id,
                                mealSizeName: selectedSize?.displayName(
                                  LanguageController.isArabic.value,
                                ),
                                addonIds: allSelectedAddons
                                    .map((a) => a.id)
                                    .toList(),
                                addonNames: allSelectedAddons
                                    .map(
                                      (a) => a.displayName(
                                        LanguageController.isArabic.value,
                                      ),
                                    )
                                    .toList(),
                                quantity: quantity,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedBottomCartButton extends StatefulWidget {
  final VoidCallback onTap;
  final double totalPrice;
  final int quantity;

  const _AnimatedBottomCartButton({
    required this.onTap,
    required this.totalPrice,
    required this.quantity,
  });

  @override
  State<_AnimatedBottomCartButton> createState() =>
      _AnimatedBottomCartButtonState();
}

class _AnimatedBottomCartButtonState extends State<_AnimatedBottomCartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dropAnimation;
  late Animation<double> _bounceAnimation;

  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _dropAnimation = Tween<double>(
      begin: -25,
      end: 8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1, curve: Curves.elasticOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isAnimating) return;

    setState(() => _isAnimating = true);

    HapticFeedback.lightImpact();

    widget.onTap();

    await _controller.forward();
    await _controller.reverse();

    if (mounted) {
      setState(() => _isAnimating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary(context),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              if (!_isAnimating) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        color: AppColors.textOnPrimary(context),
                        size: 20,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        // 👈 أهم تعديل
                        child: Text(
                          '${(widget.totalPrice * widget.quantity).toStringAsFixed(2)} SAR',
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textOnPrimary(context),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: _bounceAnimation.value,
                    child: Icon(
                      Icons.shopping_cart,
                      color: AppColors.textOnPrimary(context),
                      size: 26,
                    ),
                  ),
                  Positioned(
                    top: _dropAnimation.value,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.textOnPrimary(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
