import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common/empty_state.dart';
import 'widgets/task_tile.dart';

enum _TaskFilter { all, today, upcoming, completed }

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  _TaskFilter _filter = _TaskFilter.all;
  String _query = '';

  List<TaskModel> _applyFilter(List<TaskModel> tasks) {
    var result = tasks;
    switch (_filter) {
      case _TaskFilter.today:
        result = result.where((t) => t.dueDate != null && AppDateUtils.isToday(t.dueDate!)).toList();
        break;
      case _TaskFilter.upcoming:
        result = result
            .where((t) => !t.isCompleted && t.dueDate != null && t.dueDate!.isAfter(AppDateUtils.today()))
            .toList();
        break;
      case _TaskFilter.completed:
        result = result.where((t) => t.isCompleted).toList();
        break;
      case _TaskFilter.all:
        break;
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      result = result.where((t) => t.title.toLowerCase().contains(q) || t.category.toLowerCase().contains(q)).toList();
    }
    result = [...result]
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        final ad = a.dueDate ?? DateTime(2100);
        final bd = b.dueDate ?? DateTime(2100);
        return ad.compareTo(bd);
      });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Tasks')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search tasks…',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _TaskFilter.values.map((f) {
                    final selected = f == _filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_filterLabel(f)),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = f),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.divider),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: tasksAsync.when(
                  data: (tasks) {
                    final filtered = _applyFilter(tasks);
                    if (filtered.isEmpty) {
                      return const EmptyState(
                        icon: Icons.task_alt_rounded,
                        title: 'No tasks here',
                        message: 'Try a different filter, or add a new task with the + button.',
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () => ref.read(taskListProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 100, top: 4),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final t = filtered[i];
                          return Dismissible(
                            key: ValueKey(t.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(18)),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                            ),
                            onDismissed: (_) => ref.read(taskListProvider.notifier).deleteTask(t.id),
                            child: TaskTile(
                              task: t,
                              onToggle: () => ref.read(taskListProvider.notifier).toggleComplete(t),
                              onTap: () => context.push(AppRoutes.editTask, extra: t),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addTask),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _filterLabel(_TaskFilter f) {
    switch (f) {
      case _TaskFilter.all:
        return 'All';
      case _TaskFilter.today:
        return 'Today';
      case _TaskFilter.upcoming:
        return 'Upcoming';
      case _TaskFilter.completed:
        return 'Completed';
    }
  }
}
