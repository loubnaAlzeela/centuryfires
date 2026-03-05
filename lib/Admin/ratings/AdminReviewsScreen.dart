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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
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
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildStats(),
                              const SizedBox(height: 20),
                              _buildTabs(),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 600,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [_buildFoodList()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary(context),
        unselectedLabelColor: AppColors.textGrey(context),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary(context), width: 3),
        ),
        tabs: [Tab(text: '${L.t('food_ratings')} (${_reviews.length})')],
      ),
    );
  }

  // ===========================
  // FOOD LIST WITH ANIMATION + BAD HIGHLIGHT
  // ===========================

  Widget _buildFoodList() {
    if (_reviews.isEmpty) {
      return Center(
        child: Text(
          L.t('no_meals_rate'),
          style: TextStyle(color: AppColors.textGrey(context)),
        ),
      );
    }

    return ListView.builder(
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        final isArabic = LanguageController.isArabic.value;
        final mealName = isArabic ? review['name_ar'] : review['name_en'];

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 350 + (index * 80)),
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
