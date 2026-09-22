import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task_model.dart';

/// All Supabase reads/writes for tasks. Row Level Security (see
/// supabase/schema.sql) enforces the user_id scoping server-side; the
/// `.eq('user_id', ...)` filters here are for clarity and query efficiency,
/// not the security boundary itself.
class TaskService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<TaskModel>> fetchTasks(String userId) async {
    final rows = await _client
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .order('due_date', ascending: true, nullsFirst: false)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => TaskModel.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<TaskModel> createTask(TaskModel draft, String userId) async {
    final row = await _client.from('tasks').insert(draft.toInsertJson(userId)).select().single();
    return TaskModel.fromJson(row);
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    final row = await _client.from('tasks').update(task.toUpdateJson()).eq('id', task.id).select().single();
    return TaskModel.fromJson(row);
  }

  Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id);
  }

  Future<TaskModel> setStatus(String id, String status) async {
    final row = await _client
        .from('tasks')
        .update({'status': status, 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .select()
        .single();
    return TaskModel.fromJson(row);
  }
}
