class GoalMilestoneModel {
  final String id;
  final String goalId;
  final String title;
  final bool isCompleted;

  const GoalMilestoneModel({
    required this.id,
    required this.goalId,
    required this.title,
    required this.isCompleted,
  });

  factory GoalMilestoneModel.fromJson(Map<String, dynamic> json) {
    return GoalMilestoneModel(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      title: json['title'] as String,
      isCompleted: (json['is_completed'] as bool?) ?? false,
    );
  }
}

class GoalModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String category;
  final String icon;
  final String color;
  final DateTime? targetDate;
  final String status; // active | completed | archived
  final double manualProgress;
  final DateTime createdAt;
  final List<GoalMilestoneModel> milestones;

  const GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.icon,
    required this.color,
    this.targetDate,
    required this.status,
    required this.manualProgress,
    required this.createdAt,
    this.milestones = const [],
  });

  /// Progress is derived from milestones when any exist, otherwise falls
  /// back to the manually-set progress value (PRD §11).
  double get progress {
    if (milestones.isNotEmpty) {
      final completed = milestones.where((m) => m.isCompleted).length;
      return completed / milestones.length;
    }
    return (manualProgress / 100).clamp(0, 1);
  }

  String get progressLabel {
    if (milestones.isNotEmpty) {
      final completed = milestones.where((m) => m.isCompleted).length;
      return '$completed/${milestones.length} completed';
    }
    return '${manualProgress.round()}% complete';
  }

  factory GoalModel.fromJson(Map<String, dynamic> json, {List<GoalMilestoneModel> milestones = const []}) {
    return GoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: (json['category'] as String?) ?? 'General',
      icon: (json['icon'] as String?) ?? 'flag',
      color: (json['color'] as String?) ?? '#6C5CE7',
      targetDate: json['target_date'] != null ? DateTime.parse(json['target_date'] as String) : null,
      status: (json['status'] as String?) ?? 'active',
      manualProgress: (json['manual_progress'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      milestones: milestones,
    );
  }

  Map<String, dynamic> toInsertJson(String userId) => {
        'user_id': userId,
        'title': title,
        'description': description,
        'category': category,
        'icon': icon,
        'color': color,
        'target_date': targetDate?.toIso8601String().split('T').first,
        'status': status,
        'manual_progress': manualProgress,
      };

  Map<String, dynamic> toUpdateJson() => {
        'title': title,
        'description': description,
        'category': category,
        'icon': icon,
        'color': color,
        'target_date': targetDate?.toIso8601String().split('T').first,
        'status': status,
        'manual_progress': manualProgress,
      };
}
