import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/progress_ring.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/stat_card.dart';
import '../tasks/widgets/task_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final tasksAsync = ref.watch(taskListProvider);
    final habitsAsync = ref.watch(habitListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(taskListProvider.notifier).refresh();
            await ref.read(habitListProvider.notifier).refresh();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              profileAsync.when(
                data: (profile) => _Header(name: profile?.displayName, avatarUrl: profile?.avatarUrl, initials: profile?.initials ?? '?'),
                loading: () => const _Header(name: null, avatarUrl: null, initials: '?'),
                error: (_, __) => const _Header(name: null, avatarUrl: null, initials: '?'),
              ),
              const SizedBox(height: 24),
              tasksAsync.when(
                data: (tasks) => _DashboardBody(tasks: tasks),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text('Could not load tasks: $e', style: const TextStyle(color: AppColors.danger)),
                ),
              ),
              const SizedBox(height: 28),
              SectionHeader(
                title: "Today's Habits",
                actionLabel: 'See all',
                onAction: () => context.push(AppRoutes.habits),
              ),
              const SizedBox(height: 12),
              habitsAsync.when(
                data: (state) {
                  if (state.habits.isEmpty) {
                    return const Text('No habits yet — add one from the + button.',
                        style: TextStyle(color: AppColors.textSecondary));
                  }
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: state.habits.take(6).map((h) {
                      final done = state.isCompletedToday(h.id);
                      return ActionChip(
                        avatar: Icon(
                          done ? Icons.check_circle : Icons.circle_outlined,
                          size: 18,
                          color: done ? AppColors.success : AppColors.textMuted,
                        ),
                        label: Text(h.title),
                        backgroundColor: done ? AppColors.success.withOpacity(0.1) : AppColors.surface,
                        side: const BorderSide(color: AppColors.divider),
                        onPressed: () => ref.read(habitListProvider.notifier).toggleToday(h.id),
                      );
                    }).toList(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? name;
  final String? avatarUrl;
  final String initials;

  const _Header({required this.name, required this.avatarUrl, required this.initials});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : (hour < 17 ? 'Good Afternoon' : 'Good Evening');
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 2),
              Text(name ?? 'there', style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
        Stack(
          children: [
            AppAvatar(imageUrl: avatarUrl, initials: initials, radius: 22),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  final List<TaskModel> tasks;

  const _DashboardBody({required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = tasks.where((t) => t.dueDate != null && AppDateUtils.isToday(t.dueDate!)).toList();
    final completedToday = today.where((t) => t.isCompleted).length;
    final inProgress = tasks.where((t) => t.status == 'in_progress').length;
    final completedTotal = tasks.where((t) => t.isCompleted).length;
    final overdue = tasks.where((t) => AppDateUtils.isOverdue(t.dueDate, completed: t.isCompleted)).length;
    final progress = today.isEmpty ? 0.0 : completedToday / today.length;

    final upcoming = [...tasks]..sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        final ad = a.dueDate ?? DateTime(2100);
        final bd = b.dueDate ?? DateTime(2100);
        return ad.compareTo(bd);
      });
    final preview = upcoming.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              ProgressRing(progress: progress, subLabel: 'Today'),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Daily Progress', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      '$completedToday of ${today.length} tasks done',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      today.isEmpty
                          ? 'Nothing due today — enjoy the calm.'
                          : (progress >= 1 ? "You're all done for today! 🎉" : "Keep going, you're doing great!"),
                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: [
            StatCard(icon: Icons.list_alt_rounded, label: 'Total Tasks', value: '${tasks.length}', color: AppColors.primary),
            StatCard(icon: Icons.hourglass_bottom_rounded, label: 'In Progress', value: '$inProgress', color: AppColors.info),
            StatCard(icon: Icons.check_circle_rounded, label: 'Completed', value: '$completedTotal', color: AppColors.success),
            StatCard(icon: Icons.error_outline_rounded, label: 'Overdue', value: '$overdue', color: AppColors.danger),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickAction(icon: Icons.add_task_rounded, label: 'Add Task', onTap: () => context.push(AppRoutes.addTask)),
            _QuickAction(icon: Icons.repeat_rounded, label: 'New Habit', onTap: () => context.push(AppRoutes.addHabit)),
            _QuickAction(icon: Icons.flag_rounded, label: 'New Goal', onTap: () => context.push(AppRoutes.addGoal)),
            _QuickAction(icon: Icons.bar_chart_rounded, label: 'Analytics', onTap: () => context.push(AppRoutes.analytics)),
          ],
        ),
        const SizedBox(height: 28),
        SectionHeader(title: "Today's Tasks", actionLabel: 'See all', onAction: () => context.push(AppRoutes.tasks)),
        const SizedBox(height: 12),
        if (preview.isEmpty)
          const Text('No tasks yet — tap "Add Task" to get started.', style: TextStyle(color: AppColors.textSecondary))
        else
          Column(
            children: preview
                .map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TaskTile(
                        task: t,
                        onToggle: () => ref.read(taskListProvider.notifier).toggleComplete(t),
                        onTap: () => context.push(AppRoutes.editTask, extra: t),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
