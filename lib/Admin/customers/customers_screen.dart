import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/l.dart';
import '../services/admin_customer_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final AdminCustomerService _service = AdminCustomerService();

  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> filtered = [];
  bool isLoading = true;

  final List<List<Color>> _userGradients = [
    [Color(0xFF6C63FF), Color(0xFF5A54E6)],
    [Color(0xFFFF6B6B), Color(0xFFE65A5A)],
    [Color(0xFF00C897), Color(0xFF00A87F)],
    [Color(0xFFFFB703), Color(0xFFE6A200)],
    [Color(0xFF3A86FF), Color(0xFF2F6FD6)],
    [Color(0xFF8338EC), Color(0xFF6A2FD6)],
    [Color(0xFFFF006E), Color(0xFFD6005D)],
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final data = await _service.fetchCustomers();
    setState(() {
      customers = List<Map<String, dynamic>>.from(data);
      filtered = List<Map<String, dynamic>>.from(data);
      isLoading = false;
    });
  }

  void _search(String value) {
    setState(() {
      filtered = customers.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final email = (c['email'] ?? '').toString().toLowerCase();
        return name.contains(value.toLowerCase()) ||
            email.contains(value.toLowerCase());
      }).toList();
    });
  }

  List<Color> _getUserGradient(String seed) {
    final index = seed.hashCode.abs() % _userGradients.length;
    return _userGradients[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L.t('customers'),
              style: TextStyle(
                color: AppColors.text(context),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${customers.length} ${L.t('registered_customers')}",
              style: TextStyle(color: AppColors.textGrey(context)),
            ),
            const SizedBox(height: 20),

            TextField(
              onChanged: _search,
              style: TextStyle(color: AppColors.text(context)),
              decoration: InputDecoration(
                hintText: L.t('search_customers'),
                hintStyle: TextStyle(color: AppColors.textGrey(context)),
                filled: true,
                fillColor: AppColors.card(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final c = filtered[index];

                        final userName = c['name'] ?? L.t('guest');
                        final phone = c['phone']?.toString() ?? '';
                        final points = c['points'] ?? 0;
                        final ordersCount = c['orders_count'] ?? 0;
                        final tier = c['tier'] ?? L.t('bronze');

                        final area = c['area'];
                        final street = c['street'];
                        final building = c['building'];
                        final floor = c['floor'];
                        final apartment = c['apartment'];

                        String addressText = L.t('no_address');

                        if (area != null || street != null) {
                          addressText =
                              [area, street, building, floor, apartment]
                                  .where(
                                    (e) => e != null && e.toString().isNotEmpty,
                                  )
                                  .join(', ');
                        }

                        final gradient = _getUserGradient(userName);
                        final primaryColor = gradient.first;

                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: gradient,
                                      ),
                                    ),
                                    child: const CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.transparent,
                                      child: Icon(
                                        Icons.workspace_premium,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userName,
                                          style: TextStyle(
                                            color: AppColors.text(context),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "${L.t(tier.toLowerCase())} ${L.t('member')}",
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              Text(
                                c['email'] ?? '',
                                style: TextStyle(
                                  color: AppColors.textGrey(context),
                                ),
                              ),

                              if (phone.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 16,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      phone,
                                      style: TextStyle(
                                        color: AppColors.text(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      addressText,
                                      style: TextStyle(
                                        color: AppColors.text(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        "$points",
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        L.t('points'),
                                        style: TextStyle(
                                          color: AppColors.textGrey(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "$ordersCount",
                                        style: TextStyle(
                                          color: AppColors.text(context),
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        L.t('orders'),
                                        style: TextStyle(
                                          color: AppColors.textGrey(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
  }
}
