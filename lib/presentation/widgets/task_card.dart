import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/models/task_model.dart';
import '../../domain/enums/work_category.dart';
import '../../core/constants/app_colors.dart';
import 'glass/glass_card.dart';
import 'category_badge.dart';
import 'status_badge.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.onLongPress,
    this.index = 0,
  });

  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == TaskStatus.completed;

    // 우선순위별 배경색
    final priorityBg = switch (task.priority) {
      TaskPriority.high => AppColors.priorityHigh.withValues(alpha: 0.12),
      TaskPriority.medium => AppColors.priorityMedium.withValues(alpha: 0.06),
      TaskPriority.low => Colors.transparent,
    };
    final priorityBorder = switch (task.priority) {
      TaskPriority.high => AppColors.priorityHigh.withValues(alpha: 0.3),
      TaskPriority.medium => AppColors.priorityMedium.withValues(alpha: 0.15),
      TaskPriority.low => null,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: priorityBg,
        borderRadius: BorderRadius.circular(16),
        border: priorityBorder != null ? Border.all(color: priorityBorder, width: 1) : null,
      ),
      child: GlassCard(
        margin: EdgeInsets.zero,
        opacity: task.priority == TaskPriority.high ? 0.04 : 0.08,
        onTap: onTap,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Priority indicator bar
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: task.priority.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            color: isCompleted ? AppColors.textHint : AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: AppColors.textHint,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.description != null && task.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            task.description!,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (task.isPinned)
                    const Icon(Icons.push_pin, size: 14, color: AppColors.lightBlue),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // 복수 카테고리 뱃지
                  ...task.categories.take(2).map((c) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: CategoryBadge(category: c, small: true),
                      )),
                  if (task.categories.length > 2)
                    Text('+${task.categories.length - 2}',
                        style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
                  const SizedBox(width: 4),
                  StatusBadge(status: task.status),
                  // 커스텀 태그
                  if (task.tags.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    ...task.tags.take(1).map((tag) => _TagChip(tag: tag)),
                  ],
                  const Spacer(),
                  if (task.dueDate != null) ...[
                    Icon(Icons.calendar_today_outlined, size: 11, color: _dueDateColor(task.dueDate!)),
                    const SizedBox(width: 3),
                    Text(
                      _formatDate(task.dueDate!),
                      style: TextStyle(color: _dueDateColor(task.dueDate!), fontSize: 11),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 50)).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Color _dueDateColor(DateTime due) {
    final diff = due.difference(DateTime.now()).inDays;
    if (diff < 0) return AppColors.priorityHigh;
    if (diff <= 3) return AppColors.priorityMedium;
    return AppColors.textHint;
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}';
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});
  final TagModel tag;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(tag.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(tag.name,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }

  Color _parseColor(String hex) {
    final code = hex.replaceFirst('#', '');
    return Color(int.parse('FF$code', radix: 16));
  }
}
