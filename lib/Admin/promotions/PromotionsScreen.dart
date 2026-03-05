import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/l.dart';
import '../../utils/language_controller.dart';
import '../../theme/app_colors.dart';
import 'create_promotion_screen.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  late TabController _tabController;

  bool isLoading = true;
  bool _isDeleting = false;

  List<Map<String, dynamic>> promotions = [];
  Map<String, List<Map<String, dynamic>>> _grouped = {};

  static const Map<String, String> _emptyKeys = {
    'banner': 'admin_no_banners',
    'big_order': 'admin_no_big_orders',
    'coupon': 'admin_no_coupons',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPromotions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPromotions() async {
    try {
      final data = await supabase
          .from('promotions')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      promotions = List<Map<String, dynamic>>.from(data);
      _groupPromotions();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _groupPromotions() {
    _grouped = {
      'banner': promotions
          .where((p) => p['promotion_type'] == 'banner')
          .toList(),
      'big_order': promotions
          .where((p) => p['promotion_type'] == 'big_order')
          .toList(),
      'coupon': promotions
          .where((p) => p['promotion_type'] == 'coupon')
          .toList(),
    };
  }

  Future<void> _deletePromotion(String id) async {
    try {
      setState(() => _isDeleting = true);

      final promo = promotions.firstWhere((p) => p['id'].toString() == id);
      final imageUrl = promo['image_url']?.toString();

      await supabase.from('promotions').delete().eq('id', id);

      if (imageUrl != null && imageUrl.isNotEmpty) {
        final fileName = Uri.parse(imageUrl).pathSegments.last;
        await supabase.storage.from('promotions').remove([fileName]);
      }

      await _loadPromotions();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(L.t('deleted_successfully'))));
      }
    } catch (e) {
      debugPrint('_deletePromotion error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(L.t('error_general'))));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> promo) async {
    final isArabic = LanguageController.isArabic.value;

    final title = isArabic
        ? (promo['title_ar'] ?? promo['title_en'] ?? '')
        : (promo['title_en'] ?? promo['title_ar'] ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card(context),
        title: Text(
          L.t('delete_promo_title'),
          style: TextStyle(color: AppColors.text(context)),
        ),
        content: Text(
          L.t('delete_promo_confirm').replaceAll('{title}', title),
          style: TextStyle(color: AppColors.textGrey(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              L.t('cancel'),
              style: TextStyle(color: AppColors.textGrey(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: _isDeleting
                ? null
                : () async {
                    Navigator.pop(dialogContext);
                    await _deletePromotion(promo['id'].toString());
                  },
            child: _isDeleting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(L.t('delete')),
          ),
        ],
      ),
    );
  }

  Color _getColor(BuildContext context, String type) {
    final scheme = Theme.of(context).colorScheme;

    switch (type) {
      case 'banner':
        return AppColors.primary(context);
      case 'big_order':
        return scheme.tertiary;
      case 'coupon':
        return scheme.primary;
      default:
        return AppColors.primary(context);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'banner':
        return Icons.image;
      case 'big_order':
        return Icons.shopping_cart;
      case 'coupon':
        return Icons.card_giftcard;
      default:
        return Icons.local_offer;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'banner':
        return L.t('promo_type_banner');
      case 'big_order':
        return L.t('promo_type_big_order');
      case 'coupon':
        return L.t('promo_type_coupon');
      default:
        return type;
    }
  }

  Widget _buildCard(Map<String, dynamic> promo) {
    final isArabic = LanguageController.isArabic.value;
    final type = (promo['promotion_type'] ?? '').toString();
    final color = _getColor(context, type);

    final title = isArabic
        ? (promo['title_ar'] ?? promo['title_en'] ?? '—')
        : (promo['title_en'] ?? promo['title_ar'] ?? '—');

    final desc = isArabic
        ? (promo['description_ar'] ?? promo['description_en'] ?? '')
        : (promo['description_en'] ?? promo['description_ar'] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: .9), color.withValues(alpha: .7)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            _getIcon(type),
            color: Theme.of(context).colorScheme.onPrimary,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (desc.toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    desc.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: .8),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _typeLabel(type),
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: .7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreatePromotionScreen(promo: promo),
                ),
              );
              await _loadPromotions();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => _confirmDelete(promo),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String type) {
    final filtered = _grouped[type] ?? [];

    if (filtered.isEmpty) {
      final key = _emptyKeys[type] ?? 'admin_no_promotions';

      return RefreshIndicator(
        onRefresh: _loadPromotions,
        child: ListView(
          children: [
            const SizedBox(height: 200),
            Center(
              child: Text(
                L.t(key),
                style: TextStyle(color: AppColors.textGrey(context)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPromotions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildCard(filtered[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(L.t('admin_promotions')),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: L.t('admin_banners')),
            Tab(text: L.t('admin_big_orders')),
            Tab(text: L.t('admin_coupons')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary(context),
        foregroundColor: AppColors.textOnPrimary(context),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePromotionScreen()),
          );
          await _loadPromotions();
        },
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent("banner"),
                _buildTabContent("big_order"),
                _buildTabContent("coupon"),
              ],
            ),
    );
  }
}
