import 'package:flutter/material.dart';
import '../services/admin_review_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/l.dart';
import '../../utils/language_controller.dart';

class AdminRatingsScreen extends StatefulWidget {
  const AdminRatingsScreen({super.key});

  @override
  State<AdminRatingsScreen> createState() => _AdminRatingsScreenState();
}

class _AdminRatingsScreenState extends State<AdminRatingsScreen>
    with SingleTickerProviderStateMixin {
  final AdminReviewService _service = AdminReviewService();
  late TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic> _stats = {};
  bool _sortHighest = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final reviews = await _service.fetchAllReviews();

    if (!mounted) return;

    final stats = _service.calculateStats(reviews);

    setState(() {
      _reviews = reviews;
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: LanguageController.isArabic,
      builder: (context, isArabic, _) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: AppColors.bg(context),
            appBar: AppBar(
              backgroundColor: AppColors.card(context),
              elevation: 0,
              title: Text(
                L.t('ratings_feedback'),
                style: TextStyle(color: AppColors.text(context)),
              ),
            ),
            body: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary(context),
                    ),
                  )
                : NestedScrollView(
                    headerSliverBuilder: (context, _) => [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            children: [
                              _buildStats(),
                              const SizedBox(height: 20),
                              _buildTabs(),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFoodList(filter: 'all'),
                        _buildFoodList(filter: 'unanswered'),
                        _buildFoodList(filter: 'answered'),
                        _buildFoodList(filter: 'negative'),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  // ===========================
  // STATS
  // ===========================

  Widget _buildStats() {
    return Column(
      children: [
        _statCard(
          title: L.t('avg_food_rating'),
          value: _stats['avgFood']?.toString() ?? 'N/A',
          icon: Icons.restaurant,
        ),
        const SizedBox(height: 16),

        _statCard(
          title: L.t('positive_reviews'),
          value: _stats['positive']?.toString() ?? '0',
          icon: Icons.trending_up,
        ),
        const SizedBox(height: 16),

        _statCard(
          title: L.t('needs_attention'),
          value: _stats['needsAttention']?.toString() ?? '0',
          icon: Icons.warning_amber_rounded,
          highlight: true,
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    bool highlight = false,
  }) {
    final Color baseColor = highlight
        ? AppColors.error(context)
        : AppColors.primary(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: highlight
            ? Border.all(color: baseColor.withValues(alpha: 0.5), width: 1.2)
            : null,
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔥 السطر الأول (أيقونة + رقم)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: baseColor, size: 22),
              ),
              const SizedBox(width: 12),

              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: highlight ? baseColor : AppColors.text(context),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// 🔥 السطر الثاني (العنوان لحاله)
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: AppColors.textGrey(context)),
          ),
        ],
      ),
    );
  }

  // ===========================
  // TABS
  // ===========================

  Widget _buildTabs() {
    final allCount = _reviews.length;
    final unansweredCount = _reviews
        .where((r) => (r['admin_reply'] ?? '').toString().trim().isEmpty)
        .length;
    final answeredCount = _reviews
        .where((r) => (r['admin_reply'] ?? '').toString().trim().isNotEmpty)
        .length;
    final negativeCount = _reviews.where((r) => (r['rating'] ?? 0) <= 3).length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.primary(context),
        unselectedLabelColor: AppColors.textGrey(context),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary(context), width: 3),
        ),
        tabs: [
          Tab(text: '${L.t('all_reviews')} ($allCount)'),
          Tab(text: '${L.t('unanswered')} ($unansweredCount)'),
          Tab(text: '${L.t('answered')} ($answeredCount)'),
          Tab(text: '${L.t('negative_reviews')} ($negativeCount)'),
        ],
      ),
    );
  }

  // ===========================
  // FOOD LIST WITH ANIMATION + BAD HIGHLIGHT
  // ===========================

  Widget _buildFoodList({required String filter}) {
    List<Map<String, dynamic>> filtered = List.from(_reviews);

    if (filter == 'unanswered') {
      filtered = filtered
          .where((r) => (r['admin_reply'] ?? '').toString().trim().isEmpty)
          .toList();
    } else if (filter == 'answered') {
      filtered = filtered
          .where((r) => (r['admin_reply'] ?? '').toString().trim().isNotEmpty)
          .toList();
    } else if (filter == 'negative') {
      filtered = filtered.where((r) => (r['rating'] ?? 0) <= 3).toList();
    }

    if (filter == 'all') {
      filtered.sort((a, b) {
        final r1 = (a['rating'] ?? 0) as num;
        final r2 = (b['rating'] ?? 0) as num;
        return _sortHighest ? r2.compareTo(r1) : r1.compareTo(r2);
      });
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          L.t('no_meals_rate'),
          style: TextStyle(color: AppColors.textGrey(context)),
        ),
      );
    }

    final bool showSort = filter == 'all';
    final int itemCount = showSort ? filtered.length + 1 : filtered.length;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (showSort && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _sortHighest = !_sortHighest;
                    });
                  },
                  icon: Icon(
                    _sortHighest ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 18,
                    color: AppColors.primary(context),
                  ),
                  label: Text(
                    _sortHighest ? L.t('sort_highest') : L.t('sort_lowest'),
                    style: TextStyle(color: AppColors.primary(context)),
                  ),
                ),
              ],
            ),
          );
        }

        final reviewIndex = showSort ? index - 1 : index;
        final review = filtered[reviewIndex];
        final isArabic = LanguageController.isArabic.value;
        final mealName = isArabic ? review['name_ar'] : review['name_en'];

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 350 + (reviewIndex * 80)),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _reviewCard(review, mealName ?? ''),
        );
      },
    );
  }

  Widget _reviewCard(Map<String, dynamic> review, String mealName) {
    final hasReply = (review['admin_reply'] ?? '').toString().trim().isNotEmpty;

    final userName = (review['user_name'] ?? 'Unknown User').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= USER NAME =================
          Row(
            children: [
              Icon(Icons.person, size: 16, color: AppColors.textGrey(context)),
              const SizedBox(width: 6),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ================= MEAL NAME =================
          Text(
            mealName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.text(context),
            ),
          ),

          const SizedBox(height: 8),

          // ================= STARS =================
          Row(
            children: List.generate(
              review['rating'] ?? 0,
              (i) =>
                  Icon(Icons.star, size: 18, color: AppColors.primary(context)),
            ),
          ),

          const SizedBox(height: 10),

          // ================= COMMENT =================
          if ((review['comment'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                review['comment'],
                style: TextStyle(color: AppColors.textGrey(context)),
              ),
            ),

          // ================= REPLY SECTION =================
          if (!hasReply)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary(context),
                  foregroundColor: AppColors.textOnPrimary(context),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  final id = review['review_id'];
                  if (id == null) return;
                  _showReplyDialog(id.toString());
                },
                child: Text(
                  L.t('reply'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    review['admin_reply'],
                    style: TextStyle(color: AppColors.text(context)),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () {
                      final id = review['review_id'];
                      if (id == null) return;
                      _showReplyDialog(id.toString());
                    },
                    child: Text(
                      L.t('edit'),
                      style: TextStyle(color: AppColors.primary(context)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ===========================
  // REPLY DIALOG
  // ===========================

  void _showReplyDialog(String reviewId, {String? initialText}) {
    final controller = TextEditingController(text: initialText);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card(context),
          title: Text(L.t('write_reply')),
          content: TextField(controller: controller, maxLines: 3),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(L.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                await _service.replyToReview(
                  reviewId: reviewId,
                  reply: controller.text.trim(),
                );

                Navigator.pop(dialogContext);
                _load();
              },
              child: Text(L.t('send')),
            ),
          ],
        );
      },
    );
  }
}
