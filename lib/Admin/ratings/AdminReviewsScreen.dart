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
  // sort modes: rating_high, rating_low, newest, oldest
  String _sortBy = 'newest';

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

    // ترتيب حسب الوضع المختار
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'rating_high':
          return ((b['rating'] ?? 0) as num).compareTo((a['rating'] ?? 0) as num);
        case 'rating_low':
          return ((a['rating'] ?? 0) as num).compareTo((b['rating'] ?? 0) as num);
        case 'oldest':
          final da = DateTime.tryParse((a['created_at'] ?? '').toString()) ?? DateTime(2000);
          final db = DateTime.tryParse((b['created_at'] ?? '').toString()) ?? DateTime(2000);
          return da.compareTo(db);
        case 'newest':
        default:
          final da = DateTime.tryParse((a['created_at'] ?? '').toString()) ?? DateTime(2000);
          final db = DateTime.tryParse((b['created_at'] ?? '').toString()) ?? DateTime(2000);
          return db.compareTo(da);
      }
    });

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          L.t('no_meals_rate'),
          style: TextStyle(color: AppColors.textGrey(context)),
        ),
      );
    }

    final int itemCount = filtered.length + 1; // +1 for sort row

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _sortChip('newest', L.t('sort_newest'), Icons.arrow_downward),
                  const SizedBox(width: 8),
                  _sortChip('oldest', L.t('sort_oldest'), Icons.arrow_upward),
                  const SizedBox(width: 8),
                  _sortChip('rating_high', L.t('sort_highest'), Icons.star),
                  const SizedBox(width: 8),
                  _sortChip('rating_low', L.t('sort_lowest'), Icons.star_border),
                ],
              ),
            ),
          );
        }

        final reviewIndex = index - 1;
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

  Widget _sortChip(String mode, String label, IconData icon) {
    final isSelected = _sortBy == mode;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? AppColors.textOnPrimary(context) : AppColors.textGrey(context)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
      selectedColor: AppColors.primary(context),
      backgroundColor: AppColors.card(context),
      checkmarkColor: AppColors.textOnPrimary(context),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.textOnPrimary(context) : AppColors.text(context),
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary(context) : AppColors.textGrey(context).withValues(alpha: 0.3),
      ),
      onSelected: (_) {
        setState(() => _sortBy = mode);
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
              Expanded(
                child: Text(
                  userName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey(context),
                  ),
                ),
              ),
              if (review['user_id'] != null)
                TextButton.icon(
                  onPressed: () async {
                    final userDetails = await _service.getUserDetails(review['user_id'].toString());
                    if (!mounted) return;
                    if (userDetails != null) {
                      _showCustomerDetailsDialog(userDetails);
                    }
                  },
                  icon: Icon(Icons.person_search_rounded, size: 16, color: AppColors.primary(context)),
                  label: Text(
                    L.t('details'),
                    style: TextStyle(fontSize: 12, color: AppColors.primary(context)),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  // ===========================
  // USER DETAILS
  // ===========================

  void _showCustomerDetailsDialog(Map<String, dynamic> userDetails) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.person, color: AppColors.primary(context)),
              const SizedBox(width: 8),
              Text(L.t('customer_details'), style: const TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.badge, size: 20),
                title: Text('${userDetails['name'] ?? L.t('guest')}'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              if (userDetails['phone'] != null && userDetails['phone'].toString().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.phone, size: 20),
                  title: Text('${userDetails['phone']}'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              if (userDetails['email'] != null && userDetails['email'].toString().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.email, size: 20),
                  title: Text('${userDetails['email']}'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(L.t('close'), style: TextStyle(color: AppColors.primary(context))),
            ),
          ],
        );
      },
    );
  }
}
