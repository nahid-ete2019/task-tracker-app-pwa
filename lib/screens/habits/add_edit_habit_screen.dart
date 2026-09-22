import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/habit_model.dart';
import '../../providers/habit_provider.dart';

class AddEditHabitScreen extends ConsumerStatefulWidget {
  final HabitModel? habit;

  const AddEditHabitScreen({super.key, this.habit});

  bool get isEditing => habit != null;

  @override
  ConsumerState<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late String _frequency;
  late int _target;

  static const _colorOptions = ['#6C5CE7', '#00CEC9', '#FDA23A', '#FF6B6B', '#54A0FF', '#00B894'];
  late String _color;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _titleController = TextEditingController(text: h?.title ?? '');
    _frequency = h?.frequency ?? 'daily';
    _target = h?.targetPerPeriod ?? 1;
    _color = h?.color ?? _colorOptions.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        final updated = HabitModel(
          id: widget.habit!.id,
          userId: widget.habit!.userId,
          title: _titleController.text.trim(),
          icon: 'star',
          color: _color,
          frequency: _frequency,
          targetPerPeriod: _target,
          createdAt: widget.habit!.createdAt,
        );
        await ref.read(habitListProvider.notifier).editHabit(updated);
      } else {
        final draft = HabitModel(
          id: '',
          userId: '',
          title: _titleController.text.trim(),
          icon: 'star',
          color: _color,
          frequency: _frequency,
          targetPerPeriod: _target,
          createdAt: DateTime.now(),
        );
        await ref.read(habitListProvider.notifier).addHabit(draft);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save habit: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.habit == null) return;
    await ref.read(habitListProvider.notifier).deleteHabit(widget.habit!.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Habit' : 'New Habit'),
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
                decoration: const InputDecoration(labelText: 'Habit name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Frequency', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: AppConstants.habitFrequencies.map((f) {
                  final selected = f == _frequency;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f[0].toUpperCase() + f.substring(1)),
                      selected: selected,
                      onSelected: (_) => setState(() => _frequency = f),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textSecondary),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.divider),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Target / period:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const Spacer(),
                  IconButton(
                    onPressed: _target > 1 ? () => setState(() => _target--) : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                  Text('$_target', style: const TextStyle(fontWeight: FontWeight.w700)),
                  IconButton(
                    onPressed: () => setState(() => _target++),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _colorOptions.map((hex) {
                  final color = Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
                  final selected = hex == _color;
                  return GestureDetector(
                    onTap: () => setState(() => _color = hex),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: AppColors.textPrimary, width: 2) : null,
                      ),
                      child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.isEditing ? 'Save Changes' : 'Create Habit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
