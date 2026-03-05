import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../utils/l.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> drivers = [];
  bool loading = true;
  bool _loadingCustomers = false;

  String searchQuery = '';
  String filterStatus = 'all';

  int onlineCount = 0;
  int busyCount = 0;
  int offlineCount = 0;

  @override
  void initState() {
    super.initState();
    fetchDrivers();
  }

  // ================= FETCH DRIVERS =================

  Future<void> fetchDrivers() async {
    if (mounted) setState(() => loading = true);

    try {
      final res = await supabase
          .from('users')
          .select('''
            id,
            name,
            phone,
            driver_profiles (
              vehicle_type,
              plate_number,
              status,
              rating,
              total_orders,
              is_active
            )
          ''')
          .eq('role', 'driver');

      drivers = List<Map<String, dynamic>>.from(res);
      calculateStats();
    } catch (e) {
      debugPrint('fetchDrivers error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ================= CALCULATE STATS =================

  void calculateStats() {
    onlineCount = 0;
    busyCount = 0;
    offlineCount = 0;

    for (var d in drivers) {
      final profile = d['driver_profiles'];
      if (profile == null || profile['is_active'] != true) continue;

      final status = profile['status'] ?? 'offline';

      if (status == 'online') onlineCount++;
      if (status == 'busy') busyCount++;
      if (status == 'offline') offlineCount++;
    }
  }

  List<Map<String, dynamic>> get filteredDrivers {
    return drivers.where((d) {
      final name = (d['name'] ?? '').toLowerCase();
      final status = d['driver_profiles']?['status'] ?? '';

      final matchesSearch = name.contains(searchQuery.toLowerCase());
      final matchesStatus = filterStatus == 'all' || status == filterStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildHeader(),

                        const SizedBox(height: 20),

                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: isMobile ? 2 : 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: isMobile ? 1.4 : 2,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _statCard('online', onlineCount),
                            _statCard('busy', busyCount),
                            _statCard('offline', offlineCount),
                            _statCard('total', drivers.length),
                          ],
                        ),

                        const SizedBox(height: 20),

                        TextField(
                          onChanged: (val) {
                            setState(() => searchQuery = val);
                          },
                          decoration: InputDecoration(
                            hintText: L.t('search_driver'),
                            filled: true,
                            fillColor: AppColors.card(context),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppColors.textGrey(context),
                            ),
                          ),
                          style: TextStyle(color: AppColors.text(context)),
                        ),

                        const SizedBox(height: 20),

                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredDrivers.length,
                            itemBuilder: (context, index) {
                              final d = filteredDrivers[index];
                              final profile = d['driver_profiles'] ?? {};

                              return ListTile(
                                title: Text(
                                  d['name'] ?? '',
                                  style: TextStyle(
                                    color: AppColors.text(context),
                                  ),
                                ),
                                subtitle: Text(
                                  d['phone'] ?? '',
                                  style: TextStyle(
                                    color: AppColors.textGrey(context),
                                  ),
                                ),
                                trailing: Wrap(
                                  spacing: 12,
                                  children: [
                                    _statusBadge(
                                      profile['status'] ?? 'offline',
                                    ),
                                    Text(
                                      '${profile['total_orders'] ?? 0}',
                                      style: TextStyle(
                                        color: AppColors.text(context),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  // ================= HEADER (نفس الهيكل الأصلي) =================

  Widget buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                L.t('driver_management'),
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text(context),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 18,
                  vertical: isMobile ? 10 : 14,
                ),
              ),
              onPressed: _loadingCustomers ? null : _showAddDriverDialog,
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                L.t('add_driver'),
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: AppColors.textOnPrimary(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================= STATUS BADGE =================

  Color _statusColor(String status) {
    switch (status) {
      case 'online':
        return Colors.green;
      case 'busy':
        return Colors.orange;
      case 'offline':
      default:
        return Colors.grey;
    }
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(L.t(status), style: TextStyle(fontSize: 12, color: color)),
    );
  }

  // ================= FETCH CUSTOMERS =================

  Future<List<Map<String, dynamic>>> fetchCustomers() async {
    try {
      final res = await supabase
          .from('users')
          .select('id, name, phone')
          .eq('role', 'customer')
          .not('name', 'is', null);

      final list = List<Map<String, dynamic>>.from(res);

      return list
          .where((u) => (u['name'] ?? '').toString().trim().isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('fetchCustomers error: $e');
      return [];
    }
  }

  // ================= SHOW DIALOG (كامل بدون حذف) =================

  Future<void> _showAddDriverDialog() async {
    if (mounted) setState(() => _loadingCustomers = true);

    final customers = await fetchCustomers();

    if (!mounted) return;

    setState(() => _loadingCustomers = false);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.card(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L.t('select_user'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text(context),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: customers.isEmpty
                      ? Center(
                          child: Text(
                            L.t('no_users_available'),
                            style: TextStyle(
                              color: AppColors.textGrey(context),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: customers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final user = customers[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.bg(context),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary(
                                          context,
                                        ).withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        size: 26,
                                        color: AppColors.primary(context),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    user['name'] ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text(context),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    user['phone'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textGrey(context),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary(
                                          context,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        await _promoteToDriver(user['id']);
                                        if (mounted) Navigator.pop(context);
                                      },
                                      child: Text(
                                        L.t('make_driver'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textOnPrimary(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= PROMOTE =================

  Future<void> _promoteToDriver(String userId) async {
    try {
      await supabase.rpc(
        'promote_user_to_driver',
        params: {'target_user_id': userId},
      );

      await fetchDrivers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L.t('promoted_success')),
          backgroundColor: AppColors.primary(context),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L.t('error_general')),
          backgroundColor: AppColors.error(context),
        ),
      );
    }
  }

  Widget _statCard(String type, int value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(L.t(type), style: TextStyle(color: AppColors.textGrey(context))),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text(context),
            ),
          ),
        ],
      ),
    );
  }
}
