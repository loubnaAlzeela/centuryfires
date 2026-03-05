import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class AddonsScreen extends StatelessWidget {
  const AddonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool hasAddons = false;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildAddonsContent(hasAddons),
    );
  }
}

class _EmptyAddons extends StatelessWidget {
  const _EmptyAddons();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No add-ons yet',
        style: TextStyle(color: AppColors.textGrey(context)),
      ),
    );
  }
}

Widget _buildAddonsContent(bool hasAddons) {
  if (!hasAddons) {
    return const _EmptyAddons();
  }
  return ListView.builder(
    itemCount: 5,
    itemBuilder: (_, __) => const AddonRow(),
  );
}

class AddonRow extends StatelessWidget {
  const AddonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text(
            'Extra Cheese',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text('+5 AED', style: TextStyle(color: AppColors.textGrey(context))),
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.visibility_off)),
        ],
      ),
    );
  }
}
