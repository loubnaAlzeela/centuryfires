import 'package:supabase_flutter/supabase_flutter.dart';

class StorageHelper {
  static String? getMealImageUrl(String? imageName) {
    if (imageName == null || imageName.isEmpty) return null;

    return Supabase.instance.client.storage
        .from('meals') // اسم الـ bucket
        .getPublicUrl(imageName);
  }
}
