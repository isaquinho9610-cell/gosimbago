import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/remote/supabase_service.dart';
import '../../domain/enums/work_category.dart';
import '../../domain/models/task_model.dart';
import 'auth_provider.dart';

const _uuid = Uuid();

// ── Supabase Service ─────────────────────────────────────────────────────────

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final client = ref.watch(supabaseProvider);
  return SupabaseService(client);
});

// ── Task list (reactive stream) ──────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<WorkCategory?>((ref) => null);
final selectedTagProvider = StateProvider<String?>((ref) => null); // tag id

final taskListProvider = StreamProvider<List<TaskModel>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  final category = ref.watch(selectedCategoryProvider);
  return service.watchAllTasks(category: category);
});

// ── Single task detail ───────────────────────────────────────────────────────

final taskDetailProvider =
    StreamProvider.family<TaskModel?, String>((ref, taskId) {
  final service = ref.watch(supabaseServiceProvider);
  return service
      .watchAllTasks()
      .map((tasks) => tasks.where((t) => t.id == taskId).firstOrNull);
});

// ── Checklists ───────────────────────────────────────────────────────────────

final checklistProvider =
    StreamProvider.family<List<ChecklistItem>, String>((ref, taskId) {
  final service = ref.watch(supabaseServiceProvider);
  return service.watchChecklists(taskId);
});

// ── Activity logs ────────────────────────────────────────────────────────────

final activityLogsProvider =
    StreamProvider.family<List<ActivityLogModel>, String>((ref, taskId) {
  final service = ref.watch(supabaseServiceProvider);
  return service.watchActivityLogs(taskId);
});

// ── Tags ─────────────────────────────────────────────────────────────────────

final tagsProvider = StreamProvider<List<TagModel>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.watchTags();
});

// ── Daily todo ───────────────────────────────────────────────────────────────

final dailyTodoProvider = StreamProvider<List<TaskModel>>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.watchDailyTodos();
});

// ── Actions ──────────────────────────────────────────────────────────────────

class TaskActions {
  const TaskActions(this._service);
  final SupabaseService _service;

  Future<void> createTask({
    required String title,
    String? description,
    required List<WorkCategory> categories,
    int? subtype,
    required TaskStatus status,
    required TaskPriority priority,
    DateTime? dueDate,
    bool isDailyTodo = false,
    List<TagModel> tags = const [],
  }) async {
    final now = DateTime.now();
    await _service.insertTask(TaskModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      categories: categories,
      subtype: subtype,
      status: status,
      priority: priority,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
      isDailyTodo: isDailyTodo,
      tags: tags,
    ));
  }

  Future<void> updateTask(TaskModel task) => _service.updateTask(task);
  Future<void> deleteTask(String id) => _service.deleteTask(id);

  Future<void> advanceStatus(TaskModel task) async {
    final nextStatus = switch (task.status) {
      TaskStatus.pending => TaskStatus.inProgress,
      TaskStatus.inProgress => TaskStatus.completed,
      TaskStatus.completed => TaskStatus.completed,
    };
    await updateTask(task.copyWith(status: nextStatus));
  }

  Future<void> togglePin(TaskModel task) =>
      updateTask(task.copyWith(isPinned: !task.isPinned));

  Future<void> toggleDailyTodo(TaskModel task) =>
      updateTask(task.copyWith(isDailyTodo: !task.isDailyTodo));

  // Tags
  Future<void> createTag(String name, {String color = '#009DC4'}) =>
      _service.insertTag(id: _uuid.v4(), name: name, color: color);

  Future<void> deleteTag(String id) => _service.deleteTag(id);

  Future<void> updateTaskTags(String taskId, List<String> tagIds) =>
      _service.updateTaskTags(taskId, tagIds);

  // Checklists
  Future<void> addChecklistItem({required String taskId, required String content}) =>
      _service.insertChecklist(id: _uuid.v4(), taskId: taskId, content: content);

  Future<void> toggleChecklistItem(String id, bool isDone) =>
      _service.toggleChecklist(id, isDone);

  Future<void> deleteChecklistItem(String id) => _service.deleteChecklist(id);

  // Activity logs
  Future<void> addActivityLog({required String taskId, required String content}) =>
      _service.insertActivityLog(id: _uuid.v4(), taskId: taskId, content: content);

  Future<void> deleteActivityLog(String id) => _service.deleteActivityLog(id);
}

final taskActionsProvider = Provider<TaskActions>((ref) {
  return TaskActions(ref.watch(supabaseServiceProvider));
});
