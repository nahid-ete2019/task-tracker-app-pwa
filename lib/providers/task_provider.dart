import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_model.dart';
import '../services/task_service.dart';
import 'auth_provider.dart';

final taskServiceProvider = Provider<TaskService>((ref) => TaskService());

/// Holds the signed-in user's full task list and exposes create/update/
/// delete/toggle operations that optimistically update local state and
/// persist to Supabase.
class TaskListNotifier extends AsyncNotifier<List<TaskModel>> {
  @override
  Future<List<TaskModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return ref.read(taskServiceProvider).fetchTasks(user.id);
  }

  Future<void> refresh() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(taskServiceProvider).fetchTasks(user.id));
  }

  Future<void> addTask(TaskModel draft) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final created = await ref.read(taskServiceProvider).createTask(draft, user.id);
    state = AsyncValue.data([created, ...state.value ?? []]);
  }

  Future<void> editTask(TaskModel task) async {
    final updated = await ref.read(taskServiceProvider).updateTask(task);
    final list = [...state.value ?? []];
    final idx = list.indexWhere((t) => t.id == task.id);
    if (idx != -1) list[idx] = updated;
    state = AsyncValue.data(list);
  }

  Future<void> deleteTask(String id) async {
    final previous = state.value ?? [];
    state = AsyncValue.data(previous.where((t) => t.id != id).toList());
    try {
      await ref.read(taskServiceProvider).deleteTask(id);
    } catch (_) {
      state = AsyncValue.data(previous);
      rethrow;
    }
  }

  Future<void> toggleComplete(TaskModel task) async {
    final newStatus = task.isCompleted ? 'todo' : 'completed';
    final list = [...state.value ?? []];
    final idx = list.indexWhere((t) => t.id == task.id);
    if (idx != -1) list[idx] = task.copyWith(status: newStatus);
    state = AsyncValue.data(list);
    try {
      final updated = await ref.read(taskServiceProvider).setStatus(task.id, newStatus);
      final refreshed = [...state.value ?? []];
      final i = refreshed.indexWhere((t) => t.id == task.id);
      if (i != -1) refreshed[i] = updated;
      state = AsyncValue.data(refreshed);
    } catch (_) {
      state = AsyncValue.data(list.map((t) => t.id == task.id ? task : t).toList());
      rethrow;
    }
  }
}

final taskListProvider = AsyncNotifierProvider<TaskListNotifier, List<TaskModel>>(TaskListNotifier.new);
