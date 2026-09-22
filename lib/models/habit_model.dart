class HabitModel {
  final String id;
  final String userId;
  final String title;
  final String icon;
  final String color; // hex string, e.g. '#6C5CE7'
  final String frequency; // daily | weekly | custom
  final int targetPerPeriod;
  final DateTime createdAt;

  const HabitModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.icon,
    required this.color,
    required this.frequency,
    required this.targetPerPeriod,
    required this.createdAt,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      icon: (json['icon'] as String?) ?? 'star',
      color: (json['color'] as String?) ?? '#6C5CE7',
      frequency: (json['frequency'] as String?) ?? 'daily',
      targetPerPeriod: (json['target_per_period'] as int?) ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toInsertJson(String userId) => {
        'user_id': userId,
        'title': title,
        'icon': icon,
        'color': color,
        'frequency': frequency,
        'target_per_period': targetPerPeriod,
      };

  Map<String, dynamic> toUpdateJson() => {
        'title': title,
        'icon': icon,
        'color': color,
        'frequency': frequency,
        'target_per_period': targetPerPeriod,
      };
}

class HabitLogModel {
  final String id;
  final String habitId;
  final DateTime completedDate;

  const HabitLogModel({
    required this.id,
    required this.habitId,
    required this.completedDate,
  });

  factory HabitLogModel.fromJson(Map<String, dynamic> json) {
    return HabitLogModel(
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      completedDate: DateTime.parse(json['completed_date'] as String),
    );
  }
}
