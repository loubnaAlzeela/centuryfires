import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/theme_controller.dart';

import '../widgets/app_header.dart';
import '../widgets/promo_slider.dart';
import '../widgets/order_type_selector.dart';
import '../widgets/section_title.dart';
import '../widgets/meal_horizontal_list_from_data.dart';
import '../utils/meal_list_type.dart';

import '../models/category_model.dart';
import '../services/category_service.dart';
import '../widgets/meals_section.dart';
import '../utils/l.dart';
import '../utils/language_controller.dart';

class HomeScreen extends StatefulWidget {
  /// When [isPreviewMode] is true, the screen is rendered inside an admin
  /// session for preview purposes only. No auth changes are made.
  final bool isPreviewMode;

  const HomeScreen({super.key, this.isPreviewMode = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  bool get isArabic => LanguageController.ar;

  TabController? _tabController;
  List<CategoryModel> categories = [];

  bool isLoading = true;
  bool isLoadingDeliveryType = true;
  bool isLoadingRestaurantName = true;

  String restaurantNameEn = '';
  String restaurantNameAr = '';

  String selectedDeliveryType = 'delivery';
  String? internalUserId;

  @override
  void initState() {
    super.initState();
    _initUserAndDeliveryType();
    _loadCategories();
    _loadRestaurantName();
  }

  // ================= LOAD RESTAURANT NAME =================
  Future<void> _loadRestaurantName() async {
    try {
      final settings = await supabase
          .from('restaurant_settings')
          .select('name_en, name_ar')
          .limit(1)
          .maybeSingle();

      if (settings != null) {
        restaurantNameEn = settings['name_en'] ?? '';
        restaurantNameAr = settings['name_ar'] ?? '';
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) {
        setState(() {
          isLoadingRestaurantName = false;
        });
      }
    }
  }

  // ================= USER + DELIVERY =================
  Future<void> _initUserAndDeliveryType() async {
    // In preview mode we skip user-specific data fetching to avoid
    // touching the admin's session or writing to the wrong user record.
    if (widget.isPreviewMode) {
      if (mounted) setState(() => isLoadingDeliveryType = false);
      return;
    }

    try {
      final authId = supabase.auth.currentUser?.id;
      if (authId == null) {
        if (mounted) setState(() => isLoadingDeliveryType = false);
        return;
      }

      final res = await supabase
          .from('users')
          .select('id, preferred_delivery_type')
          .eq('auth_id', authId)
          .maybeSingle();

      if (!mounted) return;

      final value = res?['preferred_delivery_type'];

      setState(() {
        internalUserId = res?['id']?.toString();
        selectedDeliveryType =
            (value == 'delivery' || value == 'pickup' || value == 'dine_in')
            ? value
            : 'delivery';
        isLoadingDeliveryType = false;
      });
    } catch (_) {
      if (mounted) setState(() => isLoadingDeliveryType = false);
    }
  }

  // ================= CATEGORIES =================
  Future<void> _loadCategories() async {
    try {
      final data = await CategoryService().getCategories();
      if (!mounted) return;

      _tabController?.dispose();
      _tabController = TabController(length: data.length + 1, vsync: this)
        ..addListener(() {
          if (mounted) setState(() {});
        });

      setState(() {
        categories = data;
        isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // ================= PREVIEW BANNER =================
  Widget _buildPreviewBanner() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      color: AppColors.primary(context).withOpacity(0.15),
      padding: EdgeInsets.only(
        top: topPadding + 6,
        bottom: 6,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          Icon(
            Icons.visibility_outlined,
            size: 18,
            color: AppColors.primary(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              L.t('preview_mode'),
              style: TextStyle(
                color: AppColors.primary(context),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.close,
              size: 18,
              color: AppColors.primary(context),
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, _, __) {
        if (isLoading ||
            isLoadingDeliveryType ||
            isLoadingRestaurantName ||
            _tabController == null) {
          return Scaffold(
            backgroundColor: AppColors.bg(context),
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary(context),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          extendBodyBehindAppBar: true,
          body: Column(
            children: [
              // Preview banner sits above everything, only when in preview mode
              if (widget.isPreviewMode) _buildPreviewBanner(),

              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppHeader(
                              restaurantName: isArabic
                                  ? restaurantNameAr
                                  : restaurantNameEn,
                            ),
                            PromoSlider(),
                            OrderTypeSelector(
                              initialType: selectedDeliveryType,
                              onChanged: (value) async {
                                if (value == selectedDeliveryType) return;

                                setState(() {
                                  selectedDeliveryType = value;
                                });

                                // Do not persist delivery type changes in preview mode
                                if (widget.isPreviewMode) return;
                                if (internalUserId == null) return;

                                await supabase
                                    .from('users')
                                    .update({'preferred_delivery_type': value})
                                    .eq('id', internalUserId!);
                              },
                            ),
                            SectionTitle(
                              title: L.t('recommended'),
                              subtitle: '',
                            ),
                            MealHorizontalListFromData(
                              type: MealListType.recommended,
                            ),
                            SectionTitle(title: L.t('popular'), subtitle: ''),
                            MealHorizontalListFromData(
                              type: MealListType.popular,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      SliverAppBar(
                        pinned: true,
                        backgroundColor: AppColors.bg(context),
                        elevation: 1,
                        automaticallyImplyLeading: false,
                        toolbarHeight: 0,
                        bottom: PreferredSize(
                          preferredSize: const Size.fromHeight(56),
                          child: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 8),
                            child: TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              indicatorColor: Colors.transparent,
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              tabs: [
                                _buildTab(
                                  text: L.t('all'),
                                  isActive: _tabController!.index == 0,
                                ),
                                ...categories.asMap().entries.map((entry) {
                                  final index = entry.key + 1;
                                  final category = entry.value;
                                  return _buildTab(
                                    text: category.displayName(isArabic),
                                    isActive: _tabController!.index == index,
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      MealsSection(title: L.t('all'), categoryId: null),
                      ...categories.map(
                        (c) => MealsSection(
                          title: c.displayName(isArabic),
                          categoryId: c.id,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab({required String text, required bool isActive}) {
    return Tab(
      child: Container(
        constraints: const BoxConstraints(minWidth: 72),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isActive
              ? null
              : Border.all(color: AppColors.textGrey(context), width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.black : AppColors.text(context),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
