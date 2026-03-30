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
import '../../widgets/status_badge.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskDetailProvider(taskId));

    return taskAsync.when(
      data: (task) => task == null
          ? GlassScaffold(
              appBar: GlassAppBar(title: '업무 없음'),
              body: const Center(
                  child: Text('업무를 찾을 수 없습니다.',
                      style: TextStyle(color: Colors.white))),
            )
          : _TaskDetailContent(task: task),
      loading: () => const GlassScaffold(
        appBar: null,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.lightBlue)),
      ),
      error: (e, _) => GlassScaffold(
        appBar: GlassAppBar(title: '오류'),
        body: Center(
            child: Text('$e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}

class _TaskDetailContent extends ConsumerWidget {
  const _TaskDetailContent({required this.task});
  final TaskModel task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogsProvider(task.id));
    final checklistAsync = ref.watch(checklistProvider(task.id));
    final actions = ref.read(taskActionsProvider);
    final dateFormatter = DateFormat('yyyy년 MM월 dd일');

    return GlassScaffold(
      appBar: GlassAppBar(
        title: task.categories.map((c) => c.label).join(' · '),
        actions: [
          IconButton(
            icon: Icon(
              task.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: task.isPinned ? AppColors.lightBlue : AppColors.textSecondary,
            ),
            onPressed: () => actions.togglePin(task),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
            onPressed: () => context.push('/task/${task.id}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.priorityHigh),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.bgElevated,
                  title: const Text('업무 삭제',
                      style: TextStyle(color: Colors.white)),
                  content: const Text('이 업무를 삭제하시겠습니까?',
                      style: TextStyle(color: AppColors.textSecondary)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소',
                            style: TextStyle(color: AppColors.textSecondary))),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('삭제',
                            style: TextStyle(color: AppColors.priorityHigh))),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await actions.deleteTask(task.id);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // ── Header ──
          GlassCard(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...task.categories.map((c) => CategoryBadge(category: c)),
                    if (task.hasCategory(WorkCategory.agreementManagement) &&
                        task.subtype != null)
                      _SubtypeBadge(label: AgreementSubtype.values[task.subtype!].label, color: AppColors.lightBlue),
                    if (task.hasCategory(WorkCategory.dispatchWork) &&
                        task.dispatchSubtype != null)
                      _SubtypeBadge(label: DispatchSubtype.values[task.dispatchSubtype!].label, color: AppColors.mediumBlue),
                    StatusBadge(status: task.status),
                    ...task.tags.map((tag) => _TagBadge(tag: tag)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Spacer(),
                    _PriorityDot(priority: task.priority),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  task.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (task.dueDate != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Text(dateFormatter.format(task.dueDate!),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ]),
                ],
              ],
            ),
          ),

          // ── Status Stepper ──
          GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            child: _StatusStepper(task: task),
          ),

          // ── Description ──
          if (task.description != null && task.description!.isNotEmpty)
            GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('내용',
                      style: TextStyle(
                          color: AppColors.textHint, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(task.description!,
                      style: const TextStyle(
                          color: AppColors.textPrimary, height: 1.6)),
                ],
              ),
            ),

          // ── Checklist ──
          GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.checklist, color: AppColors.lightBlue, size: 16),
                  const SizedBox(width: 8),
                  const Text('체크리스트',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  // 진행률
                  checklistAsync.when(
                    data: (items) {
                      if (items.isEmpty) return const SizedBox.shrink();
                      final done = items.where((i) => i.isDone).length;
                      return Text('$done/${items.length}',
                          style: const TextStyle(color: AppColors.lightBlue, fontSize: 12, fontWeight: FontWeight.w600));
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ]),
                const SizedBox(height: 12),
                _ChecklistInput(taskId: task.id),
                const SizedBox(height: 8),
                checklistAsync.when(
                  data: (items) => items.isEmpty
                      ? const Text('체크리스트 항목을 추가하세요',
                          style: TextStyle(color: AppColors.textHint, fontSize: 13))
                      : Column(
                          children: items.map((item) => _ChecklistRow(
                                item: item,
                                onToggle: () => actions.toggleChecklistItem(item.id, !item.isDone),
                                onDelete: () => actions.deleteChecklistItem(item.id),
                              )).toList(),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // ── Daily Todo Toggle ──
          GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              const Icon(Icons.check_circle_outline,
                  color: AppColors.lightBlue, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                  child: Text(AppStrings.fieldAddToDailyTodo,
                      style: TextStyle(color: AppColors.textPrimary))),
              Switch(
                value: task.isDailyTodo,
                onChanged: (_) => actions.toggleDailyTodo(task),
                activeThumbColor: AppColors.lightBlue,
              ),
            ]),
          ),

          // ── Activity Log ──
          GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.history, color: AppColors.lightBlue, size: 16),
                  SizedBox(width: 8),
                  Text('Activity Log',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
                // 입력창
                _ActivityLogInput(taskId: task.id),
                const SizedBox(height: 12),
                const Divider(color: AppColors.glassBorder, height: 1),
                const SizedBox(height: 8),
                // 로그 목록
                logsAsync.when(
                  data: (logs) => logs.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('아직 기록이 없습니다.',
                              style: TextStyle(
                                  color: AppColors.textHint, fontSize: 13)),
                        )
                      : Column(
                          children: logs
                              .map((log) => _ActivityLogItem(
                                    log: log,
                                    onDelete: () =>
                                        actions.deleteActivityLog(log.id),
                                  ))
                              .toList(),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity Log Input ────────────────────────────────────────────────────────

class _ActivityLogInput extends ConsumerStatefulWidget {
  const _ActivityLogInput({required this.taskId});
  final String taskId;

  @override
  ConsumerState<_ActivityLogInput> createState() => _ActivityLogInputState();
}

class _ActivityLogInputState extends ConsumerState<_ActivityLogInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(taskActionsProvider).addActivityLog(taskId: widget.taskId, content: text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
              hintText: '업무 진행 상황을 기록하세요...\n(예: 상대교에 표준협약양식 발송완료)',
              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _submit,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.mediumBlue.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightBlue.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}

// ── Activity Log Item ─────────────────────────────────────────────────────────

class _ActivityLogItem extends StatelessWidget {
  const _ActivityLogItem({required this.log, required this.onDelete});
  final ActivityLogModel log;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final timeFormatter = DateFormat('MM월 dd일 · HH:mm');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: const BoxDecoration(
              color: AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.content,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.5)),
                const SizedBox(height: 2),
                Text(timeFormatter.format(log.createdAt),
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.close, size: 14, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Stepper ────────────────────────────────────────────────────────────

class _StatusStepper extends ConsumerWidget {
  const _StatusStepper({required this.task});
  final TaskModel task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(taskActionsProvider);
    final statuses = TaskStatus.values;

    return Row(
      children: statuses.asMap().entries.map((e) {
        final status = e.value;
        final isCurrent = task.status == status;
        final isPast = e.key < task.status.index;

        return Expanded(
          child: GestureDetector(
            onTap: task.status != status
                ? () => actions.updateTask(task.copyWith(status: status))
                : null,
            child: Column(
              children: [
                Row(children: [
                  if (e.key > 0)
                    Expanded(
                        child: Container(
                            height: 2,
                            color: isPast ? status.color : AppColors.glassBorder)),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent || isPast
                          ? status.color.withValues(alpha: 0.3)
                          : Colors.transparent,
                      border: Border.all(
                        color: isCurrent || isPast
                            ? status.color
                            : AppColors.glassBorder,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: isCurrent || isPast
                        ? Icon(Icons.check, size: 14, color: status.color)
                        : null,
                  ),
                  if (e.key < statuses.length - 1)
                    Expanded(
                        child: Container(
                            height: 2,
                            color: isPast
                                ? AppColors.statusCompleted
                                : AppColors.glassBorder)),
                ]),
                const SizedBox(height: 4),
                Text(
                  status.label,
                  style: TextStyle(
                    color: isCurrent ? status.color : AppColors.textHint,
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SubtypeBadge extends StatelessWidget {
  const _SubtypeBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});
  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: priority.color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(priority.label,
          style: TextStyle(
              color: priority.color,
              fontSize: 12,
              fontWeight: FontWeight.w500)),
    ]);
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.tag});
  final TagModel tag;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(tag.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(tag.name,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  Color _parseColor(String hex) {
    final code = hex.replaceFirst('#', '');
    return Color(int.parse('FF$code', radix: 16));
  }
}

// ── Checklist Input ───────────────────────────────────────────────────────────

class _ChecklistInput extends ConsumerStatefulWidget {
  const _ChecklistInput({required this.taskId});
  final String taskId;

  @override
  ConsumerState<_ChecklistInput> createState() => _ChecklistInputState();
}

class _ChecklistInputState extends ConsumerState<_ChecklistInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(taskActionsProvider).addChecklistItem(taskId: widget.taskId, content: text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              hintText: '체크리스트 항목 추가...',
              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _submit,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.mediumBlue.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}

// ── Checklist Row ─────────────────────────────────────────────────────────────

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.item, required this.onToggle, required this.onDelete});
  final ChecklistItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: item.isDone ? AppColors.statusCompleted.withValues(alpha: 0.3) : Colors.transparent,
                border: Border.all(
                  color: item.isDone ? AppColors.statusCompleted : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: item.isDone
                  ? const Icon(Icons.check, size: 14, color: AppColors.statusCompleted)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.content,
              style: TextStyle(
                color: item.isDone ? AppColors.textHint : AppColors.textPrimary,
                fontSize: 13,
                decoration: item.isDone ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textHint,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.close, size: 14, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}
