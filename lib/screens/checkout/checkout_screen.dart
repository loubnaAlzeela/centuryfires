import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../services/address_service.dart';
import '../../services/coupon_service.dart';
import '../../utils/cart_controller.dart';
import '../profile/saved_addresses_screen.dart';
import '../order_success_screen.dart';
import '../../utils/app_error_type.dart';
import '../auth/login_signup_screen.dart';
import '../../utils/l.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // ================= ORDER =================
  String orderType = 'delivery';
  String paymentMethod = 'cash';

  double minOrderAmount = 0;
  double freeDeliveryMinimum = 0;
  bool autoAcceptOrders = false;
  bool _minOrderError = false;
  bool enableVisaMaster = false;
  bool enableApplePay = false;
  bool enableGooglePay = false;
  bool enableCashOnDelivery = true;
  // ================= LOYALTY =================
  bool tierFreeDelivery = false;
  bool isLoadingTier = true;
  // ================= COUPON (كما هو) =================
  final TextEditingController couponCtrl = TextEditingController();
  bool couponApplied = false;
  double discount = 0;
  bool isApplyingCoupon = false;

  // ================= ADDRESS =================
  Map<String, dynamic>? selectedAddress;
  bool isLoadingAddress = true;

  bool isPlacingOrder = false;

  // ================= PRICING =================
  double get subtotal => CartController.instance.subtotal;
  // أضف هذا المتغير داخل _CheckoutPageState
  double deliveryFee = 0;
  bool isLoadingSettings = true;

  double get effectiveDeliveryFee {
    if (orderType != 'delivery') return 0;
    // 🔥 لو الفئة فيها توصيل مجاني
    if (tierFreeDelivery) return 0;

    if (subtotal >= freeDeliveryMinimum && freeDeliveryMinimum > 0) {
      return 0;
    }

    return deliveryFee;
  }

  double get total =>
      subtotal + effectiveDeliveryFee - discount - bigOrderDiscount;

  //=========== Big order Discount ====================
  double bigOrderDiscount = 0;
  bool isCheckingBigOrder = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadUserTier();
    _loadDefaultAddress();
    _validateCartOnInit();
    _checkBigOrderDiscount();
  }

  /// 🔎 تحقق مبكر من السلة
  void _validateCartOnInit() {
    if (CartController.instance.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showError(AppErrorType.general, customMessage: L.t('cart_empty'));
          Navigator.pop(context);
        }
      });
    }
  }

  // ================= LOAD DEFAULT ADDRESS =================
  Future<void> _loadDefaultAddress() async {
    final supabase = Supabase.instance.client;

    // ✅ إذا المستخدم غير مسجل دخول لا نظهر خطأ
    if (supabase.auth.currentUser == null) {
      if (mounted) {
        setState(() => isLoadingAddress = false);
      }
      return;
    }

    try {
      final addresses = await AddressService().getAddresses();
      if (addresses.isNotEmpty) {
        selectedAddress = addresses.first;
      }
    } catch (_) {
      // ❌ لا نعرض رسالة خطأ هنا
      // لأن الخطأ غالباً سببه عدم تسجيل الدخول
    } finally {
      if (mounted) {
        setState(() => isLoadingAddress = false);
      }
    }
  }

  //=====================================================
  Future<void> _loadSettings() async {
    try {
      final supabase = Supabase.instance.client;

      final settings = await supabase
          .from('restaurant_settings')
          .select(
            'delivery_fee, min_order_amount, free_delivery_minimum, auto_accept_orders,pay_visa_master,pay_apple_pay,pay_google_pay,pay_cash_on_delivery',
          )
          .limit(1)
          .single();

      final rawFee = settings['delivery_fee'];
      final rawMin = settings['min_order_amount'];
      final rawFree = settings['free_delivery_minimum'];

      final parsedFee = rawFee is num
          ? rawFee.toDouble()
          : double.tryParse('$rawFee') ?? 0;

      final parsedMin = rawMin is num
          ? rawMin.toDouble()
          : double.tryParse('$rawMin') ?? 0;

      final parsedFree = rawFree is num
          ? rawFree.toDouble()
          : double.tryParse('$rawFree') ?? 0;

      setState(() {
        deliveryFee = parsedFee;
        minOrderAmount = parsedMin;
        freeDeliveryMinimum = parsedFree;
        autoAcceptOrders = settings['auto_accept_orders'] == true;
        enableVisaMaster = settings['pay_visa_master'] == true;
        enableApplePay = settings['pay_apple_pay'] == true;
        enableGooglePay = settings['pay_google_pay'] == true;
        enableCashOnDelivery = settings['pay_cash_on_delivery'] == true;
      });
    } catch (e) {
      debugPrint('SETTINGS ERROR: $e');
      setState(() {
        deliveryFee = 0;
        minOrderAmount = 0;
        freeDeliveryMinimum = 0;
      });
    } finally {
      if (mounted) {
        setState(() => isLoadingSettings = false);
      }
    }
  }

  //===========================================
  Future<void> _loadUserTier() async {
    final supabase = Supabase.instance.client;
    final authUser = supabase.auth.currentUser;

    if (authUser == null) {
      setState(() => isLoadingTier = false);
      return;
    }

    try {
      final userRow = await supabase
          .from('users')
          .select('id')
          .eq('auth_id', authUser.id)
          .single();

      final userId = userRow['id'];

      final loyalty = await supabase
          .from('user_loyalty')
          .select('tier_id, loyalty_tiers(free_delivery)')
          .eq('user_id', userId)
          .maybeSingle();

      if (loyalty != null && loyalty['loyalty_tiers'] != null) {
        final tier = loyalty['loyalty_tiers'];

        setState(() {
          tierFreeDelivery = tier['free_delivery'] == true;
        });
      }
    } catch (e) {
      debugPrint("TIER LOAD ERROR: $e");
    } finally {
      if (mounted) {
        setState(() => isLoadingTier = false);
      }
    }
  }

  // ================= BUILD FULL ADDRESS =================
  String buildFullAddress(Map<String, dynamic> a) {
    final parts = [
      a['city'],
      a['area'],
      a['street'],
      if ((a['building'] ?? '').toString().isNotEmpty)
        '${L.t('bldg')} ${a['building']}',
      if ((a['floor'] ?? '').toString().isNotEmpty)
        '${L.t('floor')} ${a['floor']}',
    ];
    return parts.join(', ');
  }

  // ================= COUPON (كما كان) =================
  Future<void> applyCoupon() async {
    if (couponCtrl.text.trim().isEmpty) return;
    if (isApplyingCoupon) return;

    setState(() => isApplyingCoupon = true);

    try {
      final result = await CouponService().applyCoupon(
        code: couponCtrl.text.trim(),
        subtotal: subtotal,
      );

      setState(() {
        discount = result;
        couponApplied = true;
      });
    } catch (e) {
      _showError(AppErrorType.general, customMessage: L.t('invalid_coupon'));

      setState(() {
        couponApplied = false;
        discount = 0;
      });
    }
  }

  // ================= BIG ORDER =================
  Future<void> _checkBigOrderDiscount() async {
    if (isCheckingBigOrder) return;

    setState(() => isCheckingBigOrder = true);

    try {
      final supabase = Supabase.instance.client;

      final promo = await supabase
          .from('promotions')
          .select()
          .eq('promotion_type', 'big_order')
          .eq('is_active', true)
          .eq('auto_apply', true)
          .lte('min_order_amount', subtotal)
          .maybeSingle();

      if (promo != null) {
        double calculated = 0;

        if (promo['discount_type'] == 'percentage') {
          final percent = (promo['discount_value'] ?? 0).toDouble();
          calculated = subtotal * (percent / 100);
        } else if (promo['discount_type'] == 'fixed') {
          calculated = (promo['discount_value'] ?? 0).toDouble();
        }

        // تطبيق max_discount إذا موجود
        if (promo['max_discount'] != null) {
          final max = (promo['max_discount'] ?? 0).toDouble();
          if (max > 0 && calculated > max) {
            calculated = max;
          }
        }

        setState(() {
          bigOrderDiscount = calculated;
        });
      } else {
        setState(() {
          bigOrderDiscount = 0;
        });
      }
    } catch (e) {
      bigOrderDiscount = 0;
    } finally {
      if (mounted) {
        setState(() => isCheckingBigOrder = false);
      }
    }
  }

  void removeCoupon() {
    setState(() {
      discount = 0;
      couponApplied = false;
      couponCtrl.clear();
    });
  }

  // ================= PLACE ORDER =================
  Future<void> placeOrder() async {
    final supabase = Supabase.instance.client;

    if (!_validateOrder()) return;

    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginSignupScreen()),
      );
      return;
    }

    if (isPlacingOrder) return;
    setState(() => isPlacingOrder = true);

    try {
      // ================= USER =================
      final userRow = await supabase
          .from('users')
          .select('id')
          .eq('auth_id', authUser.id)
          .single();

      final userId = userRow['id'];

      // ================= ORDER STATUS (FAST VERSION) =================
      final bool isOnlinePayment =
          paymentMethod == 'card' ||
          paymentMethod == 'apple' ||
          paymentMethod == 'google';

      final String orderStatus = isOnlinePayment
          ? 'awaiting_payment'
          : (autoAcceptOrders ? 'confirmed' : 'pending');

      // ================= INSERT ORDER =================
      final order = await supabase
          .from('orders')
          .insert({
            'user_id': userId,
            'address_id': orderType == 'delivery'
                ? selectedAddress!['id']
                : null,
            'status': orderStatus,
            'subtotal': subtotal,
            'discount': discount + bigOrderDiscount,
            'total': total,
            'payment_method': paymentMethod,
          })
          .select()
          .single();

      final orderId = order['id'];

      // ================= INSERT ITEMS =================
      // ================= INSERT ITEMS (SAFE BATCH VERSION) =================
      final itemsPayload = CartController.instance.lines.map((line) {
        return {
          'order_id': orderId,
          'meal_id': line.mealId,
          'meal_size_id': line.mealSizeId,
          'quantity': line.quantity,
          'unit_price': line.price,
          'total_price': line.total,
        };
      }).toList();

      await supabase.from('order_items').insert(itemsPayload);

      await CartController.instance.clear();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
      );
    } catch (e) {
      debugPrint('ORDER ERROR: $e');
      _showError(AppErrorType.general);
    } finally {
      if (mounted) {
        setState(() => isPlacingOrder = false);
      }
    }
  }

  /// ✅ تحقق الطلب
  bool _validateOrder() {
    // Reset error state أولاً
    _minOrderError = false;

    if (CartController.instance.isEmpty || subtotal <= 0) {
      _showError(AppErrorType.general, customMessage: L.t('cart_empty'));
      return false;
    }

    if (orderType == 'delivery') {
      if (selectedAddress == null) {
        _showError(
          AppErrorType.general,
          customMessage: L.t('select_delivery_address'),
        );
        return false;
      }

      debugPrint('CHECK MIN ORDER: subtotal=$subtotal min=$minOrderAmount');

      // ✅ شرط الحد الأدنى
      if (minOrderAmount > 0 && subtotal < minOrderAmount) {
        setState(() {
          _minOrderError = true;
        });
        return false;
      }
    }

    return true;
  }

  // ================= ERROR =================
  void _showError(AppErrorType type, {String? customMessage}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(customMessage ?? _errorMessage(type)),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _errorMessage(AppErrorType type) {
    switch (type) {
      case AppErrorType.unauthorized:
        return L.t('login_required_to_order');
      case AppErrorType.network:
        return L.t('err_network');
      default:
        return L.t('err_general');
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (isLoadingSettings) {
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary(context)),
        ),
      );
    }
    return WillPopScope(
      onWillPop: () async {
        if (isPlacingOrder) {
          _showError(
            AppErrorType.general,
            customMessage: L.t('please_wait_order_processing'),
          );
          return false;
        }
        return true;
      },

      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        appBar: AppBar(
          title: Text(L.t('checkout')),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(L.t('how_order')),
              _orderTypeTile(L.t('delivery'), L.t('delivery_desc'), 'delivery'),
              _orderTypeTile(L.t('pickup'), L.t('pickup_desc'), 'pickup'),
              _orderTypeTile(L.t('dinein'), L.t('dinein_desc'), 'dine_in'),

              const SizedBox(height: 24),

              if (orderType == 'delivery') ...[
                _sectionTitle(L.t('delivery_address')),
                _addressCard(),
                const SizedBox(height: 24),
              ],

              _sectionTitle(L.t('payment_method')),
              if (enableCashOnDelivery)
                _paymentTile(L.t('cash'), L.t('cash_desc'), 'cash'),

              if (enableVisaMaster)
                _paymentTile(
                  'Visa / MasterCard',
                  'Pay using your card',
                  'card',
                ),

              if (enableApplePay)
                _paymentTile('Apple Pay', 'Secure Apple payment', 'apple'),

              if (enableGooglePay)
                _paymentTile('Google Pay', 'Secure Google payment', 'google'),

              const SizedBox(height: 24),

              _sectionTitle(L.t('coupon')),
              couponApplied ? _appliedCoupon() : _couponInput(),

              const SizedBox(height: 32),

              _sectionTitle(L.t('order_summary')),
              _summaryRow(
                L.t('subtotal'),
                '${subtotal.toStringAsFixed(2)} SAR',
              ),
              if (orderType == 'delivery')
                _summaryRow(
                  L.t('delivery_fee'),
                  '${effectiveDeliveryFee.toStringAsFixed(2)} SAR',
                ),
              if (discount > 0)
                _summaryRow(
                  L.t('discount'),
                  '-${discount.toStringAsFixed(2)} SAR',
                ),
              if (bigOrderDiscount > 0)
                _summaryRow(
                  L.t('big_order_discount'),
                  '-${bigOrderDiscount.toStringAsFixed(2)} SAR',
                ),
              const Divider(),
              _summaryRow(
                L.t('total'),
                '${total.toStringAsFixed(2)} SAR',
                isTotal: true,
              ),

              const SizedBox(height: 24),
              if (_minOrderError)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.error(context)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${L.t('min_order_not_met')} (${minOrderAmount.toStringAsFixed(0)} SAR)',
                          style: TextStyle(
                            color: AppColors.error(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary(context),
                    foregroundColor: Colors.black,
                  ),

                  onPressed: isPlacingOrder ? null : placeOrder,
                  child: Text(
                    isPlacingOrder ? L.t('placing_order') : L.t('place_order'),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HELPERS =================
  Widget _couponInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: couponCtrl,
            decoration: InputDecoration(hintText: L.t('enter_coupon')),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: isApplyingCoupon ? null : applyCoupon,
          child: Text(isApplyingCoupon ? L.t('loading') : L.t('apply')),
        ),
      ],
    );
  }

  Widget _appliedCoupon() {
    return _cardWrapper(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '${L.t('coupon_applied')} (-${discount.toStringAsFixed(2)} SAR)',
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : null,
              color: isTotal ? AppColors.primary(context) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardWrapper({required Widget child, bool selected = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primary(context) : Colors.grey.shade800,
        ),
      ),
      child: child,
    );
  }

  Widget _orderTypeTile(String title, String subtitle, String value) {
    final selected = orderType == value;
    return _cardWrapper(
      selected: selected,
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500)),
        trailing: selected
            ? Icon(Icons.check_circle, color: AppColors.primary(context))
            : null,
        onTap: () => setState(() => orderType = value),
      ),
    );
  }

  Widget _paymentTile(String title, String subtitle, String value) {
    final selected = paymentMethod == value;
    return _cardWrapper(
      selected: selected,
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500)),
        trailing: selected
            ? Icon(Icons.check_circle, color: AppColors.primary(context))
            : null,
        onTap: () => setState(() => paymentMethod = value),
      ),
    );
  }

  Widget _addressCard() {
    if (isLoadingAddress) {
      return const CircularProgressIndicator();
    }

    return _cardWrapper(
      child: ListTile(
        title: Text(selectedAddress?['title'] ?? L.t('no_address')),
        subtitle: Text(
          selectedAddress != null
              ? buildFullAddress(selectedAddress!)
              : L.t('select_address'),
          style: TextStyle(color: Colors.grey.shade500),
        ),
        trailing: TextButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
            );
            if (result != null) {
              setState(() => selectedAddress = result);
            }
          },
          child: Text(L.t('change')),
        ),
      ),
    );
  }
}
