import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient('https://vznqsmzqvliarvfcpaaq.supabase.co', 'sb_publishable_ns6I2P9dNdnQ2lcbsajFFg_VdGT4K0I');
  
  try {
    final res = await supabase.rpc('run_sql', params: {'sql': "SELECT definition FROM pg_views WHERE viewname = 'driver_order_details_view'"});
    print(res);
  } catch (e) {
    print('Failed with run_sql. Let us try directly from pg_views if possible, probably not allowed from anon.');
    try {
        final res2 = await supabase.from('pg_views').select('definition').eq('viewname', 'driver_order_details_view');
        print(res2);
    } catch (e2) {
        print('e2: \$e2');
    }
  }
}
