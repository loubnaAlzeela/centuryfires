import '../settings/model/admin_settings_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSettingsService {
  // ✅ Fetch settings
  final _supabase = Supabase.instance.client;

  Future<AdminSettingsModel> getSettings() async {
    final row = await _supabase
        .from('restaurant_settings')
        .select()
        .limit(1)
        .maybeSingle();

    if (row == null) {
      return AdminSettingsModel.defaults();
    }

    return AdminSettingsModel.fromJson(row);
  }

  Future<void> saveSettings(AdminSettingsModel settings) async {
    final existing = await _supabase
        .from('restaurant_settings')
        .select('id')
        .limit(1)
        .maybeSingle();

    if (existing == null) {
      await _supabase.from('restaurant_settings').insert(settings.toJson());
    } else {
      await _supabase
          .from('restaurant_settings')
          .update(settings.toJson())
          .eq('id', existing['id']);
    }
  }
}
