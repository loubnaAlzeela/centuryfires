class OrderViewModel {
  final String id;
  final String status;
  final String? orderNumber;

  final String? customerName;
  final String? customerPhone;

  final String? area;
  final String? street;

  final double? lat;
  final double? lng;

  // ✅ new
  final String? imageUrl; // first meal image
  final int itemsCount;
  final int pointsEarned;

  // (اختياري للتفاصيل تحت الخريطة)
  final double subtotal;
  final double discount;
  final double discountCoupon;
  final double discountBigOrder;
  final String? appliedCouponCode;
  final double deliveryFee;
  final double total;
  final String? paymentMethod;
  final DateTime? createdAt;

  // JSON items
  final List<Map<String, dynamic>> orderItems;

  OrderViewModel({
    required this.id,
    required this.status,
    this.orderNumber,
    this.customerName,
    this.customerPhone,
    this.area,
    this.street,
    this.lat,
    this.lng,

    this.imageUrl,
    required this.itemsCount,
    required this.pointsEarned,

    required this.subtotal,
    required this.discount,
    this.discountCoupon = 0,
    this.discountBigOrder = 0,
    this.appliedCouponCode,
    required this.deliveryFee,
    required this.total,
    this.paymentMethod,
    this.createdAt,

    required this.orderItems,
  });

  factory OrderViewModel.fromMap(Map<String, dynamic> map) {
    final rawItems = map['order_items'];

    List<Map<String, dynamic>> items = [];
    if (rawItems is List) {
      items = rawItems.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    return OrderViewModel(
      id: map['id']?.toString() ?? '',
      status: (map['status'] ?? '').toString(),
      orderNumber: map['order_number']?.toString(),

      customerName: map['customer_name']?.toString(),
      customerPhone: map['customer_phone']?.toString(),

      area: map['area']?.toString(),
      street: map['street']?.toString(),

      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),

      imageUrl: map['first_meal_image_url']?.toString(),
      itemsCount: (map['items_count'] as num?)?.toInt() ?? 0,
      pointsEarned: (map['points_earned'] as num?)?.toInt() ?? 0,

      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      discountCoupon: (map['discount_coupon'] as num?)?.toDouble() ?? 0,
      discountBigOrder: (map['discount_big_order'] as num?)?.toDouble() ?? 0,
      appliedCouponCode: map['applied_coupon_code']?.toString(),
      deliveryFee: (map['driver_fee'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,

      orderItems: items,
    );
  }
}
