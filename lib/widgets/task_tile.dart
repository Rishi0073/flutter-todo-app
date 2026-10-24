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
    required this.onTap,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

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

  String _dueLabel() {
    if (task.dueDate == null) return '';
    final d = task.dueDate!;
    final label = '${d.day}/${d.month}/${d.year}';
    if (task.isOverdue) return 'Overdue: $label';
    return 'Due: $label';
  }

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[task.category.label, task.priority.label];
    if (task.dueDate != null) subtitleParts.add(_dueLabel());
    if (task.description.isNotEmpty) subtitleParts.add(task.description);

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
        subtitleParts.join('  ·  '),
        style: TextStyle(
          color: task.isOverdue ? Colors.red : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, color: _priorityColor(), size: 18),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
