import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/work_category.dart';
import '../../../domain/models/task_model.dart';
import '../../providers/task_providers.dart';
import '../../widgets/glass/glass_card.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/category_badge.dart';

class DailyTodoScreen extends ConsumerWidget {
  const DailyTodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(dailyTodoProvider);
    final today = DateTime.now();
    final formatter = DateFormat('yyyy년 MM월 dd일 (E)', 'ko');

    return GlassScaffold(
      appBar: GlassAppBar(title: AppStrings.navDailyTodo),
      body: Column(
        children: [
          // Date header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.lightBlue, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    formatter.format(today),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  todosAsync.when(
                    data: (todos) {
                      final done = todos.where((t) => t.status == TaskStatus.completed).length;
                      return Text(
                        '$done / ${todos.length}',
                        style: const TextStyle(color: AppColors.lightBlue, fontWeight: FontWeight.w600),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          // Todo list
          Expanded(
            child: todosAsync.when(
              data: (todos) => todos.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: todos.length,
                      itemBuilder: (context, i) => _TodoItem(
                        task: todos[i],
                        onTap: () => context.push('/task/${todos[i].id}'),
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.lightBlue)),
              error: (e, _) => Center(child: Text('오류: $e', style: const TextStyle(color: Colors.white))),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoItem extends ConsumerWidget {
  const _TodoItem({required this.task, required this.onTap});
  final TaskModel task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(taskActionsProvider);
    final isDone = task.status == TaskStatus.completed;

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Checkbox-like status toggle
          GestureDetector(
            onTap: () => actions.advanceStatus(task),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppColors.statusCompleted.withValues(alpha: 0.3) : Colors.transparent,
                border: Border.all(
                  color: isDone ? AppColors.statusCompleted : AppColors.glassBorder,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: AppColors.statusCompleted)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      color: isDone ? AppColors.textHint : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  CategoryBadge(category: task.primaryCategory, small: true),
                ],
              ),
            ),
          ),
          // Remove from daily todo
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.textHint),
            onPressed: () => actions.toggleDailyTodo(task),
            tooltip: '오늘 할일에서 제거',
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 56, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text(
            AppStrings.emptyDailyTodo,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}
