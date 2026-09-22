import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal_model.dart';
import '../services/goal_service.dart';
import 'auth_provider.dart';

final goalServiceProvider = Provider<GoalService>((ref) => GoalService());

class GoalListNotifier extends AsyncNotifier<List<GoalModel>> {
  @override
  Future<List<GoalModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return ref.read(goalServiceProvider).fetchGoals(user.id);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> addGoal(GoalModel draft) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final created = await ref.read(goalServiceProvider).createGoal(draft, user.id);
    state = AsyncValue.data([created, ...state.value ?? []]);
  }

  Future<void> editGoal(GoalModel goal) async {
    final updated = await ref.read(goalServiceProvider).updateGoal(goal);
    final list = [...state.value ?? []];
    final idx = list.indexWhere((g) => g.id == goal.id);
    if (idx != -1) list[idx] = updated;
    state = AsyncValue.data(list);
  }

  Future<void> deleteGoal(String id) async {
    final previous = state.value ?? [];
    state = AsyncValue.data(previous.where((g) => g.id != id).toList());
    await ref.read(goalServiceProvider).deleteGoal(id);
  }

  Future<void> addMilestone(String goalId, String title) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(goalServiceProvider).addMilestone(goalId, user.id, title);
    await refresh();
  }

  Future<void> toggleMilestone(String goalId, String milestoneId, bool isCompleted) async {
    await ref.read(goalServiceProvider).toggleMilestone(milestoneId, isCompleted);
    await refresh();
  }
}

final goalListProvider = AsyncNotifierProvider<GoalListNotifier, List<GoalModel>>(GoalListNotifier.new);
