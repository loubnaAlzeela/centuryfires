import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'profile_orders_section.dart';
import '../../utils/l.dart';

class ProfileOrdersScreen extends StatefulWidget {
  const ProfileOrdersScreen({super.key});

  @override
  State<ProfileOrdersScreen> createState() => _ProfileOrdersScreenState();
}

class _ProfileOrdersScreenState extends State<ProfileOrdersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.text(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          L.t('my_orders'),
          style: TextStyle(
            color: AppColors.text(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ProfileOrdersSection(),
          ),
        ),
      ),
    );
  }
}
