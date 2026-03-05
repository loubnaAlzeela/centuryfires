import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// =======================
/// 🧾 CART LINE (SAFE)
/// =======================
class CartLine {
  final String id;
  final String mealId;

  final String name;
  final double price;
  final String? imageUrl;

  final String? mealSizeId;
  final String? mealSizeName;

  final List<String> addonIds;
  final List<String> addonNames;

  int quantity;

  CartLine({
    required this.id,
    required this.mealId,
    required this.name,
    required this.price,
    this.imageUrl,
    this.mealSizeId,
    this.mealSizeName,
    required this.addonIds,
    required this.addonNames,
    this.quantity = 1,
  });

  double get total => price * quantity;

  String? get subtitle {
    final parts = <String>[];
    if (mealSizeName != null && mealSizeName!.isNotEmpty) {
      parts.add(mealSizeName!);
    }
    if (addonNames.isNotEmpty) {
      parts.add(addonNames.join(', '));
    }
    return parts.isEmpty ? null : parts.join(' • ');
  }

  /// =======================
  /// JSON (STRICT + SAFE)
  /// =======================
  factory CartLine.fromJson(Map<String, dynamic> json) {
    final mealId = (json['mealId'] ?? '').toString();
    if (mealId.isEmpty) {
      throw Exception('Invalid cart line: mealId missing');
    }

    final rawPrice = (json['price'] as num?)?.toDouble() ?? 0.0;
    if (!rawPrice.isFinite || rawPrice < 0) {
      throw Exception('Invalid price: $rawPrice');
    }

    final rawQuantity = (json['quantity'] as num?)?.toInt() ?? 1;
    final safeQuantity = rawQuantity > 0 ? rawQuantity : 1;

    return CartLine(
      id: (json['id'] ?? '').toString(),
      mealId: mealId,
      name: (json['name'] ?? '').toString(),
      price: rawPrice,
      imageUrl: json['imageUrl']?.toString(),
      mealSizeId: json['mealSizeId']?.toString(),
      mealSizeName: json['mealSizeName']?.toString(),
      addonIds: List<String>.from(json['addonIds'] ?? const []),
      addonNames: List<String>.from(json['addonNames'] ?? const []),
      quantity: safeQuantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mealId': mealId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'mealSizeId': mealSizeId,
      'mealSizeName': mealSizeName,
      'addonIds': addonIds,
      'addonNames': addonNames,
      'quantity': quantity,
    };
  }
}

/// =======================
/// 🛒 CART CONTROLLER
/// =======================
class CartController extends ChangeNotifier {
  CartController._();
  static final instance = CartController._();

  final Map<String, CartLine> _lines = {};

  bool _loaded = false;
  bool _loading = false;

  Timer? _saveTimer;

  static const int maxQuantityPerItem = 99;
  static const int maxCartSizeBytes = 100000;

  /// =======================
  /// LOAD CART (SAFE)
  /// =======================
  Future<void> loadCart() async {
    if (_loaded || _loading) return;
    _loading = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cart_lines');

      if (raw != null && raw.isNotEmpty) {
        // 🔒 JSON bomb protection
        if (raw.length > maxCartSizeBytes) {
          await prefs.remove('cart_lines');
        } else {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            _lines.clear();
            decoded.forEach((key, value) {
              try {
                _lines[key] = CartLine.fromJson(
                  Map<String, dynamic>.from(value),
                );
              } catch (_) {
                // ❌ Skip corrupted line
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Cart load failed: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cart_lines');
      _lines.clear();
    } finally {
      _loaded = true;
      _loading = false;
    }

    notifyListeners();
  }

  /// =======================
  /// SAVE (DEBOUNCED)
  /// =======================
  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _saveCart);
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cart_lines',
        jsonEncode(_lines.map((k, v) => MapEntry(k, v.toJson()))),
      );
    } catch (e) {
      debugPrint('❌ Failed to save cart: $e');
    }
  }

  /// =======================
  /// GETTERS
  /// =======================
  List<CartLine> get lines => _lines.values.toList();
  int get count => _lines.values.fold(0, (s, l) => s + l.quantity);
  double get subtotal => _lines.values.fold(0.0, (s, l) => s + l.total);
  bool get isEmpty => _lines.isEmpty;

  /// =======================
  /// SAFE LINE ID (NO COLLISION)
  /// =======================
  String buildLineId({
    required String mealId,
    String? mealSizeId,
    required List<String> addonIds,
  }) {
    final sortedAddons = [...addonIds]..sort();
    return [mealId, mealSizeId ?? '∅', sortedAddons.join('§')].join('¦');
  }

  /// =======================
  /// ADD LINE
  /// =======================
  void addLine({
    required String mealId,
    required String name,
    required double price,
    String? imageUrl,
    String? mealSizeId,
    String? mealSizeName,
    required List<String> addonIds,
    required List<String> addonNames,
    int quantity = 1,
  }) {
    if (mealId.isEmpty || !price.isFinite || price < 0) return;

    final safeQuantity = quantity > 0 ? quantity : 1;

    final id = buildLineId(
      mealId: mealId,
      mealSizeId: mealSizeId,
      addonIds: addonIds,
    );

    if (_lines.containsKey(id)) {
      _lines[id]!.quantity += safeQuantity;
      if (_lines[id]!.quantity > maxQuantityPerItem) {
        _lines[id]!.quantity = maxQuantityPerItem;
      }
    } else {
      _lines[id] = CartLine(
        id: id,
        mealId: mealId,
        name: name,
        price: price,
        imageUrl: imageUrl,
        mealSizeId: mealSizeId,
        mealSizeName: mealSizeName,
        addonIds: List<String>.from(addonIds),
        addonNames: List<String>.from(addonNames),
        quantity: safeQuantity > maxQuantityPerItem
            ? maxQuantityPerItem
            : safeQuantity,
      );
    }

    _scheduleSave();
    notifyListeners();
  }

  /// =======================
  /// CLEAR
  /// =======================
  Future<void> clear() async {
    _lines.clear();
    _saveTimer?.cancel();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cart_lines');
    } catch (e) {
      debugPrint('❌ Failed to clear cart: $e');
    }

    // ❗ لا نغير _loaded
    notifyListeners();
  }

  /// =======================
  /// INCREASE
  /// =======================
  void increase(String id) {
    if (!_lines.containsKey(id)) return;
    if (_lines[id]!.quantity >= maxQuantityPerItem) return;

    _lines[id]!.quantity += 1;
    _scheduleSave();
    notifyListeners();
  }

  /// =======================
  /// DECREASE
  /// =======================
  void decrease(String id) {
    if (!_lines.containsKey(id)) return;

    if (_lines[id]!.quantity <= 1) {
      _lines.remove(id);
    } else {
      _lines[id]!.quantity -= 1;
    }

    _scheduleSave();
    notifyListeners();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
