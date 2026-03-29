import 'package:drift/drift.dart';

import '../../domain/enums/work_category.dart';
import '../../domain/models/task_model.dart';
import 'connection.dart' as conn;

part 'app_database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────────────────

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(max: 200)();
  TextColumn get description => text().nullable()();
  IntColumn get category => integer()(); // WorkCategory.index
  IntColumn get subtype => integer().nullable()(); // AgreementSubtype.index (협약관리만)
  IntColumn get status => integer()(); // TaskStatus.index
  IntColumn get priority => integer()(); // TaskPriority.index
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isDailyTodo => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class ActivityLogs extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Tasks, ActivityLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(conn.connect());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(activityLogs);
            // drop old followUps if exists (best effort)
            await customStatement('DROP TABLE IF EXISTS follow_ups');
          }
        },
      );

  // ── Tasks ──

  Stream<List<Task>> watchAllTasks({WorkCategory? category}) {
    final query = select(tasks)
      ..orderBy([
        (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);

    if (category != null) {
      query.where((t) => t.category.equals(category.index));
    }
    return query.watch();
  }

  Future<Task?> getTaskById(String id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertTask(TasksCompanion task) => into(tasks).insert(task);

  Future<void> updateTask(TasksCompanion task) =>
      (update(tasks)..where((t) => t.id.equals(task.id.value))).write(task);

  Future<void> deleteTask(String id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  Stream<List<Task>> watchDailyTodos(DateTime date) {
    return (select(tasks)
          ..where((t) => t.isDailyTodo.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .watch();
  }

  // ── ActivityLogs ──

  Stream<List<ActivityLog>> watchActivityLogs(String taskId) =>
      (select(activityLogs)
            ..where((l) => l.taskId.equals(taskId))
            ..orderBy([(l) => OrderingTerm(expression: l.createdAt, mode: OrderingMode.desc)]))
          .watch();

  Future<void> insertActivityLog(ActivityLogsCompanion log) =>
      into(activityLogs).insert(log);

  Future<void> deleteActivityLog(String id) =>
      (delete(activityLogs)..where((l) => l.id.equals(id))).go();
}

// ─── Mappers ──────────────────────────────────────────────────────────────────

extension TaskMapper on Task {
  TaskModel toModel() => TaskModel(
        id: id,
        title: title,
        description: description,
        category: WorkCategory.values[category],
        subtype: subtype,
        status: TaskStatus.values[status],
        priority: TaskPriority.values[priority],
        dueDate: dueDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isPinned: isPinned,
        isDailyTodo: isDailyTodo,
      );
}

extension ActivityLogMapper on ActivityLog {
  ActivityLogModel toModel() => ActivityLogModel(
        id: id,
        taskId: taskId,
        content: content,
        createdAt: createdAt,
      );
}
