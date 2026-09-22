import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';

/// Bottom-nav shell wrapping the 5 main tabs (Home, Tasks, Habits, Goals,
/// Profile), plus a center FAB that opens a quick-add sheet — mirrors the
/// reference UI's raised center action button.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  static const _tabs = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.check_circle_outline_rounded, label: 'Tasks'),
    (icon: Icons.repeat_rounded, label: 'Habits'),
    (icon: Icons.flag_rounded, label: 'Goals'),
    (icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  void _openQuickAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickAddSheet(onSelect: (route) {
        Navigator.of(context).pop();
        context.push(route);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openQuickAdd(context),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: AppColors.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (i) {
            // Leave a gap for the FAB between Tasks (index 1) and Habits (index 2).
            if (i == 2) {
              return Row(children: [const SizedBox(width: 48), _navItem(context, i)]);
            }
            return _navItem(context, i);
          }),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index) {
    final tab = _tabs[index];
    final selected = navigationShell.currentIndex == index;
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(tab.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _QuickAddSheet extends StatelessWidget {
  final void Function(String route) onSelect;

  const _QuickAddSheet({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Add', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _option(context, Icons.check_circle_outline_rounded, 'New Task', AppColors.primary, AppRoutes.addTask),
            _option(context, Icons.repeat_rounded, 'New Habit', AppColors.secondary, AppRoutes.addHabit),
            _option(context, Icons.flag_rounded, 'New Goal', AppColors.warning, AppRoutes.addGoal),
          ],
        ),
      ),
    );
  }

  Widget _option(BuildContext context, IconData icon, String label, Color color, String route) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () => onSelect(route),
    );
  }
}
