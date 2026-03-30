import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/remote/supabase_service.dart';
import '../../domain/enums/work_category.dart';
import '../../domain/models/task_model.dart';
import 'auth_provider.dart';

const _uuid = Uuid();

// ── Refresh trigger ──────────────────────────────────────────────────────────
// 이 값이 바뀌면 모든 데이터를 다시 가져옴 (WebSocket 없이 안정적으로 작동)

final _refreshProvider = StateProvider<int>((ref) => 0);
void refreshData(WidgetRef ref) => ref.read(_refreshProvider.notifier).state++;
void refreshDataFromRef(Ref ref) => ref.read(_refreshProvider.notifier).state++;

// ── Supabase Service ─────────────────────────────────────────────────────────

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final client = ref.watch(supabaseProvider);
  return SupabaseService(client);
});

// ── Task list ────────────────────────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<WorkCategory?>((ref) => null);

final taskListProvider = FutureProvider<List<TaskModel>>((ref) async {
  ref.watch(_refreshProvider);
  final service = ref.watch(supabaseServiceProvider);
  final category = ref.watch(selectedCategoryProvider);
  return service.fetchAllTasks(category: category);
});

// ── Single task detail ───────────────────────────────────────────────────────

final taskDetailProvider = FutureProvider.family<TaskModel?, String>((ref, taskId) async {
  ref.watch(_refreshProvider);
  final service = ref.watch(supabaseServiceProvider);
  final tasks = await service.fetchAllTasks();
  return tasks.where((t) => t.id == taskId).firstOrNull;
});

// ── Checklists ───────────────────────────────────────────────────────────────

final checklistProvider = FutureProvider.family<List<ChecklistItem>, String>((ref, taskId) async {
  ref.watch(_refreshProvider);
  final service = ref.watch(supabaseServiceProvider);
  return service.fetchChecklists(taskId);
});

// ── Activity logs ────────────────────────────────────────────────────────────

final activityLogsProvider = FutureProvider.family<List<ActivityLogModel>, String>((ref, taskId) async {
  ref.watch(_refreshProvider);
  final service = ref.watch(supabaseServiceProvider);
  return service.fetchActivityLogs(taskId);
});

// ── Tags ─────────────────────────────────────────────────────────────────────

final tagsProvider = FutureProvider<List<TagModel>>((ref) async {
  ref.watch(_refreshProvider);
  final service = ref.watch(supabaseServiceProvider);
  return service.fetchTags();
});

// ── Daily todo ───────────────────────────────────────────────────────────────

final dailyTodoProvider = FutureProvider<List<TaskModel>>((ref) async {
  ref.watch(_refreshProvider);
  final service = ref.watch(supabaseServiceProvider);
  return service.fetchDailyTodos();
});

// ── Actions ──────────────────────────────────────────────────────────────────

class TaskActions {
  TaskActions(this._service, this._ref);
  final SupabaseService _service;
  final Ref _ref;

  void _refresh() => refreshDataFromRef(_ref);

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
    _refresh();
  }

  Future<void> updateTask(TaskModel task) async {
    await _service.updateTask(task);
    _refresh();
  }

  Future<void> deleteTask(String id) async {
    await _service.deleteTask(id);
    _refresh();
  }

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
  Future<void> createTag(String name, {String color = '#009DC4'}) async {
    await _service.insertTag(id: _uuid.v4(), name: name, color: color);
    _refresh();
  }

  Future<void> deleteTag(String id) async {
    await _service.deleteTag(id);
    _refresh();
  }

  Future<void> updateTaskTags(String taskId, List<String> tagIds) async {
    await _service.updateTaskTags(taskId, tagIds);
    _refresh();
  }

  // Checklists
  Future<void> addChecklistItem({required String taskId, required String content}) async {
    await _service.insertChecklist(id: _uuid.v4(), taskId: taskId, content: content);
    _refresh();
  }

  Future<void> toggleChecklistItem(String id, bool isDone) async {
    await _service.toggleChecklist(id, isDone);
    _refresh();
  }

  Future<void> deleteChecklistItem(String id) async {
    await _service.deleteChecklist(id);
    _refresh();
  }

  // Activity logs
  Future<void> addActivityLog({required String taskId, required String content}) async {
    await _service.insertActivityLog(id: _uuid.v4(), taskId: taskId, content: content);
    _refresh();
  }

  Future<void> deleteActivityLog(String id) async {
    await _service.deleteActivityLog(id);
    _refresh();
  }
}

final taskActionsProvider = Provider<TaskActions>((ref) {
  return TaskActions(ref.watch(supabaseServiceProvider), ref);
});
