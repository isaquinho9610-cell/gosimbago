import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/work_category.dart';
import '../../../domain/models/task_model.dart';
import '../../providers/task_providers.dart';
import '../../widgets/glass/glass_card.dart';
import '../../widgets/glass/glass_scaffold.dart';
import '../../widgets/task_card.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final selectedDayProvider = StateProvider<DateTime?>((ref) => null);
final focusedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());
final showCompletedProvider = StateProvider<bool>((ref) => false);

// ── HomeScreen ────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskListProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedDay = ref.watch(selectedDayProvider);

    final filteredTasks = taskAsync.whenData((tasks) {
      if (selectedDay == null) return tasks;
      return tasks.where((t) {
        if (t.dueDate == null) return false;
        return isSameDay(t.dueDate!, selectedDay);
      }).toList();
    });

    return GlassScaffold(
      appBar: GlassAppBar(
        title: AppStrings.appTitle,
        actions: [
          if (selectedDay != null)
            TextButton(
              onPressed: () =>
                  ref.read(selectedDayProvider.notifier).state = null,
              child: const Text('전체 보기',
                  style: TextStyle(color: AppColors.lightBlue, fontSize: 12)),
            ),
        ],
      ),
      body: filteredTasks.when(
        data: (tasks) => CustomScrollView(
          slivers: [
            // ── 위클리 캘린더 (컴팩트) ──
            SliverToBoxAdapter(
              child: taskAsync.when(
                data: (allTasks) => _WeeklyCalendar(tasks: allTasks),
                loading: () => const SizedBox(height: 8),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // ── 요약 통계 ──
            SliverToBoxAdapter(
              child: taskAsync.when(
                data: (allTasks) => _StatsSummary(tasks: allTasks),
                loading: () => const SizedBox(height: 36),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // ── 카테고리 필터 또는 날짜 헤더 ──
            SliverToBoxAdapter(
              child: selectedDay == null
                  ? _CategoryFilterBar(selected: selectedCategory)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
                      child: Row(children: [
                        const Icon(Icons.filter_alt_outlined,
                            size: 14, color: AppColors.lightBlue),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('M월 d일 (E)', 'ko').format(selectedDay),
                          style: const TextStyle(
                              color: AppColors.lightBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ]),
                    ),
            ),

            // ── 업무 목록 (진행중) ──
            ..._buildTaskSections(context, ref, tasks, selectedDay != null),
          ],
        ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.lightBlue)),
        error: (e, _) => Center(
            child:
                Text('오류: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  List<Widget> _buildTaskSections(BuildContext context, WidgetRef ref, List<TaskModel> tasks, bool isFiltered) {
    final activeTasks = tasks.where((t) => t.status != TaskStatus.completed).toList();
    final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).toList();
    final showCompleted = ref.watch(showCompletedProvider);

    if (activeTasks.isEmpty && completedTasks.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(isFiltered: isFiltered),
        ),
      ];
    }

    return [
      // 진행중 업무
      if (activeTasks.isNotEmpty)
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => TaskCard(
              task: activeTasks[i],
              index: i,
              onTap: () => context.push('/task/${activeTasks[i].id}'),
              onLongPress: () => _showTaskOptions(context, ref, activeTasks[i]),
            ),
            childCount: activeTasks.length,
          ),
        ),

      // 완료됨 토글 헤더
      if (completedTasks.isNotEmpty)
        SliverToBoxAdapter(
          child: GestureDetector(
            onTap: () => ref.read(showCompletedProvider.notifier).state = !showCompleted,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Icon(
                    showCompleted ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '완료됨 (${completedTasks.length})',
                    style: const TextStyle(color: AppColors.textHint, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),

      // 완료된 업무 리스트 (토글)
      if (completedTasks.isNotEmpty && showCompleted)
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => TaskCard(
                task: completedTasks[i],
                index: i,
                onTap: () => context.push('/task/${completedTasks[i].id}'),
                onLongPress: () => _showTaskOptions(context, ref, completedTasks[i]),
              ),
              childCount: completedTasks.length,
            ),
          ),
        ),

      // 하단 패딩 (완료 숨김일 때)
      if (!showCompleted || completedTasks.isEmpty)
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
    ];
  }

  void _showTaskOptions(BuildContext context, WidgetRef ref, TaskModel task) {
    final actions = ref.read(taskActionsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassCard(
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                  task.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: AppColors.textPrimary),
              title: Text(task.isPinned ? '고정 해제' : '고정',
                  style: const TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                actions.togglePin(task);
              },
            ),
            ListTile(
              leading: Icon(
                  task.isDailyTodo
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  color: AppColors.textPrimary),
              title: Text(task.isDailyTodo ? '오늘 할일 해제' : '오늘 할일 추가',
                  style: const TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                actions.toggleDailyTodo(task);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
              title: const Text('수정',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                context.push('/task/${task.id}/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppColors.priorityHigh),
              title: const Text('삭제',
                  style: TextStyle(color: AppColors.priorityHigh)),
              onTap: () {
                Navigator.pop(context);
                actions.deleteTask(task.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Weekly Calendar (컴팩트 주간 뷰) ──────────────────────────────────────────

class _WeeklyCalendar extends ConsumerWidget {
  const _WeeklyCalendar({required this.tasks});
  final List<TaskModel> tasks;

  List<TaskModel> _getTasksForDay(DateTime day) {
    return tasks
        .where((t) => t.dueDate != null && isSameDay(t.dueDate!, day))
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedDay = ref.watch(focusedDayProvider);
    final selectedDay = ref.watch(selectedDayProvider);

    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: TableCalendar<TaskModel>(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2028, 12, 31),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        eventLoader: _getTasksForDay,
        calendarFormat: CalendarFormat.week,
        availableCalendarFormats: const {CalendarFormat.week: 'Week'},
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextFormatter: (date, locale) =>
              DateFormat('yyyy년 M월', 'ko').format(date),
          titleTextStyle: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14),
          leftChevronIcon: const Icon(Icons.chevron_left,
              color: AppColors.textSecondary, size: 20),
          rightChevronIcon: const Icon(Icons.chevron_right,
              color: AppColors.textSecondary, size: 20),
          headerPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle:
              TextStyle(color: AppColors.textSecondary, fontSize: 12),
          weekendStyle:
              TextStyle(color: AppColors.statusPending, fontSize: 12),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          cellMargin: const EdgeInsets.all(3),
          defaultTextStyle: const TextStyle(
              color: AppColors.textPrimary, fontSize: 13),
          weekendTextStyle: const TextStyle(
              color: AppColors.statusPending, fontSize: 13),
          todayDecoration: BoxDecoration(
            color: AppColors.mediumBlue.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.mediumBlue,
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13),
          selectedTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13),
          markerDecoration: const BoxDecoration(
            color: AppColors.lightBlue,
            shape: BoxShape.circle,
          ),
          markerSize: 4,
          markersMaxCount: 3,
        ),
        onDaySelected: (selected, focused) {
          final current = ref.read(selectedDayProvider);
          if (isSameDay(current, selected)) {
            ref.read(selectedDayProvider.notifier).state = null;
          } else {
            ref.read(selectedDayProvider.notifier).state = selected;
          }
          ref.read(focusedDayProvider.notifier).state = focused;
        },
        onPageChanged: (focused) {
          ref.read(focusedDayProvider.notifier).state = focused;
        },
      ),
    );
  }
}

// ── Stats ─────────────────────────────────────────────────────────────────────

class _StatsSummary extends StatelessWidget {
  const _StatsSummary({required this.tasks});
  final List<TaskModel> tasks;

  @override
  Widget build(BuildContext context) {
    final pending =
        tasks.where((t) => t.status == TaskStatus.pending).length;
    final inProgress =
        tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final completed =
        tasks.where((t) => t.status == TaskStatus.completed).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Row(children: [
        _StatChip(
            label: '대기', count: pending, color: AppColors.statusPending),
        const SizedBox(width: 8),
        _StatChip(
            label: '진행중',
            count: inProgress,
            color: AppColors.statusInProgress),
        const SizedBox(width: 8),
        _StatChip(
            label: '완료',
            count: completed,
            color: AppColors.statusCompleted),
        const Spacer(),
        Text('전체 ${tasks.length}건',
            style:
                const TextStyle(color: AppColors.textHint, fontSize: 12)),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text('$label $count',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Category Filter ───────────────────────────────────────────────────────────

class _CategoryFilterBar extends ConsumerWidget {
  const _CategoryFilterBar({required this.selected});
  final WorkCategory? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _FilterChip(
            label: AppStrings.allCategories,
            isSelected: selected == null,
            onTap: () =>
                ref.read(selectedCategoryProvider.notifier).state = null,
          ),
          ...WorkCategory.values.map((c) => _FilterChip(
                label: c.label,
                isSelected: selected == c,
                color: c.color,
                onTap: () =>
                    ref.read(selectedCategoryProvider.notifier).state = c,
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label,
      required this.isSelected,
      this.color,
      required this.onTap});
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.lightBlue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.15)
              : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor.withValues(alpha: 0.5) : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                color: isSelected ? chipColor : AppColors.textSecondary,
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              )),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isFiltered});
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(
            isFiltered
                ? Icons.event_busy_outlined
                : Icons.inbox_outlined,
            size: 56,
            color: AppColors.textHint),
        const SizedBox(height: 16),
        Text(
          isFiltered ? '이 날짜에 마감인 업무가 없습니다' : AppStrings.emptyTasks,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.6),
        ),
      ]),
    );
  }
}
