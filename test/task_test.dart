import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todo_app/controllers/task_controller.dart';
import 'package:flutter_todo_app/data/settings_repository.dart';
import 'package:flutter_todo_app/data/task_repository.dart';
import 'package:flutter_todo_app/models/task.dart';

// Fake repositories for tests: no SharedPreferences, no phone needed.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository([List<Task>? seed]) : _stored = seed ?? [];

  List<Task> _stored;

  @override
  Future<List<Task>> loadTasks() async => List.of(_stored);

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    _stored = List.of(tasks);
  }
}

class FakeSettingsRepository implements SettingsRepository {
  bool darkMode = false;

  @override
  Future<bool> loadDarkMode() async => darkMode;

  @override
  Future<void> saveDarkMode(bool enabled) async {
    darkMode = enabled;
  }
}

TaskController makeController([List<Task>? seed]) {
  return TaskController(
    FakeTaskRepository(seed),
    FakeSettingsRepository(),
  );
}

void main() {
  test('Task converts to JSON and back without losing data', () {
    final original = Task(
      id: '1',
      title: 'Write tests',
      done: true,
      priority: TaskPriority.high,
      category: TaskCategory.work,
      description: 'Unit tests for the app',
      dueDate: DateTime(2026, 10, 30),
    );
    final restored = Task.fromJson(original.toJson());
    expect(restored, original);
    expect(restored.dueDate, DateTime(2026, 10, 30));
  });

  test('Old v2 task JSON still loads (missing v3 fields default safely)', () {
    final restored = Task.fromJson({
      'id': 'old-1',
      'title': 'Old task',
      'done': false,
      'priority': 'medium',
    });
    expect(restored.category, TaskCategory.other);
    expect(restored.description, '');
    expect(restored.dueDate, isNull);
  });

  test('Overdue is true only for pending tasks past their due date', () {
    final overdue = Task(
      id: '1',
      title: 'Late',
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
    );
    final doneLate = overdue.copyWith(done: true);
    final future = Task(
      id: '2',
      title: 'Future',
      dueDate: DateTime.now().add(const Duration(days: 1)),
    );
    expect(overdue.isOverdue, isTrue);
    expect(doneLate.isOverdue, isFalse);
    expect(future.isOverdue, isFalse);
  });

  test('Controller filters pending tasks and counts them', () async {
    final controller = makeController([
      Task(id: '1', title: 'Done task', done: true),
      Task(id: '2', title: 'Open task', done: false),
    ]);
    await controller.load();
    expect(controller.pendingCount, 1);

    controller.setFilter(TaskFilter.pending);
    expect(controller.visibleTasks.length, 1);
    expect(controller.visibleTasks.first.title, 'Open task');
  });

  test('Controller search filters by title and notes, case-insensitive', () async {
    final controller = makeController([
      Task(id: '1', title: 'Learn Flutter', description: 'Widgets'),
      Task(id: '2', title: 'Buy groceries'),
    ]);
    await controller.load();
    controller.setSearchQuery('WIDGETS');
    expect(controller.visibleTasks.length, 1);
    expect(controller.visibleTasks.first.title, 'Learn Flutter');
  });

  test('Adding a task with an empty title does nothing', () async {
    final controller = makeController();
    await controller.load();
    await controller.addTask(title: '   ');
    expect(controller.allTasks, isEmpty);
  });

  test('Category filter, priority sort and clear completed work', () async {
    final controller = makeController([
      Task(id: '1', title: 'Work low', priority: TaskPriority.low,
          category: TaskCategory.work),
      Task(id: '2', title: 'Study high', priority: TaskPriority.high,
          category: TaskCategory.study),
      Task(id: '3', title: 'Work done', done: true,
          category: TaskCategory.work),
    ]);
    await controller.load();

    controller.setCategoryFilter(TaskCategory.study);
    expect(controller.visibleTasks.length, 1);

    controller.setCategoryFilter(null);
    controller.setSort(TaskSort.priority);
    expect(controller.visibleTasks.first.title, 'Study high');

    await controller.clearCompleted();
    expect(controller.allTasks.length, 2);
    expect(controller.doneCount, 0);
  });

  test('Delete can be undone, and edit updates the task', () async {
    final controller = makeController([
      Task(id: '1', title: 'Original'),
    ]);
    await controller.load();
    final task = controller.allTasks.first;

    await controller.deleteTask(task);
    expect(controller.allTasks, isEmpty);
    await controller.undoDelete();
    expect(controller.allTasks.length, 1);

    await controller.updateTask(
      controller.allTasks.first.copyWith(title: 'Edited'),
    );
    expect(controller.allTasks.first.title, 'Edited');
  });

  test('Dark mode toggle flips and persists through settings', () async {
    final settings = FakeSettingsRepository();
    final controller = TaskController(FakeTaskRepository(), settings);
    await controller.load();
    expect(controller.darkMode, isFalse);
    await controller.toggleDarkMode();
    expect(controller.darkMode, isTrue);
    expect(settings.darkMode, isTrue);
  });
}
