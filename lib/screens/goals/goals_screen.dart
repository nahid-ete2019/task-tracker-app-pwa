import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/goal_provider.dart';
import '../../widgets/common/empty_state.dart';
import 'widgets/goal_card.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Goals')),
      body: SafeArea(
        child: goalsAsync.when(
          data: (goals) {
            if (goals.isEmpty) {
              return EmptyState(
                icon: Icons.flag_rounded,
                title: 'No goals yet',
                message: 'Set a goal you\'re working toward and track it here.',
                actionLabel: 'Add Goal',
                onAction: () => context.push(AppRoutes.addGoal),
              );
            }
            final active = goals.where((g) => g.status == 'active').toList();
            final completed = goals.where((g) => g.status != 'active').toList();
            return RefreshIndicator(
              onRefresh: () => ref.read(goalListProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  if (active.isNotEmpty) ...[
                    const Text('Active', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 10),
                    ...active.map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GoalCard(goal: g, onTap: () => context.push(AppRoutes.editGoal, extra: g)),
                        )),
                  ],
                  if (completed.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Completed', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 10),
                    ...completed.map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GoalCard(goal: g, onTap: () => context.push(AppRoutes.editGoal, extra: g)),
                        )),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
