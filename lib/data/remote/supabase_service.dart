import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/enums/work_category.dart';
import '../../domain/models/task_model.dart';

class SupabaseService {
  SupabaseService(this._client);
  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser!.id;

  // ── Tasks ──────────────────────────────────────────────────────────────────

  Future<List<TaskModel>> fetchAllTasks({WorkCategory? category}) async {
    final rows = await _client
        .from('tasks')
        .select()
        .eq('user_id', _userId)
        .order('is_pinned', ascending: false)
        .order('priority', ascending: false)
        .order('created_at', ascending: false);

    var tasks = (rows as List).map((r) => _rowToTask(r as Map<String, dynamic>)).toList();

    if (category != null) {
      tasks = tasks.where((t) => t.hasCategory(category)).toList();
    }

    return tasks;
  }

  Future<List<TaskModel>> fetchDailyTodos() async {
    final rows = await _client
        .from('tasks')
        .select()
        .eq('user_id', _userId)
        .eq('is_daily_todo', true)
        .order('created_at');

    return (rows as List).map((r) => _rowToTask(r as Map<String, dynamic>)).toList();
  }

  Future<void> insertTask(TaskModel task) async {
    await _client.from('tasks').insert({
      'id': task.id,
      'user_id': _userId,
      'title': task.title,
      'description': task.description,
      'category': task.primaryCategory.index,
      'categories': task.categories.map((c) => c.index).toList(),
      'subtype': task.subtype,
      'dispatch_subtype': task.dispatchSubtype,
      'status': task.status.index,
      'priority': task.priority.index,
      'due_date': task.dueDate?.toIso8601String(),
      'is_pinned': task.isPinned,
      'is_daily_todo': task.isDailyTodo,
      'created_at': task.createdAt.toIso8601String(),
      'updated_at': task.updatedAt.toIso8601String(),
    });

    if (task.tags.isNotEmpty) {
      await _client.from('task_tags').insert(
        task.tags.map((t) => {'task_id': task.id, 'tag_id': t.id}).toList(),
      );
    }
  }

  Future<void> updateTask(TaskModel task) async {
    await _client.from('tasks').update({
      'title': task.title,
      'description': task.description,
      'category': task.primaryCategory.index,
      'categories': task.categories.map((c) => c.index).toList(),
      'subtype': task.subtype,
      'dispatch_subtype': task.dispatchSubtype,
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

  Future<void> updateTaskTags(String taskId, List<String> tagIds) async {
    await _client.from('task_tags').delete().eq('task_id', taskId);
    if (tagIds.isNotEmpty) {
      await _client.from('task_tags').insert(
        tagIds.map((id) => {'task_id': taskId, 'tag_id': id}).toList(),
      );
    }
  }

  // ── Checklists ─────────────────────────────────────────────────────────────

  Future<List<ChecklistItem>> fetchChecklists(String taskId) async {
    final rows = await _client
        .from('checklists')
        .select()
        .eq('task_id', taskId)
        .order('created_at');

    return (rows as List).map((r) => _rowToChecklist(r as Map<String, dynamic>)).toList();
  }

  Future<void> insertChecklist({required String id, required String taskId, required String content}) async {
    await _client.from('checklists').insert({
      'id': id, 'task_id': taskId, 'user_id': _userId,
      'content': content, 'is_done': false, 'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> toggleChecklist(String id, bool isDone) async {
    await _client.from('checklists').update({'is_done': isDone}).eq('id', id);
  }

  Future<void> deleteChecklist(String id) async {
    await _client.from('checklists').delete().eq('id', id);
  }

  // ── Activity Logs ──────────────────────────────────────────────────────────

  Future<List<ActivityLogModel>> fetchActivityLogs(String taskId) async {
    final rows = await _client
        .from('activity_logs')
        .select()
        .eq('task_id', taskId)
        .order('created_at', ascending: false);

    return (rows as List).map((r) => _rowToLog(r as Map<String, dynamic>)).toList();
  }

  Future<void> insertActivityLog({required String id, required String taskId, required String content}) async {
    await _client.from('activity_logs').insert({
      'id': id, 'task_id': taskId, 'user_id': _userId,
      'content': content, 'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteActivityLog(String id) async {
    await _client.from('activity_logs').delete().eq('id', id);
  }

  // ── Tags ───────────────────────────────────────────────────────────────────

  Future<List<TagModel>> fetchTags() async {
    final rows = await _client.from('tags').select().eq('user_id', _userId);
    return (rows as List).map((r) => _rowToTag(r as Map<String, dynamic>)).toList();
  }

  Future<void> insertTag({required String id, required String name, String color = '#009DC4'}) async {
    await _client.from('tags').insert({
      'id': id, 'user_id': _userId, 'name': name, 'color': color,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteTag(String id) async {
    await _client.from('tags').delete().eq('id', id);
  }

  // ── Mappers ────────────────────────────────────────────────────────────────

  TaskModel _rowToTask(Map<String, dynamic> row) {
    List<WorkCategory> cats = [];
    final rawCats = row['categories'];
    if (rawCats is List && rawCats.isNotEmpty) {
      cats = rawCats
          .map((c) => WorkCategory.values[c is int ? c : int.parse(c.toString())])
          .toList();
    } else {
      cats = [WorkCategory.values[row['category'] as int? ?? 0]];
    }

    return TaskModel(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      categories: cats,
      subtype: row['subtype'] as int?,
      dispatchSubtype: row['dispatch_subtype'] as int?,
      status: TaskStatus.values[row['status'] as int? ?? 0],
      priority: TaskPriority.values[row['priority'] as int? ?? 1],
      dueDate: row['due_date'] != null ? DateTime.parse(row['due_date'] as String) : null,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      isPinned: row['is_pinned'] as bool? ?? false,
      isDailyTodo: row['is_daily_todo'] as bool? ?? false,
    );
  }

  ActivityLogModel _rowToLog(Map<String, dynamic> row) => ActivityLogModel(
    id: row['id'] as String, taskId: row['task_id'] as String,
    content: row['content'] as String, createdAt: DateTime.parse(row['created_at'] as String),
  );

  ChecklistItem _rowToChecklist(Map<String, dynamic> row) => ChecklistItem(
    id: row['id'] as String, taskId: row['task_id'] as String,
    content: row['content'] as String, isDone: row['is_done'] as bool? ?? false,
    createdAt: DateTime.parse(row['created_at'] as String),
  );

  TagModel _rowToTag(Map<String, dynamic> row) => TagModel(
    id: row['id'] as String, name: row['name'] as String,
    color: row['color'] as String? ?? '#009DC4',
  );
}
