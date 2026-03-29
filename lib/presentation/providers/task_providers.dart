import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';
import '../../domain/enums/work_category.dart';
import '../../domain/models/task_model.dart';
import 'database_provider.dart';

const _uuid = Uuid();

// ── Task list (reactive stream) ──────────────────────────────────────────────

final selectedCategoryProvider = StateProvider<WorkCategory?>((ref) => null);

final taskListProvider = StreamProvider<List<TaskModel>>((ref) {
  final db = ref.watch(databaseProvider);
  final category = ref.watch(selectedCategoryProvider);

  return db.watchAllTasks(category: category).map(
        (rows) => rows.map((r) => r.toModel()).toList(),
      );
});

// ── Single task detail ───────────────────────────────────────────────────────

final taskDetailProvider =
    StreamProvider.family<TaskModel?, String>((ref, taskId) {
  final db = ref.watch(databaseProvider);
  return db
      .watchAllTasks()
      .map((rows) => rows.where((r) => r.id == taskId).firstOrNull?.toModel());
});

// ── Activity logs ────────────────────────────────────────────────────────────

final activityLogsProvider =
    StreamProvider.family<List<ActivityLogModel>, String>((ref, taskId) {
  final db = ref.watch(databaseProvider);
  return db
      .watchActivityLogs(taskId)
      .map((rows) => rows.map((r) => r.toModel()).toList());
});

// ── Daily todo ───────────────────────────────────────────────────────────────

final dailyTodoProvider = StreamProvider<List<TaskModel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .watchDailyTodos(DateTime.now())
      .map((rows) => rows.map((r) => r.toModel()).toList());
});

// ── Actions ──────────────────────────────────────────────────────────────────

class TaskActions {
  const TaskActions(this._db);
  final AppDatabase _db;

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
    await _db.insertTask(TasksCompanion(
      id: Value(_uuid.v4()),
      title: Value(title),
      description: Value(description),
      category: Value(category.index),
      subtype: Value(subtype),
      status: Value(status.index),
      priority: Value(priority.index),
      dueDate: Value(dueDate),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDailyTodo: Value(isDailyTodo),
    ));
  }

  Future<void> updateTask(TaskModel task) async {
    await _db.updateTask(TasksCompanion(
      id: Value(task.id),
      title: Value(task.title),
      description: Value(task.description),
      category: Value(task.category.index),
      subtype: Value(task.subtype),
      status: Value(task.status.index),
      priority: Value(task.priority.index),
      dueDate: Value(task.dueDate),
      updatedAt: Value(DateTime.now()),
      isPinned: Value(task.isPinned),
      isDailyTodo: Value(task.isDailyTodo),
    ));
  }

  Future<void> deleteTask(String id) => _db.deleteTask(id);

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
  Future<void> addActivityLog({required String taskId, required String content}) =>
      _db.insertActivityLog(ActivityLogsCompanion(
        id: Value(_uuid.v4()),
        taskId: Value(taskId),
        content: Value(content),
        createdAt: Value(DateTime.now()),
      ));

  Future<void> deleteActivityLog(String id) => _db.deleteActivityLog(id);
}

final taskActionsProvider = Provider<TaskActions>((ref) {
  return TaskActions(ref.watch(databaseProvider));
});
