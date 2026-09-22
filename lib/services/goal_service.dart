import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/goal_model.dart';

class GoalService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<GoalModel>> fetchGoals(String userId) async {
    final goalRows = await _client.from('goals').select().eq('user_id', userId).order('created_at', ascending: false);
    final milestoneRows = await _client.from('goal_milestones').select().eq('user_id', userId);

    final milestonesByGoal = <String, List<GoalMilestoneModel>>{};
    for (final row in milestoneRows as List) {
      final m = GoalMilestoneModel.fromJson(row as Map<String, dynamic>);
      milestonesByGoal.putIfAbsent(m.goalId, () => []).add(m);
    }

    return (goalRows as List)
        .map((r) => GoalModel.fromJson(
              r as Map<String, dynamic>,
              milestones: milestonesByGoal[r['id']] ?? const [],
            ))
        .toList();
  }

  Future<GoalModel> createGoal(GoalModel draft, String userId) async {
    final row = await _client.from('goals').insert(draft.toInsertJson(userId)).select().single();
    return GoalModel.fromJson(row);
  }

  Future<GoalModel> updateGoal(GoalModel goal) async {
    final row = await _client.from('goals').update(goal.toUpdateJson()).eq('id', goal.id).select().single();
    return GoalModel.fromJson(row, milestones: goal.milestones);
  }

  Future<void> deleteGoal(String id) async {
    await _client.from('goals').delete().eq('id', id);
  }

  Future<GoalMilestoneModel> addMilestone(String goalId, String userId, String title) async {
    final row = await _client
        .from('goal_milestones')
        .insert({'goal_id': goalId, 'user_id': userId, 'title': title, 'is_completed': false})
        .select()
        .single();
    return GoalMilestoneModel.fromJson(row);
  }

  Future<void> toggleMilestone(String milestoneId, bool isCompleted) async {
    await _client.from('goal_milestones').update({'is_completed': isCompleted}).eq('id', milestoneId);
  }

  Future<void> deleteMilestone(String milestoneId) async {
    await _client.from('goal_milestones').delete().eq('id', milestoneId);
  }
}
