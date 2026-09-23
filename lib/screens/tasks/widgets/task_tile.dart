import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/task_model.dart';
import '../../../widgets/common/priority_chip.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const TaskTile({super.key, required this.task, required this.onToggle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final overdue = AppDateUtils.isOverdue(task.dueDate, completed: task.isCompleted);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  _statusIcon(task.status),
                  color: AppColors.statusColor(task.status),
                  size: 26,
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
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                        color: task.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (task.status == 'in_progress') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'In Progress',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.info),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (task.dueDate != null) ...[
                          Icon(Icons.schedule_rounded, size: 13, color: overdue ? AppColors.danger : AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${AppDateUtils.friendlyDate(task.dueDate!)} · ${AppDateUtils.friendlyTime(task.dueDate!)}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: overdue ? AppColors.danger : AppColors.textMuted,
                              fontWeight: overdue ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PriorityChip(priority: task.priority),
            ],
          ),
        ),
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'in_progress':
        return Icons.timelapse_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'todo':
      default:
        return Icons.radio_button_unchecked_rounded;
    }
  }
}
