class AdminSettingsModel {
  // ================= Restaurant Info =================
  final String nameEn;
  final String nameAr;
  final String phone;
  final String email;
  final String address;
  // ================= Social Media =================
  final String instagramUrl;
  final bool instagramEnabled;

  final String tiktokUrl;
  final bool tiktokEnabled;

  final String facebookUrl;
  final bool facebookEnabled;

  // ================= Working Hours =================
  final String openingTime; // "10:00 AM"
  final String closingTime; // "11:00 PM"
  final List<int> workingDays; // 1..7 (Mon..Sun) or your own mapping

  // ================= Delivery =================
  final int deliveryRadiusKm;
  final double deliveryFee;
  final double minOrderAmount;
  final double freeDeliveryMinimum;

  // ================= Order =================
  final int defaultPrepTimeMin;
  final bool autoAcceptOrders;

  // ================= Payments =================
  final bool payVisaMaster;
  final bool payApplePay;
  final bool payGooglePay;
  final bool payCashOnDelivery;

  const AdminSettingsModel({
    required this.nameEn,
    required this.nameAr,
    required this.phone,
    required this.email,
    required this.address,
    required this.openingTime,
    required this.closingTime,
    required this.workingDays,
    required this.deliveryRadiusKm,
    required this.deliveryFee,
    required this.minOrderAmount,
    required this.freeDeliveryMinimum,
    required this.defaultPrepTimeMin,
    required this.autoAcceptOrders,
    required this.payVisaMaster,
    required this.payApplePay,
    required this.payGooglePay,
    required this.payCashOnDelivery,
    required this.instagramUrl,
    required this.instagramEnabled,
    required this.tiktokUrl,
    required this.tiktokEnabled,
    required this.facebookUrl,
    required this.facebookEnabled,
  });

  factory AdminSettingsModel.defaults() {
    return const AdminSettingsModel(
      nameEn: 'Century Fries',
      nameAr: 'سنشري فرايز',
      phone: '',
      email: '',
      address: '',
      openingTime: '10:00 AM',
      closingTime: '11:00 PM',
      workingDays: [1, 2, 3, 4, 5, 6, 7],
      deliveryRadiusKm: 10,
      deliveryFee: 15,
      minOrderAmount: 30,
      freeDeliveryMinimum: 0,
      defaultPrepTimeMin: 20,
      autoAcceptOrders: false,
      payVisaMaster: true,
      payApplePay: true,
      payGooglePay: true,
      payCashOnDelivery: true,
      instagramUrl: '',
      instagramEnabled: false,

      tiktokUrl: '',
      tiktokEnabled: false,

      facebookUrl: '',
      facebookEnabled: false,
    );
  }

  AdminSettingsModel copyWith({
    String? nameEn,
    String? nameAr,
    String? phone,
    String? email,
    String? address,
    String? openingTime,
    String? closingTime,
    List<int>? workingDays,
    int? deliveryRadiusKm,
    double? deliveryFee,
    double? minOrderAmount,
    double? freeDeliveryMinimum,
    int? defaultPrepTimeMin,
    bool? autoAcceptOrders,
    bool? payVisaMaster,
    bool? payApplePay,
    bool? payGooglePay,
    bool? payCashOnDelivery,
    String? instagramUrl,
    bool? instagramEnabled,
    String? tiktokUrl,
    bool? tiktokEnabled,
    String? facebookUrl,
    bool? facebookEnabled,
  }) {
    return AdminSettingsModel(
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      workingDays: workingDays ?? this.workingDays,
      deliveryRadiusKm: deliveryRadiusKm ?? this.deliveryRadiusKm,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      freeDeliveryMinimum: freeDeliveryMinimum ?? this.freeDeliveryMinimum,
      defaultPrepTimeMin: defaultPrepTimeMin ?? this.defaultPrepTimeMin,
      autoAcceptOrders: autoAcceptOrders ?? this.autoAcceptOrders,
      payVisaMaster: payVisaMaster ?? this.payVisaMaster,
      payApplePay: payApplePay ?? this.payApplePay,
      payGooglePay: payGooglePay ?? this.payGooglePay,
      payCashOnDelivery: payCashOnDelivery ?? this.payCashOnDelivery,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      instagramEnabled: instagramEnabled ?? this.instagramEnabled,

      tiktokUrl: tiktokUrl ?? this.tiktokUrl,
      tiktokEnabled: tiktokEnabled ?? this.tiktokEnabled,

      facebookUrl: facebookUrl ?? this.facebookUrl,
      facebookEnabled: facebookEnabled ?? this.facebookEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name_en': nameEn,
      'name_ar': nameAr,
      'phone': phone,
      'email': email,
      'address': address,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'working_days': workingDays,
      'delivery_radius_km': deliveryRadiusKm,
      'delivery_fee': deliveryFee,
      'min_order_amount': minOrderAmount,
      'free_delivery_minimum': freeDeliveryMinimum,
      'default_prep_time_min': defaultPrepTimeMin,
      'auto_accept_orders': autoAcceptOrders,
      'pay_visa_master': payVisaMaster,
      'pay_apple_pay': payApplePay,
      'pay_google_pay': payGooglePay,
      'pay_cash_on_delivery': payCashOnDelivery,
      'instagram_url': instagramUrl,
      'instagram_enabled': instagramEnabled,

      'tiktok_url': tiktokUrl,
      'tiktok_enabled': tiktokEnabled,

      'facebook_url': facebookUrl,
      'facebook_enabled': facebookEnabled,
    };
  }

  factory AdminSettingsModel.fromJson(Map<String, dynamic> json) {
    return AdminSettingsModel(
      nameEn: (json['name_en'] ?? '') as String,
      nameAr: (json['name_ar'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      openingTime: (json['opening_time'] ?? '10:00 AM') as String,
      closingTime: (json['closing_time'] ?? '11:00 PM') as String,
      workingDays: List<int>.from(
        (json['working_days'] ?? [1, 2, 3, 4, 5, 6, 7]) as List,
      ),
      deliveryRadiusKm: (json['delivery_radius_km'] ?? 10) as int,
      deliveryFee: ((json['delivery_fee'] ?? 0) as num).toDouble(),
      minOrderAmount: ((json['min_order_amount'] ?? 0) as num).toDouble(),
      freeDeliveryMinimum: ((json['free_delivery_minimum'] ?? 0) as num)
          .toDouble(),
      defaultPrepTimeMin: (json['default_prep_time_min'] ?? 20) as int,
      autoAcceptOrders: (json['auto_accept_orders'] ?? false) as bool,
      payVisaMaster: (json['pay_visa_master'] ?? true) as bool,
      payApplePay: (json['pay_apple_pay'] ?? true) as bool,
      payGooglePay: (json['pay_google_pay'] ?? true) as bool,
      payCashOnDelivery: (json['pay_cash_on_delivery'] ?? true) as bool,
      instagramUrl: (json['instagram_url'] ?? '') as String,
      instagramEnabled: (json['instagram_enabled'] ?? false) as bool,

      tiktokUrl: (json['tiktok_url'] ?? '') as String,
      tiktokEnabled: (json['tiktok_enabled'] ?? false) as bool,

      facebookUrl: (json['facebook_url'] ?? '') as String,
      facebookEnabled: (json['facebook_enabled'] ?? false) as bool,
    );
  }
}
