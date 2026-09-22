import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/habit_model.dart';

class HabitService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<HabitModel>> fetchHabits(String userId) async {
    final rows = await _client.from('habits').select().eq('user_id', userId).order('created_at');
    return (rows as List).map((r) => HabitModel.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Logs for the last [days] days across all of the user's habits, used to
  /// compute streaks and the Analytics "habit consistency" chart in one
  /// round trip instead of one query per habit.
  Future<List<HabitLogModel>> fetchRecentLogs(String userId, {int days = 60}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final rows = await _client
        .from('habit_logs')
        .select()
        .eq('user_id', userId)
        .gte('completed_date', since.toIso8601String().split('T').first);
    return (rows as List).map((r) => HabitLogModel.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<HabitModel> createHabit(HabitModel draft, String userId) async {
    final row = await _client.from('habits').insert(draft.toInsertJson(userId)).select().single();
    return HabitModel.fromJson(row);
  }

  Future<HabitModel> updateHabit(HabitModel habit) async {
    final row = await _client.from('habits').update(habit.toUpdateJson()).eq('id', habit.id).select().single();
    return HabitModel.fromJson(row);
  }

  Future<void> deleteHabit(String id) async {
    await _client.from('habits').delete().eq('id', id);
  }

  /// Marks [habitId] complete for today. Relies on the DB's unique
  /// (habit_id, completed_date) constraint to stay idempotent.
  Future<void> checkInToday(String habitId, String userId) async {
    final today = DateTime.now();
    final dateStr = DateTime(today.year, today.month, today.day).toIso8601String().split('T').first;
    await _client.from('habit_logs').upsert(
      {
        'habit_id': habitId,
        'user_id': userId,
        'completed_date': dateStr,
      },
      onConflict: 'habit_id,completed_date',
    );
  }

  Future<void> undoToday(String habitId) async {
    final today = DateTime.now();
    final dateStr = DateTime(today.year, today.month, today.day).toIso8601String().split('T').first;
    await _client.from('habit_logs').delete().eq('habit_id', habitId).eq('completed_date', dateStr);
  }
}
