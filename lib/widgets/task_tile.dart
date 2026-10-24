import 'package:flutter/material.dart';

import '../models/task.dart';

// One row in the task list. Kept separate so the home screen
// stays readable and this row can be reused or tested alone.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  Color _priorityColor() {
    switch (task.priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: task.done,
        onChanged: (_) => onToggle(),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration:
              task.done ? TextDecoration.lineThrough : TextDecoration.none,
        ),
      ),
      subtitle: Text(
        task.priority.label,
        style: TextStyle(color: _priorityColor()),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onDelete,
      ),
    );
  }
}
