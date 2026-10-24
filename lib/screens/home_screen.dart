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

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    TaskPriority priority = TaskPriority.medium;
    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New task'),
          content: Column(
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
              const SizedBox(height: 16),
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
                  if (value != null) priority = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (created == true) {
      await widget.controller.addTask(titleController.text, priority);
    }
    titleController.dispose();
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
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        controller.pendingCount == 0
                            ? 'All done! Nice work.'
                            : '${controller.pendingCount} task(s) still pending',
                        style: Theme.of(context).textTheme.titleMedium,
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
                    Expanded(
                      child: tasks.isEmpty
                          ? const Center(
                              child: Text('No tasks here yet. Add one!'),
                            )
                          : ListView.builder(
                              itemCount: tasks.length,
                              itemBuilder: (context, index) {
                                final task = tasks[index];
                                return TaskTile(
                                  task: task,
                                  onToggle: () => controller.toggleTask(task),
                                  onDelete: () => controller.deleteTask(task),
                                );
                              },
                            ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddTaskDialog,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
