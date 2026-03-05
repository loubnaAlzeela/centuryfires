import 'package:supabase_flutter/supabase_flutter.dart';

class CategoriesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getCategories() async {
    final data = await _supabase
        .from('categories')
        .select('id, name_ar, name_en')
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }
}
