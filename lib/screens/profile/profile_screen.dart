import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/habit_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common/app_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final tasksAsync = ref.watch(taskListProvider);
    final goalsAsync = ref.watch(goalListProvider);
    final habitsAsync = ref.watch(habitListProvider);

    final taskCount = tasksAsync.value?.length ?? 0;
    final goalCount = goalsAsync.value?.length ?? 0;
    final bestStreak = (habitsAsync.value?.habits ?? const <HabitModel>[])
        .map((h) => habitsAsync.value!.streakFor(h.id))
        .fold<int>(0, (best, s) => s > best ? s : best);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            profileAsync.when(
              data: (profile) => Column(
                children: [
                  AppAvatar(imageUrl: profile?.avatarUrl, initials: profile?.initials ?? '?', radius: 40),
                  const SizedBox(height: 14),
                  Text(profile?.displayName ?? 'there', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(profile?.email ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  _StatColumn(label: 'Tasks', value: '$taskCount'),
                  _divider(),
                  _StatColumn(label: 'Goals', value: '$goalCount'),
                  _divider(),
                  _StatColumn(label: 'Best Streak', value: '$bestStreak'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _MenuTile(icon: Icons.flag_outlined, label: 'My Goals', onTap: () {}),
            _MenuTile(icon: Icons.notifications_none_rounded, label: 'Notifications', trailing: 'Coming soon'),
            _MenuTile(icon: Icons.palette_outlined, label: 'Appearance', trailing: 'Light'),
            _MenuTile(icon: Icons.help_outline_rounded, label: 'Help & Support', onTap: () {}),
            _MenuTile(icon: Icons.settings_outlined, label: 'Settings', onTap: () {}),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => ref.read(authServiceProvider).signOut(),
                icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                label: const Text('Log Out', style: TextStyle(color: AppColors.danger)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('Planner v1.0.0', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.divider);
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;

  const _MenuTile({required this.icon, required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: trailing != null
          ? Text(trailing!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
