import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'widgets/meals_screen.dart';
import 'widgets/addons_screen.dart';
import 'widgets/add_meal_sheet.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        appBar: AppBar(
          title: const Text('Menu Management'),
          backgroundColor: AppColors.bg(context),
          elevation: 0,

          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddMealSheet(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary(context),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: const TabBarView(children: [MealsScreen(), AddonsScreen()]),
      ),
    );
  }
}
