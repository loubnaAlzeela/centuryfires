import 'package:supabase_flutter/supabase_flutter.dart';

class AdminCustomerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchCustomers() async {
    final response = await _supabase.from('admin_customers_view').select();

    return List<Map<String, dynamic>>.from(response);
  }
}
