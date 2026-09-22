import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Circular progress indicator with a centered percentage label, matching
/// the "Daily Progress" / "Productivity Score" rings in the reference UI.
class ProgressRing extends StatelessWidget {
  final double progress; // 0..1
  final double size;
  final double strokeWidth;
  final Color color;
  final String? centerLabel;
  final String? subLabel;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 96,
    this.strokeWidth = 10,
    this.color = AppColors.primary,
    this.centerLabel,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              color: AppColors.divider,
            ),
          ),
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: clamped,
              strokeWidth: strokeWidth,
              color: color,
              backgroundColor: Colors.transparent,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel ?? '${(clamped * 100).round()}%',
                style: TextStyle(
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subLabel != null)
                Text(
                  subLabel!,
                  style: TextStyle(fontSize: size * 0.09, color: AppColors.textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
