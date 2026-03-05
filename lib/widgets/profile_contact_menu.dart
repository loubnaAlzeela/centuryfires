import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../utils/l.dart';

class ProfileContactMenu extends StatefulWidget {
  const ProfileContactMenu({super.key});

  @override
  State<ProfileContactMenu> createState() => _ProfileContactMenuState();
}

class _ProfileContactMenuState extends State<ProfileContactMenu> {
  final supabase = Supabase.instance.client;

  bool _loading = true;

  String _phone = '';

  bool _instagramEnabled = false;
  bool _tiktokEnabled = false;
  bool _facebookEnabled = false;

  String _instagramUrl = '';
  String _tiktokUrl = '';
  String _facebookUrl = '';

  @override
  void initState() {
    super.initState();
    _loadSocials();
  }

  Future<void> _loadSocials() async {
    try {
      final row = await supabase
          .from('restaurant_settings')
          .select(
            'phone, instagram_enabled, instagram_url, tiktok_enabled, tiktok_url, facebook_enabled, facebook_url',
          )
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _phone = (row?['phone'] ?? '').toString();

        _instagramEnabled = (row?['instagram_enabled'] ?? false) as bool;
        _tiktokEnabled = (row?['tiktok_enabled'] ?? false) as bool;
        _facebookEnabled = (row?['facebook_enabled'] ?? false) as bool;

        _instagramUrl = (row?['instagram_url'] ?? '').toString();
        _tiktokUrl = (row?['tiktok_url'] ?? '').toString();
        _facebookUrl = (row?['facebook_url'] ?? '').toString();

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ================= Helpers =================
  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  String _cleanUrl(String s) {
    final v = s.trim();
    if (v.isEmpty) return '';
    return v.split('?').first; // remove tracking like ?igsh=...
  }

  Future<void> _openExternal(String url) async {
    final cleaned = _cleanUrl(url);
    if (cleaned.isEmpty) return;

    final u = Uri.parse(cleaned);

    final ok = await launchUrl(u, mode: LaunchMode.externalApplication);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L.t('cannot_open_link')),
          backgroundColor: AppColors.error(context),
        ),
      );
    }
  }

  Future<void> _openWhatsApp() async {
    final p = _digitsOnly(_phone);
    if (p.isEmpty) return;

    // 1) جرّبي deep link (يفتح تطبيق واتساب مباشرة)
    final deep = Uri.parse('whatsapp://send?phone=$p');
    final okDeep = await launchUrl(deep, mode: LaunchMode.externalApplication);

    if (okDeep) return;

    // 2) fallback للويب (لكن لازم الرقم يكون دولي)
    final web = Uri.parse('https://wa.me/$p');
    final okWeb = await launchUrl(web, mode: LaunchMode.externalApplication);

    if (!okWeb && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L.t('whatsapp_not_available')),
          backgroundColor: AppColors.error(context),
        ),
      );
    }
  }

  // لون “خاص” لكل منصة لكن كله مشتق من primary (بدون ألوان ثابتة)
  Color _brandColor(BuildContext context, String key) {
    final base = AppColors.primary(context);
    final h = HSLColor.fromColor(base);

    switch (key) {
      case 'whatsapp':
        return h.withHue(135).withSaturation(0.85).toColor();
      case 'instagram':
        return h.withHue(320).withSaturation(0.85).toColor();
      case 'tiktok':
        return h.withHue(190).withSaturation(0.70).toColor();
      case 'facebook':
        return h.withHue(215).withSaturation(0.75).toColor();
      default:
        return base;
    }
  }

  Widget _iconBadge(BuildContext context, IconData icon, Color c) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: c, size: 18),
    );
  }

  Widget _grid2(List<Widget> list) {
    if (list.isEmpty) return const SizedBox.shrink();

    // عنصر واحد → عرض كامل
    if (list.length == 1) return list.first;

    // 2 أعمدة ثابت
    final rows = <Widget>[];
    for (int i = 0; i < list.length; i += 2) {
      final left = Expanded(child: list[i]);
      final right = (i + 1 < list.length)
          ? Expanded(child: list[i + 1])
          : const Expanded(child: SizedBox.shrink());

      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [left, const SizedBox(width: 12), right],
        ),
      );

      if (i + 2 < list.length) rows.add(const SizedBox(height: 12));
    }

    return Column(children: rows);
  }

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    // WhatsApp
    if (_digitsOnly(_phone).isNotEmpty) {
      items.add(
        _card(
          context,
          icon: Icons.chat,
          iconColor: _brandColor(context, 'whatsapp'),
          title: 'WhatsApp',
          subtitle: L.t('profile_contact_whatsapp_sub'),
          onTap: _openWhatsApp,
        ),
      );
    }

    // Instagram
    if (_instagramEnabled && _cleanUrl(_instagramUrl).isNotEmpty) {
      items.add(
        _card(
          context,
          icon: Icons.camera_alt,
          iconColor: _brandColor(context, 'instagram'),
          title: 'Instagram',
          subtitle: _cleanUrl(_instagramUrl),
          onTap: () => _openExternal(_instagramUrl),
        ),
      );
    }

    // TikTok
    if (_tiktokEnabled && _cleanUrl(_tiktokUrl).isNotEmpty) {
      items.add(
        _card(
          context,
          icon: Icons.play_arrow_rounded,
          iconColor: _brandColor(context, 'tiktok'),
          title: 'TikTok',
          subtitle: _cleanUrl(_tiktokUrl),
          onTap: () => _openExternal(_tiktokUrl),
        ),
      );
    }

    // Facebook
    if (_facebookEnabled && _cleanUrl(_facebookUrl).isNotEmpty) {
      items.add(
        _card(
          context,
          icon: Icons.facebook,
          iconColor: _brandColor(context, 'facebook'),
          title: 'Facebook',
          subtitle: _cleanUrl(_facebookUrl),
          onTap: () => _openExternal(_facebookUrl),
        ),
      );
    }

    // إذا ما في شي ينعرض
    if (!_loading && items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L.t('profile_contact_title'),
          style: TextStyle(
            color: AppColors.textGrey(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        if (_loading)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.textGrey(context).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      AppColors.primary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  L.t('loading'),
                  style: TextStyle(color: AppColors.textGrey(context)),
                ),
              ],
            ),
          )
        else
          _grid2(items),
      ],
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.textGrey(context).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _iconBadge(context, icon, iconColor),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: AppColors.text(context),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textGrey(context),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
