import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/habit_model.dart';

class HabitCard extends StatelessWidget {
  final HabitModel habit;
  final bool completedToday;
  final int streak;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const HabitCard({
    super.key,
    required this.habit,
    required this.completedToday,
    required this.streak,
    required this.onToggle,
    required this.onTap,
  });

  Color get _color {
    try {
      final hex = habit.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.repeat_rounded, color: _color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.warning),
                        const SizedBox(width: 3),
                        Text('$streak day streak', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: completedToday ? AppColors.success : AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: completedToday ? AppColors.success : AppColors.divider),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: completedToday ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
