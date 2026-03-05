import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_loyalty_model.dart';

class ProfileService {
  final _client = Supabase.instance.client;

  Future<UserLoyaltyModel> getUserLoyalty() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final userRow = await _client
        .from('users')
        .select('id')
        .eq('auth_id', user.id)
        .single();

    final data = await _client
        .from('user_loyalty')
        .select('points, total_orders, loyalty_tiers(name, min_points)')
        .eq('user_id', userRow['id'])
        .single();

    return UserLoyaltyModel.fromMap(data);
  }
}
