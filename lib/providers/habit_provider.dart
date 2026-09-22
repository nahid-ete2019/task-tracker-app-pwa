import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_utils.dart';
import '../models/habit_model.dart';
import '../services/habit_service.dart';
import 'auth_provider.dart';

final habitServiceProvider = Provider<HabitService>((ref) => HabitService());

class HabitsState {
  final List<HabitModel> habits;
  final List<HabitLogModel> recentLogs;

  const HabitsState({this.habits = const [], this.recentLogs = const []});

  Set<DateTime> completedDatesFor(String habitId) => recentLogs
      .where((l) => l.habitId == habitId)
      .map((l) => DateTime(l.completedDate.year, l.completedDate.month, l.completedDate.day))
      .toSet();

  bool isCompletedToday(String habitId) => completedDatesFor(habitId).contains(AppDateUtils.today());

  int streakFor(String habitId) => AppDateUtils.currentStreak(completedDatesFor(habitId));

  HabitsState copyWith({List<HabitModel>? habits, List<HabitLogModel>? recentLogs}) {
    return HabitsState(
      habits: habits ?? this.habits,
      recentLogs: recentLogs ?? this.recentLogs,
    );
  }
}

class HabitListNotifier extends AsyncNotifier<HabitsState> {
  @override
  Future<HabitsState> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const HabitsState();
    final service = ref.read(habitServiceProvider);
    final habits = await service.fetchHabits(user.id);
    final logs = await service.fetchRecentLogs(user.id);
    return HabitsState(habits: habits, recentLogs: logs);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> addHabit(HabitModel draft) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final created = await ref.read(habitServiceProvider).createHabit(draft, user.id);
    final current = state.value ?? const HabitsState();
    state = AsyncValue.data(current.copyWith(habits: [...current.habits, created]));
  }

  Future<void> editHabit(HabitModel habit) async {
    final updated = await ref.read(habitServiceProvider).updateHabit(habit);
    final current = state.value ?? const HabitsState();
    final list = [...current.habits];
    final idx = list.indexWhere((h) => h.id == habit.id);
    if (idx != -1) list[idx] = updated;
    state = AsyncValue.data(current.copyWith(habits: list));
  }

  Future<void> deleteHabit(String id) async {
    final current = state.value ?? const HabitsState();
    state = AsyncValue.data(HabitsState(
      habits: current.habits.where((h) => h.id != id).toList(),
      recentLogs: current.recentLogs.where((l) => l.habitId != id).toList(),
    ));
    await ref.read(habitServiceProvider).deleteHabit(id);
  }

  Future<void> toggleToday(String habitId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final current = state.value ?? const HabitsState();
    final alreadyDone = current.isCompletedToday(habitId);
    final service = ref.read(habitServiceProvider);
    if (alreadyDone) {
      await service.undoToday(habitId);
    } else {
      await service.checkInToday(habitId, user.id);
    }
    await refresh();
  }
}

final habitListProvider = AsyncNotifierProvider<HabitListNotifier, HabitsState>(HabitListNotifier.new);
