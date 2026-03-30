import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/work_category.dart';
import '../../../domain/models/task_model.dart';
import '../../providers/task_providers.dart';
import '../../widgets/glass/glass_card.dart';
import '../../widgets/glass/glass_scaffold.dart';

// 전체 업무 (카테고리 필터 없이) 가져오는 provider
final _allTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.fetchAllTasks();
});

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(_allTasksProvider);

    return GlassScaffold(
      appBar: GlassAppBar(title: '업무 통계'),
      body: tasksAsync.when(
        data: (tasks) => tasks.isEmpty
            ? const Center(
                child: Text('아직 업무가 없습니다.\n업무를 추가하면 통계를 볼 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary)))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _OverviewCard(tasks: tasks),
                  const SizedBox(height: 12),
                  _CategoryBreakdown(tasks: tasks),
                  const SizedBox(height: 12),
                  _AgreementSubtypeBreakdown(tasks: tasks),
                  const SizedBox(height: 12),
                  _StatusDistribution(tasks: tasks),
                  const SizedBox(height: 100),
                ],
              ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.lightBlue)),
        error: (e, _) => Center(
            child: Text('$e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}

// ── 전체 요약 ─────────────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.tasks});
  final List<TaskModel> tasks;

  @override
  Widget build(BuildContext context) {
    final total = tasks.length;
    final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
    final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('전체 현황',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              _BigStat(label: '전체', count: total, color: AppColors.textPrimary),
              _BigStat(label: '대기', count: pending, color: AppColors.statusPending),
              _BigStat(label: '진행중', count: inProgress, color: AppColors.statusInProgress),
              _BigStat(label: '완료', count: completed, color: AppColors.statusCompleted),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 16),
            // 완료율 바
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('완료율', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const Spacer(),
                    Text('${(completed / total * 100).toInt()}%',
                        style: const TextStyle(color: AppColors.statusCompleted, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completed / total,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.statusCompleted),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$count',
              style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── 카테고리별 업무량 ─────────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.tasks});
  final List<TaskModel> tasks;

  @override
  Widget build(BuildContext context) {
    final total = tasks.length;
    final categoryData = WorkCategory.values.map((c) {
      final count = tasks.where((t) => t.hasCategory(c)).length;
      return (category: c, count: count, ratio: total > 0 ? count / total : 0.0);
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('카테고리별 업무량',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          const SizedBox(height: 4),
          const Text('어느 영역에 업무가 집중되는지 확인하세요',
              style: TextStyle(color: AppColors.textHint, fontSize: 12)),
          const SizedBox(height: 16),
          ...categoryData.map((d) => _BarRow(
                icon: d.category.icon,
                label: d.category.label,
                count: d.count,
                ratio: d.ratio,
                color: d.category.color,
                total: total,
              )),
        ],
      ),
    );
  }
}

// ── 협약관리 하위분류 ─────────────────────────────────────────────────────────

class _AgreementSubtypeBreakdown extends StatelessWidget {
  const _AgreementSubtypeBreakdown({required this.tasks});
  final List<TaskModel> tasks;

  @override
  Widget build(BuildContext context) {
    final agreementTasks = tasks.where((t) => t.hasCategory(WorkCategory.agreementManagement)).toList();
    if (agreementTasks.isEmpty) return const SizedBox.shrink();

    final total = agreementTasks.length;
    final subtypeData = AgreementSubtype.values.map((s) {
      final count = agreementTasks.where((t) => t.subtype == s.index).length;
      return (subtype: s, count: count, ratio: total > 0 ? count / total : 0.0);
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final noSubtype = agreementTasks.where((t) => t.subtype == null).length;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake_outlined, size: 16, color: AppColors.lightBlue),
              const SizedBox(width: 8),
              const Text('협약관리 세부 분류',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          ...subtypeData.map((d) => _BarRow(
                label: d.subtype.label,
                count: d.count,
                ratio: d.ratio,
                color: AppColors.lightBlue,
                total: total,
              )),
          if (noSubtype > 0)
            _BarRow(
              label: '미분류',
              count: noSubtype,
              ratio: noSubtype / total,
              color: AppColors.textHint,
              total: total,
            ),
        ],
      ),
    );
  }
}

// ── 상태 분포 ─────────────────────────────────────────────────────────────────

class _StatusDistribution extends StatelessWidget {
  const _StatusDistribution({required this.tasks});
  final List<TaskModel> tasks;

  @override
  Widget build(BuildContext context) {
    final total = tasks.length;
    if (total == 0) return const SizedBox.shrink();

    final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
    final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('상태별 분포',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          const SizedBox(height: 16),
          // 스택 바
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 20,
              child: Row(
                children: [
                  if (pending > 0)
                    Expanded(
                      flex: pending,
                      child: Container(color: AppColors.statusPending),
                    ),
                  if (inProgress > 0)
                    Expanded(
                      flex: inProgress,
                      child: Container(color: AppColors.statusInProgress),
                    ),
                  if (completed > 0)
                    Expanded(
                      flex: completed,
                      child: Container(color: AppColors.statusCompleted),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LegendItem(label: '대기', count: pending, color: AppColors.statusPending),
              _LegendItem(label: '진행중', count: inProgress, color: AppColors.statusInProgress),
              _LegendItem(label: '완료', count: completed, color: AppColors.statusCompleted),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 공통 위젯 ─────────────────────────────────────────────────────────────────

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.count,
    required this.ratio,
    required this.color,
    required this.total,
    this.icon,
  });
  final String label;
  final int count;
  final double ratio;
  final Color color;
  final int total;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
              ],
              Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('$count건', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(width: 8),
              Text('${(ratio * 100).toInt()}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.7)),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label $count', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
