import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';

class CategoryService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<CategoryModel>> getCategories() async {
    final data = await _client
        .from('categories')
        .select()
        .eq('is_active', true) // مهم جدًا
        .order('sort_order', ascending: true);

    return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
  }
}
