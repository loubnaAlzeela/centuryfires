import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PromoSlider extends StatefulWidget {
  const PromoSlider({super.key});

  @override
  State<PromoSlider> createState() => _PromoSliderState();
}

class _PromoSliderState extends State<PromoSlider> {
  final PageController _controller = PageController(viewportFraction: 0.94);
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _promos = [];
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchPromos();
  }

  Future<void> _fetchPromos() async {
    try {
      final response = await _supabase
          .from('promotions')
          .select('id, image_url, promotion_type, is_active, created_at')
          .eq('is_active', true)
          .eq('promotion_type', 'banner')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _promos = List<Map<String, dynamic>>.from(response);
        _currentPage = 0;
      });

      if (_promos.length > 1) _startAutoSlide();
    } catch (e) {
      debugPrint("Promo fetch error: $e");
      if (!mounted) return;
      setState(() => _promos = []);
    }
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_promos.isEmpty) return;
      if (!_controller.hasClients) return;

      _currentPage = (_currentPage + 1) % _promos.length;

      _controller.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );

      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_promos.isEmpty) {
      return const SizedBox(height: 200);
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        SizedBox(
          height: screenWidth * 0.45, // 👈 نسبة أذكى
          child: PageView.builder(
            controller: _controller,
            itemCount: _promos.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final imageUrl = (_promos[index]['image_url'] ?? '').toString();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center, // 👈 المهم
                    width: double.infinity,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promos.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? Colors.amber
                    : Colors.grey.shade700,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
