import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/l.dart';

class MealSizesTab extends StatefulWidget {
  final String mealId;

  const MealSizesTab({super.key, required this.mealId});

  @override
  State<MealSizesTab> createState() => _MealSizesTabState();
}

class _MealSizesTabState extends State<MealSizesTab> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _sizes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSizes();
  }

  Future<void> _loadSizes() async {
    setState(() => _loading = true);

    final data = await _supabase
        .from('meal_sizes')
        .select()
        .eq('meal_id', widget.mealId)
        .order('sort_order');

    _sizes = List<Map<String, dynamic>>.from(data);

    setState(() => _loading = false);
  }

  Future<void> _deleteSize(String id) async {
    await _supabase.from('meal_sizes').delete().eq('id', id);

    _loadSizes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary(context),
        onPressed: () {
          // لاحقًا منضيف شاشة Add/Edit
        },
        child: Icon(Icons.add, color: Colors.black),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sizes.isEmpty
          ? Center(child: Text(L.t('no_sizes_found')))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sizes.length,
              itemBuilder: (context, index) {
                final size = _sizes[index];

                return Card(
                  color: AppColors.card(context),
                  child: ListTile(
                    title: Text(
                      size['size_name_en'] ?? '',
                      style: TextStyle(color: AppColors.text(context)),
                    ),
                    subtitle: Text(
                      '${L.t('price_label')}: ${size['price']}',
                      style: TextStyle(color: AppColors.textGrey(context)),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteSize(size['id'].toString()),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
