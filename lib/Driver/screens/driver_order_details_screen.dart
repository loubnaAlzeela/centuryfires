import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../utils/l.dart';
import '../../utils/language_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'driver_map_screen.dart';

class DriverOrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const DriverOrderDetailsScreen({super.key, required this.orderId});

  @override
  State<DriverOrderDetailsScreen> createState() =>
      _DriverOrderDetailsScreenState();
}

class _DriverOrderDetailsScreenState extends State<DriverOrderDetailsScreen> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? order;
  bool loading = true;

  //=====================================
  Color _dynamicOutlineColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.primary(context) : Colors.black;
  }

  ButtonStyle _dynamicOutlinedStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: _dynamicOutlineColor(),
      side: BorderSide(color: _dynamicOutlineColor()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      if (mounted) setState(() => loading = true);
      print('Update finished');
      final res = await supabase
          .from('driver_order_details_view')
          .select('*')
          .eq('id', widget.orderId)
          .single();

      if (!mounted) return;

      setState(() {
        order = res;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      debugPrint('DriverOrderDetails _loadOrder error: $e');
    }
  }

  // ================= UPDATE STATUS =================
  Future<void> _updateStatus(String newStatus) async {
    if (order == null) return;

    final orderId = (order!['id']).toString();

    try {
      if (mounted) setState(() => loading = true);

      debugPrint('START UPDATE -> $newStatus , orderId=$orderId');

      final res = await supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId)
          .select('id,status');

      debugPrint('UPDATE RESPONSE: $res');

      await _loadOrder();
    } on PostgrestException catch (e) {
      debugPrint(
        'UPDATE PostgrestException: ${e.message} | ${e.details} | ${e.code}',
      );
    } catch (e, st) {
      debugPrint('UPDATE ERROR: $e');
      debugPrint('STACK: $st');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ================= STATUS INDEX =================
  int _statusIndex(String status) {
    final s = status.toString();

    switch (s) {
      case 'accepted':
        return 0;
      case 'picked_up':
        return 1;

      // دعم القيمتين لنفس المرحلة
      case 'on_the_way':
      case 'out_for_delivery':
        return 2;

      // دعم القيمتين لنفس المرحلة
      case 'delivered':
      case 'completed':
        return 3;

      default:
        return 0;
    }
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    if (loading || order == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.primary(context),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black, // ← هون التعديل
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L.t('order_details'),
              style: TextStyle(
                color: Colors.black, // اختياري إذا بدك العنوان كمان أسود
              ),
            ),
            Text(
              (order?['order_number'] ?? '').toString(),
              style: const TextStyle(color: Colors.black, fontSize: 13),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _pickupCard(),
                  const SizedBox(height: 16),
                  _customerCard(),
                  const SizedBox(height: 16),
                  _itemsCard(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          _bottomButtons(),
        ],
      ),
    );
  }

  // ================= STEPPER =================
  Widget _buildStepper() {
    final steps = ['accepted', 'picked_up', 'on_the_way', 'delivered'];
    final current = _statusIndex(order?['status'] ?? '');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      color: AppColors.primary(context),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          // ===== STEP CIRCLE =====
          if (index.isEven) {
            final stepIndex = index ~/ 2;
            final active = stepIndex <= current;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: active
                      ? AppColors.bg(context)
                      : AppColors.textOnPrimary(context).withValues(alpha: .3),
                  child: Icon(
                    Icons.check,
                    size: 18,
                    color: active
                        ? AppColors.primary(context)
                        : AppColors.textOnPrimary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  L.t(steps[stepIndex]),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textOnPrimary(context),
                  ),
                ),
              ],
            );
          }

          // ===== CONNECTING LINE =====
          final lineIndex = (index - 1) ~/ 2;
          final active = lineIndex < current;

          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: active
                  ? AppColors.bg(context)
                  : AppColors.textOnPrimary(context).withValues(alpha: .3),
            ),
          );
        }),
      ),
    );
  }

  // ================= PICKUP =================
  Widget _pickupCard() {
    final isArabic = LanguageController.isArabic.value;
    final phone = order?['phone'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.t('pickup_from'),
            style: TextStyle(color: AppColors.textGrey(context)),
          ),
          const SizedBox(height: 6),
          Text(
            isArabic ? (order?['name_ar'] ?? '') : (order?['name_en'] ?? ''),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order?['restaurant_address'] ?? '',
            style: TextStyle(color: AppColors.textHint(context)),
          ),
          const SizedBox(height: 12),

          // زر الاتصال
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _call(phone),
              icon: const Icon(Icons.phone),
              label: Text(L.t('call')),

              style: _dynamicOutlinedStyle(),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CUSTOMER =================
  Widget _customerCard() {
    final phone = order?['customer_phone'] ?? '';
    final lat = order?['lat'];
    final lng = order?['lng'];
    final preferred = order?['preferred_contact'] ?? 'phone';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.t('deliver_to'),
            style: TextStyle(
              color: AppColors.text(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            order?['customer_name'] ?? '',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.text(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${order?['area'] ?? ''} - ${order?['street'] ?? ''} - ${order?['building'] ?? ''}',
            style: TextStyle(color: AppColors.textHint(context)),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              if (preferred == 'phone') ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _call(phone),
                    icon: const Icon(Icons.phone),
                    label: Text(L.t('call')),
                    style: _dynamicOutlinedStyle(),
                  ),
                ),
              ],

              if (preferred == 'whatsapp') ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openWhatsApp(phone),
                    icon: const Icon(Icons.chat),
                    label: Text(L.t('whatsapp')),
                    style: _dynamicOutlinedStyle(),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final session = Supabase.instance.client.auth.currentSession;
                if (session == null) return;

                final userRes = await Supabase.instance.client
                    .from('users')
                    .select('id')
                    .eq('auth_id', session.user.id)
                    .single();

                final String driverUserId = userRes['id'].toString();

                if (!context.mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverMapScreen(
                      orderId: widget.orderId, // ✅ هون الصح
                      driverUserId: driverUserId,
                      customerLat: (lat as num).toDouble(),
                      customerLng: (lng as num).toDouble(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.navigation, color: Colors.black),
              label: Text(
                L.t('navigate'),
                style: const TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ITEMS =================
  Widget _itemsCard() {
    final items = order?['order_items'] ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= Items =================
          ...List.generate(items.length, (i) {
            final item = items[i];
            final mealName = LanguageController.isArabic.value
                ? item['meal_name_ar']
                : item['meal_name_en'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item['quantity']}x $mealName',
                    style: TextStyle(color: AppColors.text(context)),
                  ),
                  Text(
                    (item['total_price'] ?? 0).toString(),
                    style: TextStyle(color: AppColors.text(context)),
                  ),
                ],
              ),
            );
          }),

          const Divider(),

          // ================= Prices =================
          _priceRow(L.t('subtotal'), order?['subtotal']),
          _priceRow(L.t('delivery_fee'), order?['delivery_fee']),
          _priceRow(L.t('total'), order?['total'], bold: true),

          const SizedBox(height: 12),

          // ================= Payment Method =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bg(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  _getPaymentIcon(order?['payment_method']),
                  color: AppColors.primary(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getPaymentLabel(order?['payment_method']),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.text(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //===================================================
  IconData _getPaymentIcon(String? method) {
    switch (method) {
      case 'cash':
        return Icons.payments;
      case 'visa':
        return Icons.credit_card;
      case 'apple_pay':
        return Icons.phone_iphone;
      case 'google_pay':
        return Icons.account_balance_wallet;
      default:
        return Icons.receipt_long;
    }
  }

  String _getPaymentLabel(String? method) {
    switch (method) {
      case 'cash':
        return L.t('cash_on_delivery');
      case 'visa':
        return "Visa / MasterCard";
      case 'apple_pay':
        return "Apple Pay";
      case 'google_pay':
        return "Google Pay";
      default:
        return L.t('payment_method');
    }
  }

  //============================================================
  Future<void> _call(String phone) async {
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final Uri url = Uri.parse("https://wa.me/$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  //=========================================================================
  Widget _priceRow(String label, dynamic value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: AppColors.text(context),
          ),
        ),
        Text(
          (value ?? 0).toString(),
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? AppColors.primary(context) : AppColors.text(context),
          ),
        ),
      ],
    );
  }

  // ================= BOTTOM BUTTONS =================
  Widget _bottomButtons() {
    final status = (order?['status'] ?? '').toString();

    // ✅ اعتبر completed = delivered (نفس الفكرة)
    final isDone = status == 'delivered' || status == 'completed';
    if (isDone) return const SizedBox();

    String buttonText = '';
    String? nextStatus;

    if (status == 'accepted') {
      buttonText = L.t('confirm_pickup');
      nextStatus = 'picked_up';
    } else if (status == 'picked_up') {
      buttonText = L.t('start_delivery');
      // ✅ هون المهم: خليها تكتب نفس قيمة الداتابيز
      nextStatus = 'out_for_delivery'; // بدل on_the_way
    } else if (status == 'on_the_way' || status == 'out_for_delivery') {
      buttonText = L.t('mark_delivered');
      nextStatus = 'delivered';
    }

    // إذا status غير معروف لا تعرض زر فاضي
    if (nextStatus == null || buttonText.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.bg(context),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary(context),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () => _updateStatus(nextStatus!),
          child: Text(
            buttonText,
            style: TextStyle(
              color: Colors.black, // على الأصفر أفضل
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
