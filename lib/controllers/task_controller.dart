import 'package:flutter/foundation.dart';

import '../data/task_repository.dart';
import '../models/task.dart';

enum TaskFilter { all, pending, done }

extension TaskFilterLabel on TaskFilter {
  String get label {
    switch (this) {
      case TaskFilter.all:
        return 'All';
      case TaskFilter.pending:
        return 'Pending';
      case TaskFilter.done:
        return 'Done';
    }
  }
}

// All business logic lives here, not in the widgets.
// The UI only calls these methods and listens for changes.
class TaskController extends ChangeNotifier {
  TaskController(this._repository);

  final TaskRepository _repository;
  List<Task> _tasks = [];
  TaskFilter _filter = TaskFilter.all;
  String _searchQuery = '';
  bool _isLoading = true;

  List<Task> get allTasks => List.unmodifiable(_tasks);
  TaskFilter get filter => _filter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  int get pendingCount => _tasks.where((task) => !task.done).length;

  List<Task> get visibleTasks {
    Iterable<Task> result = _tasks;
    if (_filter == TaskFilter.pending) {
      result = result.where((task) => !task.done);
    } else if (_filter == TaskFilter.done) {
      result = result.where((task) => task.done);
    }
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((task) => task.title.toLowerCase().contains(query));
    }
    return result.toList();
  }

  Future<void> load() async {
    _tasks = await _repository.loadTasks();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _repository.saveTasks(_tasks);
  }

  Future<void> addTask(String title, TaskPriority priority) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    _tasks.add(
      Task(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: trimmed,
        priority: priority,
      ),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> toggleTask(Task task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;
    _tasks[index] = task.copyWith(done: !task.done);
    notifyListeners();
    await _persist();
  }

  Future<void> deleteTask(Task task) async {
    _tasks.removeWhere((item) => item.id == task.id);
    notifyListeners();
    await _persist();
  }

  void setFilter(TaskFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
