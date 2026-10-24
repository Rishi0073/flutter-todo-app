// Data model for one task. Pure Dart, no Flutter dependency,
// so it is easy to unit test.
//
// v3 fields (category, description, dueDate, createdAt) are all
// optional when reading old saved data, so tasks saved by v2
// of the app still load correctly after the upgrade.

enum TaskPriority { low, medium, high }

extension TaskPriorityLabel on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }
}

enum TaskCategory { work, study, personal, other }

extension TaskCategoryLabel on TaskCategory {
  String get label {
    switch (this) {
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.study:
        return 'Study';
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.other:
        return 'Other';
    }
  }
}

class Task {
  Task({
    required this.id,
    required this.title,
    this.done = false,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.other,
    this.description = '',
    this.dueDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final bool done;
  final TaskPriority priority;
  final TaskCategory category;
  final String description;
  final DateTime? dueDate;
  final DateTime createdAt;

  bool get isOverdue {
    if (done || dueDate == null) return false;
    final today = DateTime.now();
    final dueDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return dueDay.isBefore(todayDay);
  }

  Task copyWith({
    String? title,
    bool? done,
    TaskPriority? priority,
    TaskCategory? category,
    String? description,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      done: done ?? this.done,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      description: description ?? this.description,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'done': done,
      'priority': priority.name,
      'category': category.name,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value as String);
    }

    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      done: json['done'] as bool? ?? false,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      category: TaskCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => TaskCategory.other,
      ),
      description: json['description'] as String? ?? '',
      dueDate: parseDate(json['dueDate']),
      createdAt: parseDate(json['createdAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.done == done &&
        other.priority == priority &&
        other.category == category &&
        other.description == description &&
        other.dueDate == dueDate;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        done,
        priority,
        category,
        description,
        dueDate,
      );
}
