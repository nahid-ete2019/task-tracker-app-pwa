import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/common/empty_state.dart';
import 'widgets/habit_card.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Habits')),
      body: SafeArea(
        child: habitsAsync.when(
          data: (state) {
            if (state.habits.isEmpty) {
              return EmptyState(
                icon: Icons.repeat_rounded,
                title: 'No habits yet',
                message: 'Build consistency by tracking a daily habit — tap below to add your first one.',
                actionLabel: 'Add Habit',
                onAction: () => context.push(AppRoutes.addHabit),
              );
            }
            return RefreshIndicator(
              onRefresh: () => ref.read(habitListProvider.notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: state.habits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final h = state.habits[i];
                  return HabitCard(
                    habit: h,
                    completedToday: state.isCompletedToday(h.id),
                    streak: state.streakFor(h.id),
                    onToggle: () => ref.read(habitListProvider.notifier).toggleToday(h.id),
                    onTap: () => context.push(AppRoutes.editHabit, extra: h),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addHabit),
        child: const Icon(Icons.add),
      ),
    );
  }
}
