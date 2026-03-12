import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://vznqsmzqvliarvfcpaaq.supabase.co', 'sb_publishable_ns6I2P9dNdnQ2lcbsajFFg_VdGT4K0I');
  
  try {
    final res = await supabase.rpc('get_view_definition', params: {'view_name': 'driver_order_details_view'});
    print(res);
  } catch (e) {
    print('Failed to get view definition natively. Trying to read a row from driver_order_details_view:');
    try {
      final row = await supabase.from('driver_order_details_view').select().limit(1).single();
      print(row);
    } catch(e2) {
      print(e2);
    }
  }
}
