// Data model for one task. Pure Dart, no Flutter dependency,
// so it is easy to unit test.

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

class Task {
  Task({
    required this.id,
    required this.title,
    this.done = false,
    this.priority = TaskPriority.medium,
  });

  final String id;
  final String title;
  final bool done;
  final TaskPriority priority;

  Task copyWith({bool? done, TaskPriority? priority}) {
    return Task(
      id: id,
      title: title,
      done: done ?? this.done,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'done': done,
      'priority': priority.name,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      done: json['done'] as bool? ?? false,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.done == done &&
        other.priority == priority;
  }

  @override
  int get hashCode => Object.hash(id, title, done, priority);
}
