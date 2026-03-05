import 'package:supabase_flutter/supabase_flutter.dart';

class AddressService {
  final _client = Supabase.instance.client;

  String? _cachedUserId;

  /// ============================
  /// 🔐 Get Internal User ID (with cache)
  /// ============================
  Future<String> _getInternalUserId() async {
    if (_cachedUserId != null) return _cachedUserId!;

    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Not logged in');
    }

    final userRow = await _client
        .from('users')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();

    if (userRow == null) {
      throw Exception('User not found in database');
    }

    _cachedUserId = userRow['id'] as String;
    return _cachedUserId!;
  }

  /// ============================
  /// 📦 Get Addresses
  /// ============================
  Future<List<Map<String, dynamic>>> getAddresses() async {
    final userId = await _getInternalUserId();

    final data = await _client
        .from('user_addresses')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);

    // تنظيف null values
    return data.map<Map<String, dynamic>>((row) {
      return {
        'id': row['id'],
        'user_id': row['user_id'],
        'title': row['title'] ?? '',
        'city': row['city'] ?? '',
        'area': row['area'] ?? '',
        'street': row['street'] ?? '',
        'building': row['building'] ?? '',
        'apartment': row['apartment'] ?? '',
        'notes': row['notes'] ?? '',
        'is_default': row['is_default'] == true,
        'created_at': row['created_at'],
      };
    }).toList();
  }

  /// ============================
  /// ➕ Add Address
  /// ============================
  Future<String> addAddress(Map<String, dynamic> data) async {
    final userId = await _getInternalUserId();

    // whitelist الحقول
    final sanitized = {
      'title': data['title']?.toString().trim(),
      'city': data['city']?.toString().trim(),
      'area': data['area']?.toString().trim(),
      'street': data['street']?.toString().trim(),
      'building': data['building']?.toString().trim(),
      'apartment': data['apartment']?.toString().trim(),
      'notes': data['notes']?.toString().trim(),
      'is_default': data['is_default'] == true,
      'lat': data['lat'],
      'lng': data['lng'],
      'user_id': userId,
    };

    // Validation أساسي
    final title = sanitized['title'] as String?;
    if (title == null || title.isEmpty) {
      throw Exception('Title is required');
    }

    final city = sanitized['city'] as String?;
    if (city == null || city.isEmpty) {
      throw Exception('City is required');
    }

    final area = sanitized['area'] as String?;
    if (area == null || area.isEmpty) {
      throw Exception('Area is required');
    }

    final street = sanitized['street'] as String?;
    if (street == null || street.isEmpty) {
      throw Exception('Street is required');
    }

    // إذا default → صفّر الباقي
    if (sanitized['is_default'] == true) {
      await _client
          .from('user_addresses')
          .update({'is_default': false})
          .eq('user_id', userId);
    }

    final result = await _client
        .from('user_addresses')
        .insert(sanitized)
        .select('id')
        .single();

    return result['id'] as String;
  }

  /// ============================
  /// ✏️ Update Address
  /// ============================
  Future<void> updateAddress(
    String addressId,
    Map<String, dynamic> data,
  ) async {
    final userId = await _getInternalUserId();

    final sanitized = {
      'title': data['title']?.toString().trim(),
      'city': data['city']?.toString().trim(),
      'area': data['area']?.toString().trim(),
      'street': data['street']?.toString().trim(),
      'building': data['building']?.toString().trim(),
      'apartment': data['apartment']?.toString().trim(),
      'notes': data['notes']?.toString().trim(),
      'is_default': data['is_default'] == true,
      'lat': data['lat'],
      'lng': data['lng'],
    };

    // إذا default → صفّر الباقي
    if (sanitized['is_default'] == true) {
      await _client
          .from('user_addresses')
          .update({'is_default': false})
          .eq('user_id', userId);
    }

    // 🔒 تحقق من المالك
    final result = await _client
        .from('user_addresses')
        .update(sanitized)
        .eq('id', addressId)
        .eq('user_id', userId)
        .select();

    if (result.isEmpty) {
      throw Exception('Address not found or unauthorized');
    }
  }

  /// ============================
  /// 🗑 Delete Address
  /// ============================
  Future<void> deleteAddress(String addressId) async {
    final userId = await _getInternalUserId();

    // تحقق من الملكية + معرفة إذا كان default
    final address = await _client
        .from('user_addresses')
        .select('id, is_default')
        .eq('id', addressId)
        .eq('user_id', userId)
        .maybeSingle();

    if (address == null) {
      throw Exception('Address not found or unauthorized');
    }

    final wasDefault = address['is_default'] == true;

    await _client
        .from('user_addresses')
        .delete()
        .eq('id', addressId)
        .eq('user_id', userId);

    // إذا كان default → اجعل أول عنوان آخر default
    if (wasDefault) {
      final remaining = await _client
          .from('user_addresses')
          .select('id')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (remaining.isNotEmpty) {
        await _client
            .from('user_addresses')
            .update({'is_default': true})
            .eq('id', remaining.first['id'])
            .eq('user_id', userId);
      }
    }
  }

  /// ============================
  /// 🧹 Clear Cache (call on logout)
  /// ============================
  void clearCache() {
    _cachedUserId = null;
  }
}
