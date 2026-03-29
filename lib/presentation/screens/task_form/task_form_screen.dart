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
import '../../widgets/glass/glass_button.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.taskId});
  final String? taskId;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  WorkCategory _category = WorkCategory.agreementManagement;
  AgreementSubtype? _agreementSubtype;
  TaskStatus _status = TaskStatus.pending;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  bool _isDailyTodo = false;
  bool _isLoading = false;

  TaskModel? _existingTask;
  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _initFromTask(TaskModel task) {
    if (_initialized) return;
    _initialized = true;
    _existingTask = task;
    _titleController.text = task.title;
    _descController.text = task.description ?? '';
    _category = task.category;
    if (task.subtype != null && task.category == WorkCategory.agreementManagement) {
      _agreementSubtype = AgreementSubtype.values[task.subtype!];
    }
    _status = task.status;
    _priority = task.priority;
    _dueDate = task.dueDate;
    _isDailyTodo = task.isDailyTodo;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final actions = ref.read(taskActionsProvider);

    try {
      final subtype = _category == WorkCategory.agreementManagement
          ? _agreementSubtype?.index
          : null;

      if (_existingTask != null) {
        await actions.updateTask(_existingTask!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          category: _category,
          subtype: subtype,
          status: _status,
          priority: _priority,
          dueDate: _dueDate,
          isDailyTodo: _isDailyTodo,
        ));
      } else {
        await actions.createTask(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          category: _category,
          subtype: subtype,
          status: _status,
          priority: _priority,
          dueDate: _dueDate,
          isDailyTodo: _isDailyTodo,
        );
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.mediumBlue,
            onPrimary: Colors.white,
            surface: Color(0xFF005A80),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    // Load existing task if editing
    if (widget.taskId != null && !_initialized) {
      final taskAsync = ref.watch(taskDetailProvider(widget.taskId!));
      taskAsync.whenData((task) {
        if (task != null) _initFromTask(task);
      });
    }

    final isEditing = widget.taskId != null;
    final dateFormatter = DateFormat('yyyy년 MM월 dd일');

    return GlassScaffold(
      resizeToAvoidBottomInset: true,
      appBar: GlassAppBar(
        title: isEditing ? '업무 수정' : '새 업무',
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel(AppStrings.fieldTitle),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: '업무명을 입력하세요'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? '업무명을 입력하세요' : null,
                    maxLength: 200,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Description
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel(AppStrings.fieldDescription),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: '업무 내용을 입력하세요 (선택)'),
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Category
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel(AppStrings.fieldCategory),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: WorkCategory.values.map((c) {
                      final isSelected = _category == c;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _category = c;
                          if (c != WorkCategory.agreementManagement) _agreementSubtype = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? c.color.withValues(alpha: 0.3) : AppColors.glassWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? c.color : AppColors.glassBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(c.icon, size: 14, color: isSelected ? c.color : AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                c.label,
                                style: TextStyle(
                                  color: isSelected ? c.color : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // 협약관리 하위분류
                  if (_category == WorkCategory.agreementManagement) ...[
                    const SizedBox(height: 12),
                    const _FieldLabel('협약 유형'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: AgreementSubtype.values.map((s) {
                        final isSelected = _agreementSubtype == s;
                        return GestureDetector(
                          onTap: () => setState(() => _agreementSubtype = isSelected ? null : s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.lightBlue.withValues(alpha: 0.25)
                                  : AppColors.glassWhite,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.lightBlue : AppColors.glassBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              s.label,
                              style: TextStyle(
                                color: isSelected ? AppColors.lightBlue : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Priority & Status
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(AppStrings.fieldPriority),
                        const SizedBox(height: 10),
                        ...TaskPriority.values.map((p) => _RadioOption(
                              label: p.label,
                              color: p.color,
                              isSelected: _priority == p,
                              onTap: () => setState(() => _priority = p),
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('상태'),
                        const SizedBox(height: 10),
                        ...TaskStatus.values.map((s) => _RadioOption(
                              label: s.label,
                              color: s.color,
                              isSelected: _status == s,
                              onTap: () => setState(() => _status = s),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Due date
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: AppColors.lightBlue, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(AppStrings.fieldDueDate),
                        const SizedBox(height: 2),
                        Text(
                          _dueDate != null ? dateFormatter.format(_dueDate!) : AppStrings.noDueDate,
                          style: TextStyle(
                            color: _dueDate != null ? AppColors.textPrimary : AppColors.textHint,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GlassButton(label: '선택', isPrimary: false, onPressed: _pickDate),
                  if (_dueDate != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _dueDate = null),
                      child: const Icon(Icons.close, size: 16, color: AppColors.textHint),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Daily todo toggle
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.lightBlue, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(AppStrings.fieldAddToDailyTodo, style: TextStyle(color: AppColors.textPrimary)),
                  ),
                  Switch(
                    value: _isDailyTodo,
                    onChanged: (v) => setState(() => _isDailyTodo = v),
                    activeThumbColor: AppColors.lightBlue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            GlassButton(
              label: _isLoading ? '저장 중...' : AppStrings.actionSave,
              isFullWidth: true,
              onPressed: _isLoading ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: AppColors.textHint, fontSize: 12));
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({required this.label, required this.color, required this.isSelected, required this.onTap});
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
                border: Border.all(color: isSelected ? color : AppColors.glassBorder, width: isSelected ? 2 : 1),
              ),
              child: isSelected ? Center(child: Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle))) : null,
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? color : AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
