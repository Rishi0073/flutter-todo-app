import 'package:flutter/foundation.dart';

import '../data/settings_repository.dart';
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

enum TaskSort { newest, priority, dueDate, title }

extension TaskSortLabel on TaskSort {
  String get label {
    switch (this) {
      case TaskSort.newest:
        return 'Newest first';
      case TaskSort.priority:
        return 'Priority';
      case TaskSort.dueDate:
        return 'Due date';
      case TaskSort.title:
        return 'Title A-Z';
    }
  }
}

// All business logic lives here, not in the widgets.
// The UI only calls these methods and listens for changes.
class TaskController extends ChangeNotifier {
  TaskController(this._repository, [this._settings]);

  final TaskRepository _repository;
  final SettingsRepository? _settings;
  List<Task> _tasks = [];
  TaskFilter _filter = TaskFilter.all;
  TaskCategory? _categoryFilter;
  TaskSort _sort = TaskSort.newest;
  String _searchQuery = '';
  bool _isLoading = true;
  bool _darkMode = false;

  // Last deleted task, kept so the UI can offer Undo.
  Task? _lastDeleted;
  int _lastDeletedIndex = -1;

  List<Task> get allTasks => List.unmodifiable(_tasks);
  TaskFilter get filter => _filter;
  TaskCategory? get categoryFilter => _categoryFilter;
  TaskSort get sort => _sort;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get darkMode => _darkMode;
  bool get canUndoDelete => _lastDeleted != null;

  int get totalCount => _tasks.length;
  int get doneCount => _tasks.where((task) => task.done).length;
  int get pendingCount => _tasks.where((task) => !task.done).length;
  int get overdueCount => _tasks.where((task) => task.isOverdue).length;

  double get doneFraction {
    if (_tasks.isEmpty) return 0;
    return doneCount / _tasks.length;
  }

  List<Task> get visibleTasks {
    Iterable<Task> result = _tasks;
    if (_filter == TaskFilter.pending) {
      result = result.where((task) => !task.done);
    } else if (_filter == TaskFilter.done) {
      result = result.where((task) => task.done);
    }
    if (_categoryFilter != null) {
      result = result.where((task) => task.category == _categoryFilter);
    }
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where(
        (task) =>
            task.title.toLowerCase().contains(query) ||
            task.description.toLowerCase().contains(query),
      );
    }
    final list = result.toList();
    switch (_sort) {
      case TaskSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case TaskSort.priority:
        int rank(TaskPriority p) => p == TaskPriority.high
            ? 0
            : (p == TaskPriority.medium ? 1 : 2);
        list.sort((a, b) => rank(a.priority).compareTo(rank(b.priority)));
      case TaskSort.dueDate:
        list.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
      case TaskSort.title:
        list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return list;
  }

  Future<void> load() async {
    _tasks = await _repository.loadTasks();
    if (_settings != null) {
      _darkMode = await _settings.loadDarkMode();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _repository.saveTasks(_tasks);
  }

  Future<void> addTask({
    required String title,
    TaskPriority priority = TaskPriority.medium,
    TaskCategory category = TaskCategory.other,
    String description = '',
    DateTime? dueDate,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    _tasks.add(
      Task(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: trimmed,
        priority: priority,
        category: category,
        description: description.trim(),
        dueDate: dueDate,
      ),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> updateTask(Task updated) async {
    final index = _tasks.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    _tasks[index] = updated;
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
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;
    _lastDeleted = _tasks[index];
    _lastDeletedIndex = index;
    _tasks.removeAt(index);
    notifyListeners();
    await _persist();
  }

  Future<void> undoDelete() async {
    if (_lastDeleted == null) return;
    int index = _lastDeletedIndex;
    if (index < 0) index = 0;
    if (index > _tasks.length) index = _tasks.length;
    _tasks.insert(index, _lastDeleted!);
    _lastDeleted = null;
    _lastDeletedIndex = -1;
    notifyListeners();
    await _persist();
  }

  Future<void> clearCompleted() async {
    _tasks.removeWhere((task) => task.done);
    notifyListeners();
    await _persist();
  }

  Future<void> toggleDarkMode() async {
    _darkMode = !_darkMode;
    notifyListeners();
    if (_settings != null) {
      await _settings.saveDarkMode(_darkMode);
    }
  }

  void setFilter(TaskFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setCategoryFilter(TaskCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setSort(TaskSort sort) {
    _sort = sort;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
