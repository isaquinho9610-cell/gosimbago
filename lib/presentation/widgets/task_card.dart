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

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      onTap: onTap,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Priority indicator
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
                          color: AppColors.textPrimary,
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
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
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
                CategoryBadge(category: task.category, small: true),
                const SizedBox(width: 6),
                StatusBadge(status: task.status),
                const Spacer(),
                if (task.dueDate != null) ...[
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 11,
                    color: _dueDateColor(task.dueDate!),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _formatDate(task.dueDate!),
                    style: TextStyle(
                      color: _dueDateColor(task.dueDate!),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 50)).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Color _dueDateColor(DateTime due) {
    final now = DateTime.now();
    final diff = due.difference(now).inDays;
    if (diff < 0) return AppColors.priorityHigh;
    if (diff <= 3) return AppColors.priorityMedium;
    return AppColors.textHint;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
