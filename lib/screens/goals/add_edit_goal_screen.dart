import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/goal_model.dart';
import '../../providers/goal_provider.dart';

class AddEditGoalScreen extends ConsumerStatefulWidget {
  final GoalModel? goal;

  const AddEditGoalScreen({super.key, this.goal});

  bool get isEditing => goal != null;

  @override
  ConsumerState<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends ConsumerState<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _milestoneController;
  late String _category;
  DateTime? _targetDate;
  double _manualProgress = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _titleController = TextEditingController(text: g?.title ?? '');
    _descController = TextEditingController(text: g?.description ?? '');
    _milestoneController = TextEditingController();
    _category = g?.category ?? AppConstants.goalCategories.first;
    _targetDate = g?.targetDate;
    _manualProgress = g?.manualProgress ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _milestoneController.dispose();
    super.dispose();
  }

  Future<void> _pickTargetDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) setState(() => _targetDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        final updated = GoalModel(
          id: widget.goal!.id,
          userId: widget.goal!.userId,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          category: _category,
          icon: widget.goal!.icon,
          color: widget.goal!.color,
          targetDate: _targetDate,
          status: widget.goal!.status,
          manualProgress: _manualProgress,
          createdAt: widget.goal!.createdAt,
          milestones: widget.goal!.milestones,
        );
        await ref.read(goalListProvider.notifier).editGoal(updated);
      } else {
        final draft = GoalModel(
          id: '',
          userId: '',
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          category: _category,
          icon: 'flag',
          color: '#6C5CE7',
          targetDate: _targetDate,
          status: 'active',
          manualProgress: _manualProgress,
          createdAt: DateTime.now(),
        );
        await ref.read(goalListProvider.notifier).addGoal(draft);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save goal: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.goal == null) return;
    await ref.read(goalListProvider.notifier).deleteGoal(widget.goal!.id);
    if (mounted) context.pop();
  }

  Future<void> _addMilestone() async {
    final title = _milestoneController.text.trim();
    if (title.isEmpty || widget.goal == null) return;
    await ref.read(goalListProvider.notifier).addMilestone(widget.goal!.id, title);
    _milestoneController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final goals = widget.isEditing ? ref.watch(goalListProvider).value ?? [] : const <GoalModel>[];
    final liveGoal = widget.isEditing
        ? goals.firstWhere((g) => g.id == widget.goal!.id, orElse: () => widget.goal!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Goal' : 'New Goal'),
        actions: [
          if (widget.isEditing)
            IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger)),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Goal title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: AppConstants.goalCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickTargetDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Target date (optional)'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_targetDate == null
                          ? 'No target date'
                          : '${_targetDate!.year}-${_targetDate!.month.toString().padLeft(2, '0')}-${_targetDate!.day.toString().padLeft(2, '0')}'),
                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              if (liveGoal == null || liveGoal.milestones.isEmpty) ...[
                const SizedBox(height: 18),
                Text('Progress: ${_manualProgress.round()}%',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Slider(
                  value: _manualProgress,
                  max: 100,
                  divisions: 20,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _manualProgress = v),
                ),
              ],
              if (widget.isEditing) ...[
                const SizedBox(height: 8),
                const Text('Milestones', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 10),
                ...?liveGoal?.milestones.map((m) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: m.isCompleted,
                      activeColor: AppColors.primary,
                      title: Text(m.title, style: const TextStyle(fontSize: 14)),
                      onChanged: (v) => ref
                          .read(goalListProvider.notifier)
                          .toggleMilestone(widget.goal!.id, m.id, v ?? false),
                    )),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _milestoneController,
                        decoration: const InputDecoration(hintText: 'Add a milestone…'),
                        onSubmitted: (_) => _addMilestone(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addMilestone,
                      icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.isEditing ? 'Save Changes' : 'Create Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
