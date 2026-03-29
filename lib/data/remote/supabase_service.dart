import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/enums/work_category.dart';
import '../../domain/models/task_model.dart';

class SupabaseService {
  SupabaseService(this._client);
  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  // ── Tasks ──────────────────────────────────────────────────────────────────

  Stream<List<TaskModel>> watchAllTasks({WorkCategory? category}) {
    var query = _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId);

    return query.map((rows) {
      var tasks = rows.map(_rowToTask).toList();

      // 카테고리 필터
      if (category != null) {
        tasks = tasks.where((t) => t.category == category).toList();
      }

      // 정렬: 고정 먼저, 최신순
      tasks.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      return tasks;
    });
  }

  Stream<List<TaskModel>> watchDailyTodos() {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .map((rows) => rows
            .map(_rowToTask)
            .where((t) => t.isDailyTodo)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  }

  Future<void> insertTask(TaskModel task) async {
    await _client.from('tasks').insert({
      'id': task.id,
      'user_id': _userId,
      'title': task.title,
      'description': task.description,
      'category': task.category.index,
      'subtype': task.subtype,
      'status': task.status.index,
      'priority': task.priority.index,
      'due_date': task.dueDate?.toIso8601String(),
      'is_pinned': task.isPinned,
      'is_daily_todo': task.isDailyTodo,
      'created_at': task.createdAt.toIso8601String(),
      'updated_at': task.updatedAt.toIso8601String(),
    });
  }

  Future<void> updateTask(TaskModel task) async {
    await _client.from('tasks').update({
      'title': task.title,
      'description': task.description,
      'category': task.category.index,
      'subtype': task.subtype,
      'status': task.status.index,
      'priority': task.priority.index,
      'due_date': task.dueDate?.toIso8601String(),
      'is_pinned': task.isPinned,
      'is_daily_todo': task.isDailyTodo,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', task.id);
  }

  Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id);
  }

  // ── Activity Logs ──────────────────────────────────────────────────────────

  Stream<List<ActivityLogModel>> watchActivityLogs(String taskId) {
    return _client
        .from('activity_logs')
        .stream(primaryKey: ['id'])
        .eq('task_id', taskId)
        .map((rows) => rows.map(_rowToLog).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<void> insertActivityLog({
    required String id,
    required String taskId,
    required String content,
  }) async {
    await _client.from('activity_logs').insert({
      'id': id,
      'task_id': taskId,
      'user_id': _userId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteActivityLog(String id) async {
    await _client.from('activity_logs').delete().eq('id', id);
  }

  // ── Mappers ────────────────────────────────────────────────────────────────

  TaskModel _rowToTask(Map<String, dynamic> row) {
    return TaskModel(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      category: WorkCategory.values[row['category'] as int],
      subtype: row['subtype'] as int?,
      status: TaskStatus.values[row['status'] as int],
      priority: TaskPriority.values[row['priority'] as int],
      dueDate: row['due_date'] != null ? DateTime.parse(row['due_date'] as String) : null,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      isPinned: row['is_pinned'] as bool? ?? false,
      isDailyTodo: row['is_daily_todo'] as bool? ?? false,
    );
  }

  ActivityLogModel _rowToLog(Map<String, dynamic> row) {
    return ActivityLogModel(
      id: row['id'] as String,
      taskId: row['task_id'] as String,
      content: row['content'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
