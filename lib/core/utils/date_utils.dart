import 'package:intl/intl.dart';

/// Small date helpers shared across screens. Kept dependency-free (just
/// `intl`) so it's easy to unit test.
class AppDateUtils {
  AppDateUtils._();

  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static bool isToday(DateTime date) {
    final t = today();
    return date.year == t.year && date.month == t.month && date.day == t.day;
  }

  static bool isOverdue(DateTime? dueDate, {bool completed = false}) {
    if (dueDate == null || completed) return false;
    return dueDate.isBefore(today());
  }

  static String friendlyDate(DateTime date) {
    final t = today();
    final d = DateTime(date.year, date.month, date.day);
    final diff = d.difference(t).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }

  static String friendlyTime(DateTime date) => DateFormat('h:mm a').format(date);

  static String weekdayShort(DateTime date) => DateFormat('E').format(date);

  static String monthYear(DateTime date) => DateFormat('MMMM yyyy').format(date);

  /// Current streak length (consecutive days ending today or yesterday)
  /// given a set of completed dates (normalized to y/m/d).
  static int currentStreak(Set<DateTime> completedDates) {
    if (completedDates.isEmpty) return 0;
    final normalized = completedDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    var cursor = today();
    if (!normalized.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!normalized.contains(cursor)) return 0;
    }
    var streak = 0;
    while (normalized.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
