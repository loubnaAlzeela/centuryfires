import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/l.dart';
import '../services/loyalty_admin_service.dart';
import 'widgets/loyalty_stat_card.dart';
import 'widgets/loyalty_settings_section.dart';
import 'widgets/loyalty_tier_card.dart';

class AdminLoyaltyScreen extends StatefulWidget {
  const AdminLoyaltyScreen({super.key});

  @override
  State<AdminLoyaltyScreen> createState() => _AdminLoyaltyScreenState();
}

class _AdminLoyaltyScreenState extends State<AdminLoyaltyScreen> {
  final LoyaltyAdminService _service = LoyaltyAdminService();

  bool _loading = true;
  bool _error = false;

  int totalMembers = 0;
  int diamondMembers = 0;
  int totalPointsIssued = 0;
  int totalPointsRedeemed = 0;

  List<Map<String, dynamic>> tiers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _error = false;
      });

      final results = await Future.wait([
        _service.getTotalMembers(),
        _service.getDiamondMembers(),
        _service.getTotalPointsIssued(),
        _service.getTotalPointsRedeemed(),
        _service.getTiers(),
      ]);

      if (!mounted) return;

      setState(() {
        totalMembers = results[0] as int;
        diamondMembers = results[1] as int;
        totalPointsIssued = results[2] as int;
        totalPointsRedeemed = results[3] as int;
        tiers = results[4] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 900 ? 4 : 2;

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            elevation: 0,
            title: Text(
              L.t('loyalty'),
              style: TextStyle(color: AppColors.text(context)),
            ),
            iconTheme: IconThemeData(color: AppColors.text(context)),
          ),
          body: _loading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary(context),
                  ),
                )
              : _error
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        L.t('error_loading_data'),
                        style: TextStyle(color: AppColors.error(context)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: Text(L.t('retry')),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary(context),
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: width >= 900 ? 1.2 : 0.9,
                          children: [
                            LoyaltyStatCard(
                              title: L.t('total_members'),
                              value: totalMembers.toString(),
                              icon: Icons.group,
                            ),
                            LoyaltyStatCard(
                              title: L.t('diamond_members'),
                              value: diamondMembers.toString(),
                              icon: Icons.diamond,
                            ),
                            LoyaltyStatCard(
                              title: L.t('points_issued'),
                              value: totalPointsIssued.toString(),
                              icon: Icons.star,
                            ),
                            LoyaltyStatCard(
                              title: L.t('points_redeemed'),
                              value: totalPointsRedeemed.toString(),
                              icon: Icons.card_giftcard,
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        LoyaltySettingsSection(onUpdated: _loadData),

                        const SizedBox(height: 40),

                        Text(
                          L.t('membership_tiers'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 16),

                        tiers.isEmpty
                            ? Center(
                                child: Text(
                                  L.t('no_tiers_found'),
                                  style: TextStyle(
                                    color: AppColors.textGrey(context),
                                  ),
                                ),
                              )
                            : Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: tiers
                                    .map(
                                      (tier) => SizedBox(
                                        width: width >= 900
                                            ? (width - 24 * 2 - 16 * 2) / 3
                                            : double.infinity,
                                        child: LoyaltyTierCard(
                                          tier: tier,
                                          onUpdated: _loadData,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
