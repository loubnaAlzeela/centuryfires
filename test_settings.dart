import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://vznqsmzqvliarvfcpaaq.supabase.co', 'sb_publishable_ns6I2P9dNdnQ2lcbsajFFg_VdGT4K0I');
  
  try {
    final settings = await supabase
          .from('restaurant_settings')
          .select()
          .limit(1)
          .single();
    print('Settings: ');
    print(settings);

    final tiers = await supabase.from('loyalty_tiers').select();
    print('Tiers: ');
    print(tiers);
  } catch (e) {
    print('Error: ');
    print(e);
  }
}
