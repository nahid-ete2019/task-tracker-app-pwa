class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String category;
  final String priority; // low | medium | high
  final String status; // todo | in_progress | completed
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == 'completed';

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: (json['category'] as String?) ?? 'General',
      priority: (json['priority'] as String?) ?? 'medium',
      status: (json['status'] as String?) ?? 'todo',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String).toLocal() : null,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse((json['updated_at'] ?? json['created_at']) as String).toLocal(),
    );
  }

  Map<String, dynamic> toInsertJson(String userId) => {
        'user_id': userId,
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'status': status,
        'due_date': dueDate?.toUtc().toIso8601String(),
      };

  Map<String, dynamic> toUpdateJson() => {
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'status': status,
        'due_date': dueDate?.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  TaskModel copyWith({
    String? title,
    String? description,
    String? category,
    String? priority,
    String? status,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return TaskModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
