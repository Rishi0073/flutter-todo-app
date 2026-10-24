import 'package:flutter/material.dart';

import '../controllers/task_controller.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart';

// The screen only renders state and forwards taps to the
// controller. No business logic lives here.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final TaskController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteWithUndo(Task task) async {
    await widget.controller.deleteTask(task);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => widget.controller.undoDelete(),
        ),
      ),
    );
  }

  Future<void> _showTaskDialog({Task? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    TaskPriority priority = existing?.priority ?? TaskPriority.medium;
    TaskCategory category = existing?.category ?? TaskCategory.other;
    DateTime? dueDate = existing?.dueDate;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'New task' : 'Edit task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task title',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TaskPriority>(
                      value: priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: TaskPriority.values.map((item) {
                        return DropdownMenuItem<TaskPriority>(
                          value: item,
                          child: Text(item.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => priority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TaskCategory>(
                      value: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: TaskCategory.values.map((item) {
                        return DropdownMenuItem<TaskCategory>(
                          value: item,
                          child: Text(item.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => category = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dueDate == null
                                ? 'No due date'
                                : 'Due: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dueDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() => dueDate = picked);
                            }
                          },
                          child: const Text('Pick date'),
                        ),
                        if (dueDate != null)
                          TextButton(
                            onPressed: () {
                              setDialogState(() => dueDate = null);
                            },
                            child: const Text('Clear'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(existing == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      if (existing == null) {
        await widget.controller.addTask(
          title: titleController.text,
          priority: priority,
          category: category,
          description: descriptionController.text,
          dueDate: dueDate,
        );
      } else {
        await widget.controller.updateTask(
          existing.copyWith(
            title: titleController.text.trim(),
            priority: priority,
            category: category,
            description: descriptionController.text.trim(),
            dueDate: dueDate,
            clearDueDate: dueDate == null,
          ),
        );
      }
    }
    titleController.dispose();
    descriptionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final tasks = controller.visibleTasks;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Tasks'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              IconButton(
                icon: Icon(
                  controller.darkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                tooltip: 'Toggle dark mode',
                onPressed: controller.toggleDarkMode,
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Clear completed',
                onPressed: controller.doneCount > 0
                    ? controller.clearCompleted
                    : null,
              ),
            ],
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Stats card: progress + counts.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${controller.doneCount} of ${controller.totalCount} done'
                            '${controller.overdueCount > 0 ? '  ·  ${controller.overdueCount} overdue' : ''}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: controller.doneFraction,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search tasks',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: controller.setSearchQuery,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<TaskFilter>(
                      segments: TaskFilter.values.map((filter) {
                        return ButtonSegment<TaskFilter>(
                          value: filter,
                          label: Text(filter.label),
                        );
                      }).toList(),
                      selected: {controller.filter},
                      onSelectionChanged: (selected) {
                        controller.setFilter(selected.first);
                      },
                    ),
                    const SizedBox(height: 8),
                    // Category chips: All + one per category.
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All categories'),
                            selected: controller.categoryFilter == null,
                            onSelected: (_) {
                              controller.setCategoryFilter(null);
                            },
                          ),
                          const SizedBox(width: 8),
                          ...TaskCategory.values.map((category) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(category.label),
                                selected:
                                    controller.categoryFilter == category,
                                onSelected: (_) {
                                  controller.setCategoryFilter(category);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Sort menu.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Text('Sort by: '),
                          DropdownButton<TaskSort>(
                            value: controller.sort,
                            items: TaskSort.values.map((sort) {
                              return DropdownMenuItem<TaskSort>(
                                value: sort,
                                child: Text(sort.label),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) controller.setSort(value);
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: tasks.isEmpty
                          ? const Center(
                              child: Text('No tasks here yet. Add one!'),
                            )
                          : ListView.builder(
                              itemCount: tasks.length,
                              itemBuilder: (context, index) {
                                final task = tasks[index];
                                return Dismissible(
                                  key: ValueKey(task.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 16),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onDismissed: (_) =>
                                      _deleteWithUndo(task),
                                  child: TaskTile(
                                    task: task,
                                    onToggle: () =>
                                        controller.toggleTask(task),
                                    onDelete: () => _deleteWithUndo(task),
                                    onTap: () =>
                                        _showTaskDialog(existing: task),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showTaskDialog(),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
