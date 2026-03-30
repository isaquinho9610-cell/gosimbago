import '../enums/work_category.dart';

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.categories,
    this.subtype,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isDailyTodo = false,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String? description;
  final List<WorkCategory> categories; // 복수 카테고리
  final int? subtype;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isDailyTodo;
  final List<TagModel> tags; // 커스텀 태그

  /// 첫 번째 카테고리 (하위호환)
  WorkCategory get primaryCategory =>
      categories.isNotEmpty ? categories.first : WorkCategory.otherWork;

  bool hasCategory(WorkCategory c) => categories.contains(c);

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    List<WorkCategory>? categories,
    int? subtype,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isDailyTodo,
    List<TagModel>? tags,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      subtype: subtype ?? this.subtype,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isDailyTodo: isDailyTodo ?? this.isDailyTodo,
      tags: tags ?? this.tags,
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

class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.taskId,
    required this.content,
    this.isDone = false,
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final String content;
  final bool isDone;
  final DateTime createdAt;
}

class TagModel {
  const TagModel({
    required this.id,
    required this.name,
    this.color = '#009DC4',
  });

  final String id;
  final String name;
  final String color;
}
