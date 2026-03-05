class OrderModel {
  // ================= BASIC =================
  final String id;
  final double total;
  final String status;
  final DateTime createdAt;

  // ================= LOYALTY =================
  final int points;

  // ================= UI / SUMMARY =================
  /// اسم أول وجبة بالطلب
  final String? title;

  /// صورة أول وجبة (جاي من meals.image_url)
  final String? imageUrl;

  /// عدد العناصر بالطلب
  final int itemsCount;

  const OrderModel({
    required this.id,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.points,
    this.title,
    this.imageUrl,
    this.itemsCount = 0,
  });

  // ================= HELPERS =================
  bool get isDelivered => status == 'delivered';

  // ================= FACTORY =================
  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id']?.toString() ?? '',
      total: double.tryParse(map['total']?.toString() ?? '0') ?? 0.0,
      status: _validateStatus(map['status']),
      createdAt: _parseCreatedAt(map['created_at']),
      points: int.tryParse(map['points']?.toString() ?? '0') ?? 0,
      title: map['title']?.toString(),
      imageUrl: _validateImageUrl(map['image_url']),
      itemsCount: int.tryParse(map['items_count']?.toString() ?? '0') ?? 0,
    );
  }

  // ================= INTERNAL HELPERS =================
  static String _validateStatus(dynamic status) {
    const validStatuses = [
      'pending',
      'confirmed',
      'preparing',
      'ready',
      'delivered',
      'cancelled',
    ];

    final value = status?.toString().toLowerCase();
    return validStatuses.contains(value) ? value! : 'pending';
  }

  static DateTime _parseCreatedAt(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    // نرجّع epoch بدل now حتى نعرف إن في مشكلة بالداتا
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String? _validateImageUrl(dynamic url) {
    final value = url?.toString().trim();
    if (value == null || value.isEmpty) return null;
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      return null;
    }
    return value;
  }
}
