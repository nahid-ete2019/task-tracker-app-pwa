import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final TaskModel? task;

  const AddEditTaskScreen({super.key, this.task});

  bool get isEditing => task != null;

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late String _category;
  late String _priority;
  late String _status;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _category = t?.category ?? AppConstants.taskCategories.first;
    _priority = t?.priority ?? 'medium';
    _status = t?.status ?? 'todo';
    _dueDate = t?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
    );
    setState(() {
      _dueDate = DateTime(date.year, date.month, date.day, time?.hour ?? 9, time?.minute ?? 0);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        final updated = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          category: _category,
          priority: _priority,
          status: _status,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
        );
        await ref.read(taskListProvider.notifier).editTask(updated);
      } else {
        final draft = TaskModel(
          id: '',
          userId: '',
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          category: _category,
          priority: _priority,
          status: _status,
          dueDate: _dueDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ref.read(taskListProvider.notifier).addTask(draft);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save task: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Done';
      case 'todo':
      default:
        return 'Open';
    }
  }

  Future<void> _delete() async {
    if (widget.task == null) return;
    await ref.read(taskListProvider.notifier).deleteTask(widget.task!.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Task' : 'New Task'),
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
                decoration: const InputDecoration(labelText: 'Title'),
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
                items: AppConstants.taskCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 14),
              const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: AppConstants.taskPriorities.map((p) {
                  final selected = p == _priority;
                  final color = AppColors.priorityColor(p);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(p[0].toUpperCase() + p.substring(1)),
                      selected: selected,
                      onSelected: (_) => setState(() => _priority = p),
                      selectedColor: color,
                      labelStyle: TextStyle(color: selected ? Colors.white : color, fontWeight: FontWeight.w600),
                      backgroundColor: color.withOpacity(0.08),
                      side: BorderSide(color: color.withOpacity(0.3)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: AppConstants.taskStatuses.map((s) {
                  final selected = s == _status;
                  final color = AppColors.statusColor(s);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_statusLabel(s)),
                      selected: selected,
                      onSelected: (_) => setState(() => _status = s),
                      selectedColor: color,
                      labelStyle: TextStyle(color: selected ? Colors.white : color, fontWeight: FontWeight.w600),
                      backgroundColor: color.withOpacity(0.08),
                      side: BorderSide(color: color.withOpacity(0.3)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Due date & time'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dueDate == null
                            ? 'No due date'
                            : '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}  ${TimeOfDay.fromDateTime(_dueDate!).format(context)}',
                      ),
                      if (_dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() => _dueDate = null),
                        )
                      else
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.isEditing ? 'Save Changes' : 'Create Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
