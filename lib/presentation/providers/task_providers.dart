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

// ── Activity logs ────────────────────────────────────────────────────────────

final activityLogsProvider =
    StreamProvider.family<List<ActivityLogModel>, String>((ref, taskId) {
  final service = ref.watch(supabaseServiceProvider);
  return service.watchActivityLogs(taskId);
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
    required WorkCategory category,
    int? subtype,
    required TaskStatus status,
    required TaskPriority priority,
    DateTime? dueDate,
    bool isDailyTodo = false,
  }) async {
    final now = DateTime.now();
    await _service.insertTask(TaskModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      category: category,
      subtype: subtype,
      status: status,
      priority: priority,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
      isDailyTodo: isDailyTodo,
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

  // Activity logs
  Future<void> addActivityLog({
    required String taskId,
    required String content,
  }) =>
      _service.insertActivityLog(
          id: _uuid.v4(), taskId: taskId, content: content);

  Future<void> deleteActivityLog(String id) =>
      _service.deleteActivityLog(id);
}

final taskActionsProvider = Provider<TaskActions>((ref) {
  return TaskActions(ref.watch(supabaseServiceProvider));
});
