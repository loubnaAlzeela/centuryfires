import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPromotionsService {
  final _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getPromotions() async {
    final res = await _client.from('promotions').select().order('priority');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> toggleActive(String id, bool value) async {
    await _client.from('promotions').update({'is_active': value}).eq('id', id);
  }

  Future<void> deletePromotion(String id) async {
    await _client.from('promotions').delete().eq('id', id);
  }
}
