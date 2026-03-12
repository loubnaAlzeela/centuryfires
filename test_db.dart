import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://vznqsmzqvliarvfcpaaq.supabase.co', 'sb_publishable_ns6I2P9dNdnQ2lcbsajFFg_VdGT4K0I');
  
  try {
    final res = await supabase.from('driver_order_details_view').select().limit(1).single();
    print('View: ');
    print(res);
  } catch (e) {
    print('Error profiles: ');
    print(e);
  }
}
