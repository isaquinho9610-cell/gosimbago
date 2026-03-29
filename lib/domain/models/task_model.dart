import '../enums/work_category.dart';

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.subtype,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isDailyTodo = false,
  });

  final String id;
  final String title;
  final String? description;
  final WorkCategory category;
  final int? subtype; // AgreementSubtype.index (협약관리만)
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isDailyTodo;

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    WorkCategory? category,
    int? subtype,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isDailyTodo,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      subtype: subtype ?? this.subtype,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isDailyTodo: isDailyTodo ?? this.isDailyTodo,
    );
  }
}

class ActivityLogModel {
  const ActivityLogModel({
    required this.id,
    required this.taskId,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final String content;
  final DateTime createdAt;
}
