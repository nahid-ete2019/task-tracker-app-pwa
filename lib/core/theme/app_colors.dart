import 'package:flutter/material.dart';

/// Palette derived from the reference "Modern Dashboard App" UI kit:
/// soft lavender surfaces, an indigo/violet primary, and clear
/// semantic colors for priority/status chips.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFFA29BFE);
  static const Color primaryDark = Color(0xFF4834D4);

  static const Color secondary = Color(0xFF00CEC9);

  static const Color background = Color(0xFFF7F7FC);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF747D8C);
  static const Color textMuted = Color(0xFFB2BEC3);

  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDA23A);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF54A0FF);

  static const Color divider = Color(0xFFEDEDF7);

  // Priority colors
  static const Color priorityLow = success;
  static const Color priorityMedium = warning;
  static const Color priorityHigh = danger;

  // Category donut palette (Analytics)
  static const List<Color> categoryPalette = [
    primary,
    secondary,
    warning,
    success,
    info,
    Color(0xFFFF7675),
  ];

  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return priorityHigh;
      case 'low':
        return priorityLow;
      case 'medium':
      default:
        return priorityMedium;
    }
  }

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return success;
      case 'in_progress':
        return info;
      case 'todo':
      default:
        return textMuted;
    }
  }
}
