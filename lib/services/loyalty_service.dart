import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/language_controller.dart';

class LoyaltyState {
  final int points;
  final int totalOrders;
  final String tierName;
  final int currentTierMinPoints;
  final int nextTierPoints;
  final String nextTierName;

  const LoyaltyState({
    required this.points,
    required this.totalOrders,
    required this.tierName,
    required this.currentTierMinPoints,
    required this.nextTierPoints,
    required this.nextTierName,
  });

  double get progress {
    if (nextTierPoints <= currentTierMinPoints) return 1.0;

    final earned = points - currentTierMinPoints;
    final required = nextTierPoints - currentTierMinPoints;

    if (required <= 0) {
      debugPrint(
        '⚠️ Invalid tier configuration: '
        'next=$nextTierPoints, current=$currentTierMinPoints',
      );
      return 1.0;
    }

    return (earned / required).clamp(0.0, 1.0);
  }

  bool get isMaxTier => nextTierPoints <= currentTierMinPoints;
}

class LoyaltyService {
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _cachedUserId;

  // ================= USER ID =================

  Future<String> _getInternalUserId() async {
    if (_cachedUserId != null) return _cachedUserId!;

    final authUser = _supabase.auth.currentUser;
    if (authUser == null) {
      throw Exception('User not authenticated');
    }

    final userRow = await _supabase
        .from('users')
        .select('id')
        .eq('auth_id', authUser.id)
        .maybeSingle();

    if (userRow == null) {
      throw Exception('User not found in database');
    }

    _cachedUserId = userRow['id'] as String;
    return _cachedUserId!;
  }

  // ================= MAIN =================

  Future<LoyaltyState> getLoyaltyState() async {
    try {
      return await _fetchLoyaltyState();
    } catch (_) {
      return await _getDefaultStateFromDB();
    }
  }

  Future<LoyaltyState> _fetchLoyaltyState() async {
    final userId = await _getInternalUserId();

    final ul = await _supabase
        .from('user_loyalty')
        .select('points, total_orders, tier_id')
        .eq('user_id', userId)
        .maybeSingle();

    if (ul == null) {
      return await _createDefaultLoyalty();
    }

    final int points = (ul['points'] as num?)?.toInt() ?? 0;
    final int totalOrders = (ul['total_orders'] as num?)?.toInt() ?? 0;
    final String tierId = ul['tier_id'];

    // ===== current tier =====
    final tier = await _supabase
        .from('loyalty_tiers')
        .select('name_ar, name_en, min_points')
        .eq('id', tierId)
        .maybeSingle();

    if (tier == null) {
      return await _getDefaultStateFromDB();
    }

    final int currentMinPoints = (tier['min_points'] as num?)?.toInt() ?? 0;

    final String tierName =
        (LanguageController.ar ? tier['name_ar'] : tier['name_en'])
            ?.toString()
            .toUpperCase() ??
        'UNKNOWN';

    // ===== next tier =====
    final next = await _supabase
        .from('loyalty_tiers')
        .select('name_ar, name_en, min_points')
        .gt('min_points', currentMinPoints)
        .order('min_points', ascending: true)
        .limit(1)
        .maybeSingle();

    if (next == null) {
      return LoyaltyState(
        points: points,
        totalOrders: totalOrders,
        tierName: tierName,
        currentTierMinPoints: currentMinPoints,
        nextTierName: tierName,
        nextTierPoints: currentMinPoints,
      );
    }

    final String nextTierName =
        (LanguageController.ar ? next['name_ar'] : next['name_en'])
            ?.toString()
            .toUpperCase() ??
        tierName;

    final int nextTierPoints =
        (next['min_points'] as num?)?.toInt() ?? currentMinPoints;

    return LoyaltyState(
      points: points,
      totalOrders: totalOrders,
      tierName: tierName,
      currentTierMinPoints: currentMinPoints,
      nextTierName: nextTierName,
      nextTierPoints: nextTierPoints,
    );
  }

  // ================= CREATE DEFAULT =================

  Future<LoyaltyState> _createDefaultLoyalty() async {
    final userId = await _getInternalUserId();

    final firstTier = await _supabase
        .from('loyalty_tiers')
        .select('id')
        .order('min_points', ascending: true)
        .limit(1)
        .maybeSingle();

    if (firstTier == null) {
      return _getDefaultState();
    }

    await _supabase.from('user_loyalty').insert({
      'user_id': userId,
      'tier_id': firstTier['id'],
      'points': 0,
      'total_orders': 0,
    });

    return await _getDefaultStateFromDB();
  }

  // ================= DEFAULT FROM DB =================

  Future<LoyaltyState> _getDefaultStateFromDB() async {
    final tiers = await _supabase
        .from('loyalty_tiers')
        .select('name_ar, name_en, min_points')
        .order('min_points', ascending: true)
        .limit(2);

    if (tiers.isEmpty) return _getDefaultState();

    final first = tiers.first;
    final second = tiers.length > 1 ? tiers[1] : first;

    final String firstName =
        (LanguageController.ar ? first['name_ar'] : first['name_en'])
            ?.toString()
            .toUpperCase() ??
        'BRONZE';

    final String secondName =
        (LanguageController.ar ? second['name_ar'] : second['name_en'])
            ?.toString()
            .toUpperCase() ??
        firstName;

    return LoyaltyState(
      points: 0,
      totalOrders: 0,
      tierName: firstName,
      currentTierMinPoints: (first['min_points'] as num?)?.toInt() ?? 0,
      nextTierName: secondName,
      nextTierPoints: (second['min_points'] as num?)?.toInt() ?? 0,
    );
  }

  // ================= HARD FALLBACK =================

  LoyaltyState _getDefaultState() {
    return const LoyaltyState(
      points: 0,
      totalOrders: 0,
      tierName: 'BRONZE',
      currentTierMinPoints: 0,
      nextTierName: 'SILVER',
      nextTierPoints: 250,
    );
  }

  void clearCache() {
    _cachedUserId = null;
  }
}
