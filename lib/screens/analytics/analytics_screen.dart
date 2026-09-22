import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../models/task_model.dart';
import '../../providers/habit_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common/progress_ring.dart';
import '../../widgets/common/section_header.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);
    final habitsAsync = ref.watch(habitListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Analytics')),
      body: SafeArea(
        child: tasksAsync.when(
          data: (tasks) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _ProductivityCard(tasks: tasks),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Task Completion (Last 7 Days)'),
              const SizedBox(height: 12),
              _CompletionTrendChart(tasks: tasks),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Category Breakdown'),
              const SizedBox(height: 12),
              _CategoryDonut(tasks: tasks),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Habit Consistency (30 Days)'),
              const SizedBox(height: 12),
              habitsAsync.when(
                data: (state) => _HabitConsistencyList(state: state),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _ProductivityCard extends StatelessWidget {
  final List<TaskModel> tasks;

  const _ProductivityCard({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final weekAgo = AppDateUtils.today().subtract(const Duration(days: 7));
    final thisWeek = tasks.where((t) => t.createdAt.isAfter(weekAgo) || (t.dueDate?.isAfter(weekAgo) ?? false)).toList();
    final completed = thisWeek.where((t) => t.isCompleted).length;
    final score = thisWeek.isEmpty ? 0.0 : completed / thisWeek.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          ProgressRing(progress: score, subLabel: 'This Week', color: AppColors.secondary),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Productivity Score', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text('$completed of ${thisWeek.length} tasks completed this week',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionTrendChart extends StatelessWidget {
  final List<TaskModel> tasks;

  const _CompletionTrendChart({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final today = AppDateUtils.today();
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    final counts = days.map((d) {
      return tasks.where((t) {
        if (!t.isCompleted) return false;
        final ref = t.updatedAt;
        return ref.year == d.year && ref.month == d.month && ref.day == d.day;
      }).length;
    }).toList();

    final maxY = (counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b)).toDouble();

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY < 4 ? 4 : maxY + 1,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= days.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(AppDateUtils.weekdayShort(days[i]),
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(days.length, (i) {
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: counts[i].toDouble(),
                color: AppColors.primary,
                width: 18,
                borderRadius: BorderRadius.circular(6),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}

class _CategoryDonut extends StatelessWidget {
  final List<TaskModel> tasks;

  const _CategoryDonut({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final open = tasks.where((t) => !t.isCompleted).toList();
    if (open.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(
          child: Text('No open tasks to break down yet.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final byCategory = <String, int>{};
    for (final t in open) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + 1;
    }
    final entries = byCategory.entries.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 32,
                sections: List.generate(entries.length, (i) {
                  final color = AppColors.categoryPalette[i % AppColors.categoryPalette.length];
                  return PieChartSectionData(
                    value: entries[i].value.toDouble(),
                    color: color,
                    radius: 26,
                    title: '',
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(entries.length, (i) {
                final color = AppColors.categoryPalette[i % AppColors.categoryPalette.length];
                final pct = (entries[i].value / open.length * 100).round();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entries[i].key, style: const TextStyle(fontSize: 13))),
                      Text('$pct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitConsistencyList extends StatelessWidget {
  final HabitsState state;

  const _HabitConsistencyList({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.habits.isEmpty) {
      return const Text('No habits yet.', style: TextStyle(color: AppColors.textSecondary));
    }
    return Column(
      children: state.habits.map((h) {
        final completedIn30 = state.completedDatesFor(h.id).where((d) {
          return d.isAfter(AppDateUtils.today().subtract(const Duration(days: 30)));
        }).length;
        final rate = (completedIn30 / 30).clamp(0, 1).toDouble();
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(h.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  Text('${(rate * 100).round()}%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: rate,
                  minHeight: 7,
                  backgroundColor: AppColors.divider,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
