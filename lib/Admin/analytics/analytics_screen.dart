import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../utils/l.dart';
import 'widgets/analytics_kpi_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final supabase = Supabase.instance.client;

  String selectedPeriod = 'month';

  double totalRevenue = 0.0;
  int totalOrders = 0;
  double avgOrderValue = 0.0;

  /// ملاحظة: هذا الرقم هو "عدد المستخدمين اللي طلبوا أكثر من مرة داخل الفترة المحددة"
  /// وليس "repeat customers" مدى الحياة.
  int repeatCustomers = 0;

  // آخر 7 أيام جاهزة للـ chart
  List<_DayRevenue> revenueSeries = [];

  // Top meals list
  List<_TopMeal> topMeals = [];

  bool isLoading = true;
  int _reqId = 0;

  @override
  void initState() {
    super.initState();
    fetchAnalytics();
  }

  DateTime _getStartDate() {
    final now = DateTime.now();

    switch (selectedPeriod) {
      case 'today':
        return DateTime(now.year, now.month, now.day);

      case 'week':
        // ✅ آخر 7 أيام كاملة
        return now.subtract(const Duration(days: 7));

      case 'month':
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> fetchAnalytics() async {
    final int myReq = ++_reqId;

    if (mounted) {
      // ✅ إعادة بناء تكفي لتحديث الفلتر لأنه يقرأ selectedPeriod الحالي
      setState(() => isLoading = true);
    }

    try {
      final startDate = _getStartDate().toIso8601String();

      final ordersResp = await supabase
          .from('orders')
          .select('id, total, user_id, created_at')
          .eq('status', 'delivered')
          .gte('created_at', startDate);

      if (myReq != _reqId) return;

      final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(
        ordersResp,
      );

      double revenue = 0.0;
      final Map<String, int> userOrderCount = {};
      final Map<DateTime, double> dailyMap = {};

      // ✅ مهم: نخليها String
      final List<String> orderIds = [];

      for (final order in orders) {
        final id = order['id']?.toString();
        if (id != null && id.isNotEmpty) {
          orderIds.add(id);
        }

        final num amountNum = (order['total'] as num?) ?? 0;
        final double amount = amountNum.toDouble();
        revenue += amount;

        final userId = order['user_id']?.toString();
        if (userId != null && userId.isNotEmpty) {
          userOrderCount[userId] = (userOrderCount[userId] ?? 0) + 1;
        }

        final created = DateTime.parse(order['created_at']);
        final key = _dateOnly(created);
        dailyMap[key] = (dailyMap[key] ?? 0.0) + amount;
      }

      final int ordersCount = orders.length;
      final double avg = ordersCount > 0 ? (revenue / ordersCount) : 0.0;

      // ✅ أوضح بالمنطق: repeats داخل الفترة
      final int repeatsInPeriod = userOrderCount.values
          .where((c) => c > 1)
          .length;

      // ===== Revenue Series (آخر 7 أيام فقط - مرتّبة) =====
      final now = DateTime.now();
      final List<_DayRevenue> series = List.generate(7, (i) {
        final d = _dateOnly(now.subtract(Duration(days: 6 - i)));
        final v = dailyMap[d] ?? 0.0;
        return _DayRevenue(date: d, value: v);
      });

      // ===== Top Meals =====
      List<_TopMeal> top = [];

      if (orderIds.isNotEmpty) {
        // ✅ JOIN: order_items + meals(name_en,name_ar) => يلغي استدعاء meals الثالث بالكامل
        final itemsResp = await supabase
            .from('order_items')
            .select('meal_id, quantity, meals(name_en, name_ar)')
            .inFilter('order_id', orderIds);

        if (myReq != _reqId) return;

        final List<Map<String, dynamic>> items =
            List<Map<String, dynamic>>.from(itemsResp);

        final Map<String, int> mealQty = {};
        final Map<String, Map<String, dynamic>> mealInfo = {};

        for (final item in items) {
          final mealId = item['meal_id']?.toString();
          if (mealId == null || mealId.isEmpty) continue;

          final int qty = ((item['quantity'] as num?) ?? 0).toInt();
          mealQty[mealId] = (mealQty[mealId] ?? 0) + qty;

          // نخزن الاسم مرة واحدة
          if (!mealInfo.containsKey(mealId)) {
            final joined = item['meals'];
            if (joined is Map) {
              mealInfo[mealId] = Map<String, dynamic>.from(joined);
            } else {
              mealInfo[mealId] = {};
            }
          }
        }

        final sorted = mealQty.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final top5 = sorted.take(5).toList();

        for (final entry in top5) {
          final m = mealInfo[entry.key] ?? {};
          top.add(
            _TopMeal(
              id: entry.key.toString(),
              nameEn: (m['name_en'] ?? '').toString(),
              nameAr: (m['name_ar'] ?? '').toString(),
              qty: entry.value,
            ),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        totalRevenue = revenue;
        totalOrders = ordersCount;
        avgOrderValue = avg;
        repeatCustomers = repeatsInPeriod;

        revenueSeries = series;
        topMeals = top;

        isLoading = false;
      });
    } catch (e) {
      if (myReq != _reqId) return;
      if (!mounted) return;

      setState(() {
        totalRevenue = 0.0;
        totalOrders = 0;
        avgOrderValue = 0.0;
        repeatCustomers = 0;

        revenueSeries = [];
        topMeals = [];

        isLoading = false;
      });

      debugPrint('Analytics error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        title: Text(
          L.t('analytics'),
          style: TextStyle(
            color: AppColors.text(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bg(context), AppColors.card(context)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              /// 🔹 Period Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _buildFilter('today')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFilter('week')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFilter('month')),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 🔹 KPI Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: width >= 850 ? 1.25 : 0.95,
                  children: [
                    AnalyticsKpiCard(
                      titleKey: 'total_revenue',
                      value: isLoading
                          ? '...'
                          : '${totalRevenue.toStringAsFixed(2)} ${L.t('currency')}',
                    ),
                    AnalyticsKpiCard(
                      titleKey: 'orders',
                      value: isLoading ? '...' : totalOrders.toString(),
                    ),
                    AnalyticsKpiCard(
                      titleKey: 'avg_order_value',
                      value: isLoading
                          ? '...'
                          : '${avgOrderValue.toStringAsFixed(2)} ${L.t('currency')}',
                    ),
                    AnalyticsKpiCard(
                      titleKey: 'repeat_customers',
                      value: isLoading ? '...' : repeatCustomers.toString(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// 🔹 Revenue Overview (Line Chart)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSectionCard(
                  title: L.t('revenue_overview'),
                  child: _buildRevenueLineChart(),
                ),
              ),

              const SizedBox(height: 20),

              /// 🔹 Top Meals
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSectionCard(
                  title: L.t('top_meals'),
                  child: _buildTopMealsList(isRtl: isRtl),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueLineChart() {
    if (isLoading) return const EmptyStateWidget();

    if (revenueSeries.isEmpty || revenueSeries.every((e) => e.value == 0)) {
      return const EmptyStateWidget();
    }

    final values = revenueSeries.map((e) => e.value).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxY == 0 ? 10.0 : maxY * 1.2;

    final spots = List.generate(
      revenueSeries.length,
      (i) => FlSpot(i.toDouble(), revenueSeries[i].value),
    );

    return SizedBox(
      height: 190,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: chartMaxY,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textGrey(context),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= revenueSeries.length) {
                    return const SizedBox();
                  }
                  final d = revenueSeries[i].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${d.day}/${d.month}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textGrey(context),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary(context),
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                // ✅ withOpacity deprecated
                color: AppColors.primary(context).withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMealsList({required bool isRtl}) {
    if (isLoading) return const EmptyStateWidget();
    if (topMeals.isEmpty) return const EmptyStateWidget();

    return Column(
      children: topMeals.map((m) {
        final name = isRtl
            ? (m.nameAr.isNotEmpty ? m.nameAr : m.nameEn)
            : (m.nameEn.isNotEmpty ? m.nameEn : m.nameAr);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: AppColors.text(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${m.qty}×',
                style: TextStyle(
                  color: AppColors.primary(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilter(String period) {
    final isSelected = selectedPeriod == period;

    return GestureDetector(
      onTap: () {
        // ✅ بدون setState هون، fetchAnalytics فيها setState وتعمل rebuild
        selectedPeriod = period;
        fetchAnalytics();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary(context)
              : AppColors.card(context),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          L.t(period),
          style: TextStyle(
            color: isSelected
                ? AppColors.textOnPrimary(context)
                : AppColors.text(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.text(context),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Text(
          L.t('no_sales_data'),
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textGrey(context)),
        ),
      ),
    );
  }
}

class _DayRevenue {
  final DateTime date;
  final double value;

  _DayRevenue({required this.date, required this.value});
}

class _TopMeal {
  final String id;
  final String nameEn;
  final String nameAr;
  final int qty;

  _TopMeal({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.qty,
  });
}
